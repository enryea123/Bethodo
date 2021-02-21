#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#property description "Enrico Albano's automated bot for Bethodo"
#property version "210.221"

#include "src/drawer/Drawer.mqh"
#include "src/market/Market.mqh"
#include "src/order/OrderCreate.mqh"
#include "src/order/OrderManage.mqh"
#include "src/order/OrderTrail.mqh"
#include "src/util/Price.mqh"
#include "tst/UnitTestsRunner.mqh"

/**
 * This is the main file of the program. OnInit is executed only once at the program start.
 * OnTick is executed every time there is a new price update (tick) in the market.
 * OnDeInit is executed at the end of the program, and cleans up some variables.
 */

/**
 *
 * TODO:
 *
 *  - Bethodo must be compatible with Ahtodo if run in the same account
 *
 *  - Fare unit tests mancanti come areThereOrdersThisSymbolThisPeriod, getTrendLineSlope, getTrendLineDiscriminator.
 *      Ripulire i metodi inutili in TrendLine che sono duplicati in channel.
 *      Sistemare unit tests commentati per metodi molto cambiati.
 *
 *  - Average true range +2pip per stoploss.
 *
 *  - Separare file comuni Ahtodo Bethodo in librerie condivise con un git a parte. Credo si possa con un "../" in più.
 *      Forse si possono unire i 2 bot sotto un unico workspace, con 2 file .mq4, e da mt4 si può scegliere.
 *      Molte controindicazioni come Constants, isMarketOpened, ecc. Le funzioni molto diverse possono avere un
 *      parametro di ingresso per distinguere la strategy e fare cose differenti.
 *
 *  - Canali con inclinazione leggeremente opposta (3-4 gradi). Rendere GetMarketVolatility esterno e che ritorni Pip
 *      interi (facendo result / Pip()), cosi che la pendenza delle rette possa essere intera. Attenzione che pero
 *      non sono gradi, visto che altrimenti il massimo sarebbe 90.
 *
 *  - Ordini stop se il prezzo è oltre il segnale. E se invece ha gia toccato il segnale ed è già partito indietro?
 *      In quel caso il bot al momento metterebbe un limit, ma il segnale non verrà piu toccato e serve uno stop.
 *      L'ordine stop quanto piu avanti viene fatto in questo caso? Il prezzo dev'essere "entro 15-20 pip".
 *      Quando si useranno anche ordini stop, bisognerà controllare tutti i type/OP_ come in areThereBetterOrders.
 *      Questo è il problema degli ordini nel passato. In teoria si possono vedere tutte le 9 candele passate
 *      dalle 14 alle 23, e mettere ordine se il setup c'è (ed è valido) su una qualsiasi di quelle.
 *      Non rimettere ordine che ha già fatto 1:1.5. In generale non rimettere ordini se è già stato perso il primo.
 *      Mettere ordine stop per canale 2+2 appena fatto (sopra la candela corrente? o un tot di pip meglio).
 *
 *  - La soluzione corrente al bug dei setup multipli è molto approssimativa. Non trova l'ordine migliore ma
 *      quello più in alto/basso possibile, che dovrebbe essere in teoria più vicino. Un ordine successivo
 *      con setup migliori (?) non viene considerato se ce n'è già un altro.
 *
 *  - I livelli orizzontali devono avere un margine di tolleranza di 4pip, altrimenti vengono cancellati
 *      quando vengono superati di poco e bisognerebbe mettere un ordine stop (o limit in ritardo).
 *      Messo, ma controllare dettagli piu avanti. Inoltre ho reso le ultime `2 * MIN_EXTREME` candele
 *      invisibili sia a canali che livelli orizzontali.
 *
 *  - La durata degli ordini dev'essere variabile e dipende dal setup, altrimenti scadono tutti alle 16
 *      quelli non entrati, e non vengono rimessi fino alle 23. Forse bisognerebbe considerare di lasciare sempre
 *      aperto il mercato, a parte che nella spread hour. Vedere meglio il lookback, qui non serve come pattern
 *      e candele direttamente, ma piu come per mettere ordini di tipo diverso se un setup (corrente o passato)
 *      è stato superato. Può aiutare passare sia openPrice che tipo di ordine? Magari il secondo si può fare
 *      cercando un livello con quel price esatto. Ricordare i pip cuscinetto da togliere per la ricerca, o
 *      magari da mettere direttamente in createNewOrder, invece che in calculateOrderOpenPriceFromSetups.
 *
 *  - PeriodFactor inutile, considera se eliminarlo.
 *
 *  - Il commento va aggiornato:
 *      forse P è inutile
 *      SIZE_FACTOR_COMMENT_IDENTIFIER puo diventare la percentuale di rischio attuale.
 *
 *  - Trailing stopLoss su minimo precendente, può essere fatto prendendo il minimo delle ultime 3-4 candele.
 *      Quando si aggiunge quello si puo aumentare BASE_TAKEPROFIT_FACTOR, e magari fare up TP che scappa.
 *      Si può considerare un TP fisso a 1:2 / 1:3, uno grande a 1:4 / 1:5 con trailing, o uno "infinito" con trailing.
 *      Si può anche fare un TP che sia alla fine del canale.
 *      Si possono anche mettere scaling in della posizione (si perderebbe il commento), o scaling out.
 *      Il rollover notturno alle 23 con gap grandi potrebbe essere un grosso problema per il trailing.
 *      Il trailing deve allontanarsi di un tot (20pip?) poco prima delle 23 per ripristinarsi alle 00, pero
 *      non puo andare sotto il breakeven a 0. Quindi c'è un trailing che si disattiva quando c'è il rollover stoploss.
 *      Trailing basico gia implementato, mancano test per calculateTrailingStopLoss e getPreviousExtreme.
 *
 *  - Spread con memoria di 5-10 minuti: se c'è stato spread alto negli ultimi X minuti, il mercato rimane chiuso.
 *      A parte quello il mercato deve rimanere chiuso davvero dalle 14 alle 23? Se non ci fosse spread quali
 *      sarebbero i reali valori? Verificare se una spreadHour custom basta o serve proprio chiudere.
 *
 *  - Mezzo bug con isGoodTrendLineFromName che prende indici troppo piccoli. O forse va quasi bene perché
 *      cosi mette ordini a canali 2+2, solo che lo fa in leggero ritardo (dovrebbero essere stop a quel punto).
 *      C'è inoltre il problema che il livello orizzontale li è quello del massimo che ha appena creato il canale.
 *      Per risolvere quest'ultimo bug per ora ho messo `TRENDLINE_MIN_EXTREMES_DISTANCE + extremesMinDistance`.
 *      Bisogna confermare se questo è il valore ottimale o si puo fare di meglio.
 *      L'indice minimo di una trendLine ora è 1, ma si può fare 0 più avanti, cambiando Extreme e TrendLine.
 *      Per fare quello però bisogna aggiornare i disegni ogni 15 minuti invece che 60.
 *
 *  - Bot lento nell'inizializzazione e disegni. Troppe trendlines? Magari c'entra con gli errori 4066 di iCandle.
 *
 *  - SymbolFamily per ora è troppo rudimentale, devo abilitare famiglie multiple tipo U|G|A|Z. Inoltre devo
 *      considerare sia correlazione che anticorrelazione (u|G|a|Z) (o forse togliere la distinzione a bethodo).
 *      Non so come abilitare famiglie multiple, forse il concetto di family è sbagliato e posso fare una
 *      funzione GetCorrelatedSymbols (dentro OrderFilter?) che prende la lista di simboli permessi e controlla
 *      tutte le combinazioni, e dopo semplicmente quello che fa è aggiungere tutti i simboli a orderfilter.symbol.add.
 *
 *  - I canali per ora verificano il bilanciamento solo al livello delle singole trendline, ma bisogna farlo
 *      piu a livello di canale, con una verifica a 4 punti.
 *      I canali piccoli che si formano dentro altri canali sono pericolosi, come scegliere in quei casi? Vedi sotto.
 *      Uguale per 2 canali con pendenza diversa, mettere sempre l'ordine sul piu piccolo.
 *      Usare fatness per filtrare canali, non height (e diminuire valore massimo). Difficile da fare pero.
 *      Forse usare OBJ_CHANNEL???
 *
 *  - Per ora gli ordini vengono messi fino alle 14 e scadono 1 ora dopo, ma bisognerà fare che vengono
 *      tolti quelli pending se diventano le 15.
 *
 */


void OnInit() {
    const ulong startTime = GetTickCount();
    InitializeMaps();

    while (!IsConnected() || AccountNumber() == 0) {
        Sleep(500);
    }

    if (!DownloadHistory()) {
        ThrowFatalException(__FUNCTION__, "History data is outdated, restart the bot to download it");
        return;
    }

    Drawer drawer;
    Market market;
    OrderManage orderManage;

    if (!market.marketConditionsValidation()) {
        return;
    }

    drawer.setChartDefaultColors();

    if (market.isMarketOpened() || orderManage.areThereOrdersThisSymbolThisPeriod()) {
        drawer.setChartMarketOpenedColors();
    } else {
        drawer.setChartMarketClosedColors();
    }

    UnitTestsRunner unitTestsRunner;
    unitTestsRunner.runAllUnitTests();

    drawer.drawEverything();

    Print("Initialization completed in ", GetTickCount() - startTime, " ms");
}

void OnTick() {
    DownloadHistory();
    Sleep(500);

    Drawer drawer;
    Market market;
    NewsDraw newsDraw;
    OrderManage orderManage;

    if (!market.marketConditionsValidation()) {
        return;
    }

    drawer.drawEverything();

    if (!IsTradeAllowed()) {
        drawer.setChartMarketClosedColors();
        return;
    }

    if (market.isMarketOpened() || orderManage.areThereOrdersThisSymbolThisPeriod()) {
        drawer.setChartMarketOpenedColors();
    } else {
        drawer.setChartMarketClosedColors();
    }

    if (GetSpread() > SPREAD_PIPS_CLOSE_MARKET || newsDraw.isNewsTimeWindow()) {
        orderManage.deletePendingOrders();
    }

    if (market.isMarketOpened() && !orderManage.areThereOpenOrders()) {
        OrderCreate orderCreate;
        orderCreate.newOrder();
    }

    orderManage.emergencySwitchOff();
    orderManage.lossLimiter();
    orderManage.deduplicateOrders();

    OrderTrail orderTrail;
    orderTrail.manageOpenOrders();

    if (market.isEndOfWeek()) {
        orderManage.deleteAllOrders();
    }
}

void OnDeinit(const int reason) {
    Drawer drawer;
    drawer.setChartDefaultColors();

    ObjectsDeleteAll();
    UNIT_TESTS_COMPLETED = false;
}
