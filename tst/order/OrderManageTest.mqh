#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../UnitTest.mqh"
#include "../../src/order/Order.mqh"
#include "../../src/order/OrderManage.mqh"


class OrderManageTest: public OrderManage {
    public:
        void areThereOpenOrdersTest();
        void areThereOrdersThisSymbolThisPeriodTest();
        void findBestOrderTest();
        void deduplicateOrdersTest();
        void emergencySwitchOffTest();
        void lossLimiterTest();
        void deleteAllOrdersTest();
        void deletePendingOrdersTest();
};

void OrderManageTest::areThereOpenOrdersTest() {
    UnitTest unitTest("areThereOpenOrdersTest");

    Order order;
    order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H1;
    order.symbol = Symbol();
    order.type = OP_SELLSTOP;

    orderFind_.setMockedOrders(order);
    unitTest.assertFalse(
        areThereOpenOrders()
    );

    order.type = OP_BUY;
    orderFind_.setMockedOrders(order);

    unitTest.assertTrue(
        areThereOpenOrders()
    );

    order.symbol = "CIAO";
    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereOpenOrders()
    );

    order.symbol = Symbol();
    order.magicNumber = 999999;
    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereOpenOrders()
    );

    orderFind_.deleteAllMockedOrders();
}

void OrderManageTest::areThereOrdersThisSymbolThisPeriodTest() {
    UnitTest unitTest("areThereOrdersThisSymbolThisPeriodTest");

    Order order;
    order.magicNumber = BASE_MAGIC_NUMBER + Period();
    order.symbol = Symbol();

    orderFind_.setMockedOrders(order);
    unitTest.assertTrue(
        areThereOrdersThisSymbolThisPeriod()
    );

    order.symbol = StringConcatenate(SymbolFamily(), "CIA");
    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereOrdersThisSymbolThisPeriod()
    );

    order.symbol = Symbol();
    order.magicNumber = BASE_MAGIC_NUMBER;
    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereOrdersThisSymbolThisPeriod()
    );

    order.symbol = Symbol();
    order.magicNumber = 999999;
    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereOrdersThisSymbolThisPeriod()
    );

    orderFind_.deleteAllMockedOrders();
}

void OrderManageTest::findBestOrderTest() {
    UnitTest unitTest("findBestOrderTest");

    Order orders[];
    ArrayResize(orders, 2);
    orders[0].symbol = Symbol();
    orders[0].type = OP_SELLSTOP;
    orders[0].openPrice = GetPrice(orders[0].symbol);
    orders[0].stopLoss = orders[0].openPrice + 20 * Pip();

    orders[1] = orders[0];

    unitTest.assertTrue(
        findBestOrder(orders[0], orders[1])
    );

    orders[1].type = OP_BUY;

    unitTest.assertFalse(
        findBestOrder(orders[0], orders[1])
    );

    orders[1].type = OP_SELLSTOP;
    orders[1].stopLoss -= 2 * Pip();

    unitTest.assertFalse(
        findBestOrder(orders[0], orders[1])
    );
}

void OrderManageTest::deduplicateOrdersTest() {
    UnitTest unitTest("deduplicateOrdersTest");

    Order orders[];
    ArrayResize(orders, 1);
    orders[0].magicNumber = BASE_MAGIC_NUMBER + PERIOD_H1;
    orders[0].symbol = Symbol();
    orders[0].type = OP_SELLSTOP;
    orders[0].openPrice = GetPrice(orders[0].symbol);
    orders[0].stopLoss = orders[0].openPrice + 20 * Pip();

    Order mockedOrders[];

    orderFind_.setMockedOrders(orders);
    deduplicateOrders();
    orderFind_.getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        orders,
        mockedOrders
    );

    ArrayResize(orders, 2);
    orders[1] = orders[0];
    ArrayFree(mockedOrders);

    orderFind_.setMockedOrders(orders);
    deduplicateOrders();
    orderFind_.getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        1,
        ArraySize(mockedOrders)
    );

    unitTest.assertEquals(
        orders[0],
        mockedOrders[0]
    );

    orders[0].symbol = "CIAO";
    ArrayFree(mockedOrders);

    orderFind_.setMockedOrders(orders);
    deduplicateOrders();
    orderFind_.getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        orders,
        mockedOrders
    );

    orders[0].symbol = Symbol();

    orders[1].type = OP_BUYSTOP;
    ArrayFree(mockedOrders);

    orderFind_.setMockedOrders(orders);
    deduplicateOrders();
    orderFind_.getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        orders,
        mockedOrders
    );

    orders[1].type = OP_SELL;
    ArrayResize(orders, 3);
    orders[2] = orders[0];
    ArrayFree(mockedOrders);

    orderFind_.setMockedOrders(orders);
    deduplicateOrders();
    orderFind_.getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        1,
        ArraySize(mockedOrders)
    );

    unitTest.assertEquals(
        orders[1],
        mockedOrders[0]
    );

    orderFind_.deleteAllMockedOrders();
}

void OrderManageTest::emergencySwitchOffTest() {
    UnitTest unitTest("emergencySwitchOffTest");

    Order orders[];
    ArrayResize(orders, 3);
    orders[0].magicNumber = MagicNumber();
    orders[1].magicNumber = MagicNumber();
    orders[2].magicNumber = (MagicNumber() == BASE_MAGIC_NUMBER + PERIOD_H4) ?
        BASE_MAGIC_NUMBER + PERIOD_H1 : BASE_MAGIC_NUMBER + PERIOD_H4;
    orders[0].symbol = Symbol();
    orders[1].symbol = orders[0].symbol;
    orders[2].symbol = orders[0].symbol;

    Order mockedOrders[];

    orderFind_.setMockedOrders(orders);
    emergencySwitchOff();
    orderFind_.getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        3,
        ArraySize(mockedOrders)
    );

    orders[1].magicNumber = 9999999;
    ArrayFree(mockedOrders);

    orderFind_.setMockedOrders(orders);
    emergencySwitchOff();
    orderFind_.getMockedOrders(mockedOrders);

    // An unknown magicNumber is not enough to trigger the emergency mechanism
    unitTest.assertEquals(
        3,
        ArraySize(mockedOrders)
    );

    orders[1].openPrice = EMERGENCY_SWITCHOFF_OPENPRICE;
    ArrayFree(mockedOrders);

    orderFind_.setMockedOrders(orders);
    emergencySwitchOff();
    orderFind_.getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        3,
        ArraySize(mockedOrders)
    );

    orders[1].stopLoss = EMERGENCY_SWITCHOFF_STOPLOSS;
    orders[1].takeProfit = EMERGENCY_SWITCHOFF_TAKEPROFIT;
    ArrayFree(mockedOrders);

    orderFind_.setMockedOrders(orders);
    emergencySwitchOff();
    orderFind_.getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        2, // deleteAllOrders() only deletes orders with MagicNumber()
        ArraySize(mockedOrders)
    );

    unitTest.assertEquals(
        orders[2],
        mockedOrders[0]
    );

    unitTest.assertEquals(
        orders[1],
        mockedOrders[1]
    );

    orderFind_.deleteAllMockedOrders();
}

void OrderManageTest::lossLimiterTest() {
    UnitTest unitTest("lossLimiterTest");

    const double maxAllowedLosses = AccountEquity() * LOSS_LIMITER_MAX_ALLOWED_LOSSES_PERCENT / 100;

    Order orders[];
    ArrayResize(orders, 3);
    orders[0].magicNumber = MagicNumber();
    orders[1].magicNumber = MagicNumber();
    orders[2].magicNumber = 9999999;
    orders[0].symbol = Symbol();
    orders[1].symbol = orders[0].symbol;
    orders[2].symbol = orders[0].symbol;

    orders[0].profit = 50.4;
    orders[1].profit = 0;
    orders[2].profit = -50;

    orders[0].closeTime = TimeCurrent();
    orders[1].closeTime = orders[0].closeTime;
    orders[2].closeTime = orders[0].closeTime;

    Order mockedOrders[];

    orderFind_.setMockedOrders(orders);
    lossLimiter();
    orderFind_.getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        orders,
        mockedOrders
    );

    orders[0].profit = - maxAllowedLosses / 2;
    orders[1].profit = - maxAllowedLosses / 2 + 1;
    ArrayFree(mockedOrders);

    orderFind_.setMockedOrders(orders);
    lossLimiter();
    orderFind_.getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        orders,
        mockedOrders
    );

    orders[1].profit = - maxAllowedLosses;
    ArrayFree(mockedOrders);

    orderFind_.setMockedOrders(orders);
    lossLimiter();
    orderFind_.getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        1, // deleteAllOrders() only deletes orders with MagicNumber()
        ArraySize(mockedOrders)
    );

    unitTest.assertEquals(
        orders[2],
        mockedOrders[0]
    );

    orders[1].closeTime = (datetime) (TimeCurrent() - LOSS_LIMITER_HOURS * 3600 - 10);
    ArrayFree(mockedOrders);

    orderFind_.setMockedOrders(orders);
    lossLimiter();
    orderFind_.getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        orders,
        mockedOrders
    );

    orderFind_.deleteAllMockedOrders();
}

void OrderManageTest::deleteAllOrdersTest() {
    UnitTest unitTest("deleteAllOrdersTest");

    Order orders[];
    ArrayResize(orders, 2);
    orders[0].magicNumber = MagicNumber();
    orders[0].symbol = Symbol();
    orders[1] = orders[0];

    Order mockedOrders[];

    orderFind_.setMockedOrders(orders);
    deleteAllOrders();
    orderFind_.getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        0,
        ArraySize(mockedOrders)
    );

    orders[0].symbol = "CIAO";
    ArrayFree(mockedOrders);

    orderFind_.setMockedOrders(orders);
    deleteAllOrders();
    orderFind_.getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        1,
        ArraySize(mockedOrders)
    );

    unitTest.assertEquals(
        orders[0],
        mockedOrders[0]
    );

    orders[0].symbol = Symbol();
    orders[0].magicNumber = (MagicNumber() == BASE_MAGIC_NUMBER + PERIOD_H4) ?
        BASE_MAGIC_NUMBER + PERIOD_H1 : BASE_MAGIC_NUMBER + PERIOD_H4;
    ArrayFree(mockedOrders);

    orderFind_.setMockedOrders(orders);
    deleteAllOrders();
    orderFind_.getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        1,
        ArraySize(mockedOrders)
    );

    unitTest.assertEquals(
        orders[0],
        mockedOrders[0]
    );

    orderFind_.deleteAllMockedOrders();
}

void OrderManageTest::deletePendingOrdersTest() {
    UnitTest unitTest("deletePendingOrdersTest");

    Order orders[];
    ArrayResize(orders, 2);
    orders[0].magicNumber = MagicNumber();
    orders[0].symbol = Symbol();
    orders[0].type = OP_BUYSTOP;
    orders[1] = orders[0];
    orders[1].type = OP_SELLSTOP;

    Order mockedOrders[];

    orderFind_.setMockedOrders(orders);
    deletePendingOrders();
    orderFind_.getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        0,
        ArraySize(mockedOrders)
    );

    orders[0].symbol = "CIAO";
    ArrayFree(mockedOrders);

    orderFind_.setMockedOrders(orders);
    deletePendingOrders();
    orderFind_.getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        1,
        ArraySize(mockedOrders)
    );

    unitTest.assertEquals(
        orders[0],
        mockedOrders[0]
    );

    orders[0].symbol = Symbol();
    orders[1].type = OP_SELL;
    ArrayFree(mockedOrders);

    orderFind_.setMockedOrders(orders);
    deletePendingOrders();
    orderFind_.getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        1,
        ArraySize(mockedOrders)
    );

    unitTest.assertEquals(
        orders[1],
        mockedOrders[0]
    );

    orderFind_.deleteAllMockedOrders();
}
