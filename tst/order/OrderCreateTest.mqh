#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../UnitTest.mqh"
#include "../../src/order/Order.mqh"
#include "../../src/order/OrderCreate.mqh"


class OrderCreateTest: public OrderCreate {
    public:
        void areThereRecentOrdersTest();
        void areThereBetterOrdersTest();
        void calculateOrderOpenPriceFromSetupsTest();
        void calculateOrderLotsTest();
        void getPercentRiskTest();
};

void OrderCreateTest::areThereRecentOrdersTest() {
    UnitTest unitTest("areThereRecentOrdersTest");

    const int period = Period();
    const datetime filterDate = (datetime) "2020-09-01 17:45";

    Order order;
    order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H1;
    order.symbol = Symbol();
    order.type = OP_SELL;
    order.closeTime = (datetime) "2020-08-20";

    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereRecentOrders(filterDate)
    );

    order.closeTime = filterDate;
    orderFind_.setMockedOrders(order);

    unitTest.assertTrue(
        areThereRecentOrders(filterDate)
    );

    order.closeTime = (datetime) "2020-09-01 18:00";
    orderFind_.setMockedOrders(order);

    unitTest.assertTrue(
        areThereRecentOrders(filterDate)
    );

    if (period == PERIOD_M30) {
        order.closeTime = (datetime) "2020-09-01 14:50";
        orderFind_.setMockedOrders(order);

        unitTest.assertFalse(
            areThereRecentOrders(filterDate)
        );

        order.closeTime = (datetime) "2020-09-01 15:10";
        orderFind_.setMockedOrders(order);

        unitTest.assertTrue(
            areThereRecentOrders(filterDate)
        );
    } else if (period == PERIOD_H1) {
        order.closeTime = (datetime) "2020-09-01 11:50";
        orderFind_.setMockedOrders(order);

        unitTest.assertFalse(
            areThereRecentOrders(filterDate)
        );

        order.closeTime = (datetime) "2020-09-01 12:10";
        orderFind_.setMockedOrders(order);

        unitTest.assertTrue(
            areThereRecentOrders(filterDate)
        );
    } else if (period == PERIOD_H4) {
        order.closeTime = (datetime) "2020-09-01 05:50";
        orderFind_.setMockedOrders(order);

        unitTest.assertFalse(
            areThereRecentOrders(filterDate)
        );

        order.closeTime = (datetime) "2020-09-01 06:10";
        orderFind_.setMockedOrders(order);

        unitTest.assertTrue(
            areThereRecentOrders(filterDate)
        );
    }

    order.closeTime = filterDate;
    order.type = OP_SELLSTOP;
    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereRecentOrders(filterDate)
    );

    order.type = OP_BUY;
    order.symbol = "CIAO";
    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereRecentOrders(filterDate)
    );

    orderFind_.deleteAllMockedOrders();
}

void OrderCreateTest::areThereBetterOrdersTest() {
    UnitTest unitTest("areThereBetterOrdersTest");

    const double stopLossSize = 20 * Pip();

    Order order;
    order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H1;
    order.symbol = Symbol();
    order.type = OP_SELLSTOP;
    order.ticket = 1234;
    order.openPrice = GetPrice(order.symbol);
    order.stopLoss = order.openPrice + stopLossSize;

    orderFind_.setMockedOrders(order);

    unitTest.assertTrue(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize, 0)
    );

    orderFind_.setMockedOrders(order);

    unitTest.assertTrue(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize * 1.2, 0)
    );

    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize * 0.8, 0)
    );

    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereBetterOrders(order.symbol, OP_SELL, stopLossSize * 0.8, 0)
    );

    orderFind_.setMockedOrders(order);

    unitTest.assertTrue(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize - 0.5 * Pip(), 0)
    );

    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize - 2 * Pip(), 0)
    );

    order.type = OP_BUYSTOP;
    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize * 1.2, 0)
    );

    order.type = OP_BUY;
    orderFind_.setMockedOrders(order);

    unitTest.assertTrue(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize * 0.8, 0)
    );

    order.type = OP_SELLSTOP;
    order.symbol = "CIAO";
    orderFind_.setMockedOrders(order);

    unitTest.assertTrue(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize, 0)
    );

    order.symbol = Symbol();
    order.magicNumber = 999999;
    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize, 0)
    );

    order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H1;

    Order orders[];
    ArrayResize(orders, 2);
    orders[0] = order;
    orders[1] = order;
    orders[1].stopLoss = order.openPrice + stopLossSize / 2;

    orderFind_.setMockedOrders(orders);

    unitTest.assertTrue(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize * 0.6, 0)
    );

    orderFind_.deleteAllMockedOrders();
}

void OrderCreateTest::calculateOrderOpenPriceFromSetupsTest() {
    UnitTest unitTest("calculateOrderOpenPriceFromSetupsTest");

    unitTest.assertEquals(
        -1.0,
        calculateOrderOpenPriceFromSetups(-1)
    );
/*
    const int totalAssertions = 3;
    int checkedAssertions = 0;

    bool antiPatternTested = false;
    bool patternTested = false;
    bool trendLineTested = false;

    for (int i = 1; i < 100; i++) {
        if (checkedAssertions == totalAssertions) {
            break;
        }

        if (pattern.isAntiPattern(i)) {
            if (antiPatternTested) {
                continue;
            }

            unitTest.assertEquals(
                -1,
                calculateOrderOpenPriceFromSetups(i)
            );
            checkedAssertions++;
            antiPatternTested = true;

        } else if (!pattern.isSellPattern(i) && !pattern.isBuyPattern(i)) {
            if (patternTested) {
                continue;
            }

            unitTest.assertEquals(
                -1,
                calculateOrderOpenPriceFromSetups(i)
            );
            checkedAssertions++;
            patternTested = true;

        } else {
            if (trendLineTested) {
                continue;
            }

            TrendLine trendLine;

            const Discriminator discriminator = (pattern.isSellPattern(i)) ? Min : Max;
            const int expectedOrder = (discriminator == Min) ? OP_SELLSTOP : OP_BUYSTOP;
            const double currentExtreme = iExtreme(discriminator, i);

            string trendLineName = trendLine.buildTrendLineName(50 + i, 20 + i, 0, discriminator);
            ObjectCreate(trendLineName, OBJ_TREND, 0, Time[50 + i], currentExtreme, Time[20 + i], currentExtreme);

            unitTest.assertEquals(
                expectedOrder,
                calculateOrderOpenPriceFromSetups(i)
            );

            ObjectDelete(trendLineName);
            trendLineName = trendLine.buildTrendLineName(50 + i, 20 + i, 0, discriminator);
            ObjectCreate(trendLineName, OBJ_TREND, 0,
                Time[50 + i], currentExtreme + (TRENDLINE_SETUP_MAX_PIPS_DISTANCE - 1) * Pip(),
                Time[20 + i], currentExtreme + (TRENDLINE_SETUP_MAX_PIPS_DISTANCE - 1) * Pip()
            );

            unitTest.assertEquals(
                expectedOrder,
                calculateOrderOpenPriceFromSetups(i)
            );

            ObjectDelete(trendLineName);
            trendLineName = trendLine.buildTrendLineName(50 + i, 20 + i, 0, discriminator);
            ObjectCreate(trendLineName, OBJ_TREND, 0,
                Time[50 + i], currentExtreme + (TRENDLINE_SETUP_MAX_PIPS_DISTANCE + 1) * Pip(),
                Time[20 + i], currentExtreme + (TRENDLINE_SETUP_MAX_PIPS_DISTANCE + 1) * Pip()
            );

            unitTest.assertEquals(
                -1,
                calculateOrderOpenPriceFromSetups(i)
            );

            ObjectDelete(trendLineName);
            trendLineName = trendLine.buildTrendLineName(50 + i, 20 + i, 0, discriminator);
            ObjectCreate(trendLineName, OBJ_TREND, 0,
                Time[50 + i], currentExtreme - (TRENDLINE_SETUP_MAX_PIPS_DISTANCE + 1) * Pip(),
                Time[20 + i], currentExtreme - (TRENDLINE_SETUP_MAX_PIPS_DISTANCE + 1) * Pip()
            );

            unitTest.assertEquals(
                -1,
                calculateOrderOpenPriceFromSetups(i)
            );

            ObjectDelete(trendLineName);
            trendLineName = trendLine.buildBadTrendLineName(50 + i, 20 + i, 0, discriminator);
            ObjectCreate(trendLineName, OBJ_TREND, 0, Time[50 + i], currentExtreme, Time[20 + i], currentExtreme);

            unitTest.assertEquals(
                -1,
                calculateOrderOpenPriceFromSetups(i)
            );

            ObjectDelete(trendLineName);
            trendLineName = trendLine.buildTrendLineName(50 + i, i, 0, discriminator);
            ObjectCreate(trendLineName, OBJ_TREND, 0, Time[50 + i], currentExtreme, Time[i], currentExtreme);

            unitTest.assertEquals(
                -1,
                calculateOrderOpenPriceFromSetups(i)
            );

            ObjectDelete(trendLineName);

            checkedAssertions++;
            trendLineTested = true;
        }
    }

    if (checkedAssertions < totalAssertions && IS_DEBUG) {
        Print(checkedAssertions, "/", totalAssertions, " checks run, some skipped..");
    }
*/
    ObjectsDeleteAll();
}

void OrderCreateTest::calculateOrderLotsTest() {
    UnitTest unitTest("calculateOrderLotsTest");

    const int stopLossPips = 10;
    const string symbol = Symbol();
/*
    unitTest.assertEquals(
        0.0,
        calculateOrderLots(stopLossPips, 0, symbol)
    );

    unitTest.assertEquals(
        NormalizeDouble(calculateOrderLots(stopLossPips, 1, symbol) / 2, 2),
        calculateOrderLots(stopLossPips, 1, symbol) / 2
    );

    unitTest.assertEquals(
        0.02,
        calculateOrderLots(stopLossPips, 0.0001, symbol)
    );

    unitTest.assertTrue(
        calculateOrderLots(stopLossPips, 1.5, symbol) > calculateOrderLots(stopLossPips, 1, symbol)
    );

    unitTest.assertTrue(
        calculateOrderLots(stopLossPips, 1, symbol) > 0
    );

    unitTest.assertTrue(
        calculateOrderLots(stopLossPips, 1, symbol) < 30 // max lots allowed per operation
    );
*/
}

void OrderCreateTest::getPercentRiskTest() {
    UnitTest unitTest("getPercentRiskTest");

    if (AccountNumber() == 2100183900) {
        unitTest.assertEquals(
            0.015,
            getPercentRisk()
        );
    } else {
        unitTest.assertEquals(
            PERCENT_RISK / 100,
            getPercentRisk()
        );
    }
}
