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
        void findOrderChannelSetupTest();
        void calculateOrderLotsTest();
};

void OrderCreateTest::areThereRecentOrdersTest() {
    UnitTest unitTest("areThereRecentOrdersTest");

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

    order.closeTime = (datetime) "2020-09-01 2:50";
    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereRecentOrders(filterDate)
    );

    order.closeTime = (datetime) "2020-09-01 12:10";
    orderFind_.setMockedOrders(order);

    unitTest.assertTrue(
        areThereRecentOrders(filterDate)
    );

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
    order.symbol = "EURUSD";
    order.type = OP_SELLSTOP;
    order.comment = "V50";

    Order newOrder;
    newOrder = order;

    orderFind_.setMockedOrders(order);

    unitTest.assertTrue(
        areThereBetterOrders(newOrder)
    );

    newOrder.comment = "V60";

    unitTest.assertTrue(
        areThereBetterOrders(newOrder)
    );

    newOrder.symbol = "AUDUSD";

    unitTest.assertFalse(
        areThereBetterOrders(newOrder)
    );

    newOrder.comment = "V40";

    unitTest.assertTrue(
        areThereBetterOrders(newOrder)
    );

    newOrder.symbol = "NZDCHF";

    unitTest.assertFalse(
        areThereBetterOrders(newOrder)
    );

    newOrder.symbol = "AUDUSD";
    newOrder.type = OP_SELL;

    unitTest.assertFalse(
        areThereBetterOrders(newOrder)
    );

    newOrder.type = OP_BUYSTOP;

    unitTest.assertFalse(
        areThereBetterOrders(newOrder)
    );

    newOrder.type = OP_SELLSTOP;
    order.type = OP_BUY;
    orderFind_.setMockedOrders(order);

    unitTest.assertTrue(
        areThereBetterOrders(newOrder)
    );

    order.type = OP_SELLSTOP;
    order.magicNumber = 999999;
    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereBetterOrders(newOrder)
    );

    order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H1;

    Order orders[];
    ArrayResize(orders, 2);
    orders[0] = order;
    orders[1] = order;
    orders[1].comment = "V60";

    newOrder = orders[0];
    newOrder.symbol = "AUDUSD";
    orderFind_.setMockedOrders(orders);

    unitTest.assertTrue(
        areThereBetterOrders(newOrder)
    );

    orderFind_.deleteAllMockedOrders();
}

void OrderCreateTest::findOrderChannelSetupTest() {
    UnitTest unitTest("findOrderChannelSetupTest");

    TrendLine trendLine;

    unitTest.assertEquals(
        "",
        findOrderChannelSetup(-1)
    );

    const double currentMarketValue = GetPrice();

    string trendLineName = trendLine.buildTrendLineName(50, 0, 0, Max);
    ObjectCreate(trendLineName, OBJ_TREND, 0, Time[50], currentMarketValue, Time[0], currentMarketValue);

    unitTest.assertEquals(
        "",
        findOrderChannelSetup(0)
    );

    ObjectSet(trendLineName, OBJPROP_COLOR, CHANNEL_COLOR);
    ObjectSet(trendLineName, OBJPROP_WIDTH, CHANNEL_LINE_WIDTH);

    unitTest.assertEquals(
        trendLineName,
        findOrderChannelSetup(0)
    );

    ObjectDelete(trendLineName);
    ObjectCreate(trendLineName, OBJ_TREND, 0, Time[50], currentMarketValue + 20 * Pip(),
        Time[0], currentMarketValue + 20 * Pip());
    ObjectSet(trendLineName, OBJPROP_COLOR, CHANNEL_COLOR);
    ObjectSet(trendLineName, OBJPROP_WIDTH, CHANNEL_LINE_WIDTH);

    unitTest.assertEquals(
        "",
        findOrderChannelSetup(0)
    );

    ObjectDelete(trendLineName);
    ObjectCreate(trendLineName, OBJ_TREND, 0, Time[50], currentMarketValue + 20 * Pip(),
        Time[0], currentMarketValue);
    ObjectSet(trendLineName, OBJPROP_COLOR, CHANNEL_COLOR);
    ObjectSet(trendLineName, OBJPROP_WIDTH, CHANNEL_LINE_WIDTH);

    unitTest.assertEquals(
        trendLineName,
        findOrderChannelSetup(0)
    );

    ObjectDelete(trendLineName);
    ObjectCreate(trendLineName, OBJ_TREND, 0, Time[50], currentMarketValue - 20 * Pip(),
        Time[0], currentMarketValue);
    ObjectSet(trendLineName, OBJPROP_COLOR, CHANNEL_COLOR);
    ObjectSet(trendLineName, OBJPROP_WIDTH, CHANNEL_LINE_WIDTH);

    unitTest.assertEquals(
        "",
        findOrderChannelSetup(0)
    );

    ObjectsDeleteAll();
}

void OrderCreateTest::calculateOrderLotsTest() {
    UnitTest unitTest("calculateOrderLotsTest");

    const int stopLossPips = 10;
    const string symbol = Symbol();

    unitTest.assertTrue(
        calculateOrderLots(10, symbol) > 0
    );

    unitTest.assertTrue(
        calculateOrderLots(10, symbol) < 30 // max lots allowed per operation
    );

    unitTest.assertEquals(
        -1.0,
        calculateOrderLots(0, symbol)
    );

    unitTest.assertEquals(
        -1.0,
        calculateOrderLots(stopLossPips, "CIAO")
    );
}
