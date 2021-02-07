#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#property description "Enrico Albano's automated bot for Bethodo"
#property version "210.207"

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
 *
 *  - Average true range +2pip per stoploss.
 *
 *  - Separare file comuni Ahtodo Bethodo in librerie condivise con un git a parte. Credo si possa con un "../" in più.
 *      Forse si possono unire i 2 bot sotto un unico workspace, con 2 file .mq4, e da mt4 si può scegliere.
 *      Molte controindicazioni come Constants, isMarketOpened, ecc. Le funzioni molto diverse possono avere un
 *      parametro di ingresso per distinguere la strategy e fare cose differenti.
 *
 *  - Rimuovi PrintSpreadInfo().
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
 *
 *  - Spread con memoria di 5-10 minuti: se c'è stato spread alto negli ultimi X minuti, il mercato rimane chiuso.
 *
 *  - Mezzo bug con isGoodTrendLineFromName che prende indici troppo piccoli. O forse va quasi bene perché
 *      cosi mette ordini a canali 2+2, solo che lo fa in leggero ritardo (dovrebbero essere stop a quel punto).
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

    // Needed to momentarily gather spread info
    PrintSpreadInfo();

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

void PrintSpreadInfo() {
    static datetime timeStamp;
    const datetime thisTime = (datetime) iCandle(I_time, Symbol(), PERIOD_M5, 0);

    if (timeStamp == thisTime) {
        return;
    }
    timeStamp = thisTime;

    Print("Market spread: ", GetSpread(), " pips");
}
