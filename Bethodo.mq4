#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#property description "Enrico Albano's automated bot for Bethodo"
#property version "210.419"

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
 *  - Unire Ahtodo e Bethodo in un solo bot con librerie condivise
 *
 *  - SymbolFamily per ora è troppo rudimentale, devo abilitare famiglie multiple tipo U|G|A|Z. Inoltre devo
 *      considerare sia correlazione che anticorrelazione (u|G|a|Z) (o forse togliere la distinzione a bethodo).
 *      Non so come abilitare famiglie multiple, forse il concetto di family è sbagliato e posso fare una
 *      funzione GetCorrelatedSymbols (dentro OrderFilter?) che prende la lista di simboli permessi e controlla
 *      tutte le combinazioni, e dopo semplicmente quello che fa è aggiungere tutti i simboli a orderfilter.symbol.add.
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
        if (orderManage.areTherePendingOrdersThisSymbolThisPeriod()) {
            SPREAD_NEWS_TIMESTAMP = PrintTimer(SPREAD_NEWS_TIMESTAMP, "Closing pending orders for news or spread");
            orderManage.deletePendingOrders();
        }
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
