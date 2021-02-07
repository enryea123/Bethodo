#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../UnitTest.mqh"
#include "../../src/order/Order.mqh"
#include "../../src/order/OrderTrail.mqh"


class OrderTrailTest: public OrderTrail {
    public:
        void calculateBreakEvenStopLossTest();
};

void OrderTrailTest::calculateBreakEvenStopLossTest() {
    UnitTest unitTest("calculateBreakEvenStopLossTest");

/*
    Order order;
    order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H1;
    order.symbol = Symbol();
    order.type = OP_BUY;
    order.openPrice = iExtreme(Max, 0) - 5 * Pip(order.symbol);
    order.stopLoss = order.openPrice - 10 * Pip(order.symbol);

    unitTest.assertEquals(
        order.stopLoss,
        calculateBreakEvenStopLoss(order)
    );

    order.openPrice = iExtreme(Max, 0) - 7 * Pip(order.symbol);
    order.stopLoss = order.openPrice - 10 * Pip(order.symbol);

    unitTest.assertEquals(
        order.openPrice - 4 * Pip(order.symbol),
        calculateBreakEvenStopLoss(order)
    );

    order.type = OP_SELL;
    order.openPrice = iExtreme(Min, 0) + 9 * Pip(order.symbol);
    order.stopLoss = order.openPrice + 20 * Pip(order.symbol);

    unitTest.assertEquals(
        order.openPrice + 4 * Pip(order.symbol),
        calculateBreakEvenStopLoss(order)
    );

    order.openPrice = iExtreme(Min, 0) + 27 * Pip(order.symbol);
    order.stopLoss = order.openPrice + 20 * Pip(order.symbol);

    unitTest.assertEquals(
        order.openPrice,
        calculateBreakEvenStopLoss(order)
    );
*/
}
