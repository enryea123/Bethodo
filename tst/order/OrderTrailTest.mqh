#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../UnitTest.mqh"
#include "../../src/order/Order.mqh"
#include "../../src/order/OrderTrail.mqh"


class OrderTrailTest: public OrderTrail {
    public:
        void calculateBreakEvenStopLossTest();
        void calculateTrailingStopLossTest();
        void getPreviousExtremeTest();
        void closeOrderForTrailingProfitTest();
};

void OrderTrailTest::calculateBreakEvenStopLossTest() {
    UnitTest unitTest("calculateBreakEvenStopLossTest");

    const double currentPrice = GetPrice();

    Order order;
    order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H1;
    order.symbol = Symbol();
    order.type = OP_BUY;
    order.openPrice = currentPrice - 0.6 * order.getStopLossPips() * Pip(order.symbol);
    order.stopLoss = order.openPrice - order.getStopLossPips() * Pip(order.symbol);

    unitTest.assertEquals(
        order.stopLoss,
        calculateBreakEvenStopLoss(order)
    );

    order.openPrice = currentPrice - 1.6 * order.getStopLossPips() * Pip(order.symbol);
    order.stopLoss = order.openPrice - order.getStopLossPips() * Pip(order.symbol);

    unitTest.assertEquals(
        order.openPrice + Pip(order.symbol),
        calculateBreakEvenStopLoss(order)
    );

    order.type = OP_SELL;
    order.openPrice = currentPrice + 1.6 * order.getStopLossPips() * Pip(order.symbol);
    order.stopLoss = order.openPrice + order.getStopLossPips() * Pip(order.symbol);

    unitTest.assertEquals(
        order.openPrice - Pip(order.symbol),
        calculateBreakEvenStopLoss(order)
    );
}

void OrderTrailTest::calculateTrailingStopLossTest() {
    UnitTest unitTest("calculateTrailingStopLossTest");

    const double currentPrice = GetPrice();

    Order order;
    order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H1;
    order.symbol = Symbol();
    order.type = OP_BUY;
    order.openPrice = currentPrice - 0.6 * order.getStopLossPips() * Pip(order.symbol);
    order.stopLoss = order.openPrice - order.getStopLossPips() * Pip(order.symbol);

    double expected = order.stopLoss;

    unitTest.assertEquals(
        expected,
        calculateTrailingStopLoss(order)
    );

    order.openPrice = currentPrice - 2.6 * order.getStopLossPips() * Pip(order.symbol);
    order.stopLoss = order.openPrice - order.getStopLossPips() * Pip(order.symbol);

    expected = order.stopLoss;

    unitTest.assertEquals(
        expected,
        calculateTrailingStopLoss(order)
    );

    order.stopLoss = order.openPrice;

    expected = MathMax(order.stopLoss, getPreviousExtreme(Min, TRAILING_STEPS.get(2)) -
        TRAILING_BUFFER_PIPS * Pip(order.symbol));

    unitTest.assertEquals(
        expected,
        calculateTrailingStopLoss(order)
    );

    order.openPrice = currentPrice - 3.2 * order.getStopLossPips() * Pip(order.symbol);
    order.stopLoss = order.openPrice;

    expected = MathMax(order.stopLoss, getPreviousExtreme(Min, TRAILING_STEPS.get(3)) -
        TRAILING_BUFFER_PIPS * Pip(order.symbol));

    unitTest.assertEquals(
        expected,
        calculateTrailingStopLoss(order)
    );

    order.openPrice = currentPrice - 9.0 * order.getStopLossPips() * Pip(order.symbol);
    order.stopLoss = order.openPrice;

    expected = MathMax(order.stopLoss, getPreviousExtreme(Min, TRAILING_STEPS.get(4)) -
        TRAILING_BUFFER_PIPS * Pip(order.symbol));

    unitTest.assertEquals(
        expected,
        calculateTrailingStopLoss(order)
    );

    order.type = OP_SELL;
    order.openPrice = currentPrice + 4.3 * order.getStopLossPips() * Pip(order.symbol);
    order.stopLoss = order.openPrice;

    expected = MathMin(order.stopLoss, getPreviousExtreme(Max, TRAILING_STEPS.get(4)) +
        TRAILING_BUFFER_PIPS * Pip(order.symbol));

    unitTest.assertEquals(
        expected,
        calculateTrailingStopLoss(order)
    );
}

void OrderTrailTest::getPreviousExtremeTest() {
    UnitTest unitTest("getPreviousExtremeTest");

    Discriminator discriminator = Max;

    double candle0 = iExtreme(discriminator, 0);
    double candle1 = iExtreme(discriminator, 1);
    double candle2 = iExtreme(discriminator, 2);
    double candle3 = iExtreme(discriminator, 3);
    double candle4 = iExtreme(discriminator, 4);

    double previousExtreme = MathMax(candle0, MathMax(MathMax(candle1, candle2), MathMax(candle3, candle4)));

    unitTest.assertEquals(
        previousExtreme,
        getPreviousExtreme(discriminator, 4)
    );

    unitTest.assertEquals(
        MathMax(candle0, candle1),
        getPreviousExtreme(discriminator, 1)
    );

    unitTest.assertEquals(
        candle0,
        getPreviousExtreme(discriminator, 0)
    );

    discriminator = Min;

    candle0 = iExtreme(discriminator, 0);
    candle1 = iExtreme(discriminator, 1);
    candle2 = iExtreme(discriminator, 2);
    candle3 = iExtreme(discriminator, 3);
    candle4 = iExtreme(discriminator, 4);

    previousExtreme = MathMin(candle0, MathMin(MathMin(candle1, candle2), MathMin(candle3, candle4)));

    unitTest.assertEquals(
        previousExtreme,
        getPreviousExtreme(discriminator, 4)
    );

    unitTest.assertEquals(
        -1.0,
        getPreviousExtreme(discriminator, -1)
    );
}

void OrderTrailTest::closeOrderForTrailingProfitTest() {
    UnitTest unitTest("closeOrderForTrailingProfitTest");

    const double lastCandleClose = iCandle(I_close, 1);

    Order order;
    order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H1;
    order.symbol = Symbol();
    order.type = OP_BUY;
    order.openPrice = lastCandleClose - (TRAILING_PROFIT_GAIN_CLOSE + 0.1) * order.getStopLossPips() * Pip(order.symbol);

    unitTest.assertTrue(
        closeOrderForTrailingProfit(order)
    );

    order.openPrice = lastCandleClose - 2.6 * order.getStopLossPips() * Pip(order.symbol);

    unitTest.assertFalse(
        closeOrderForTrailingProfit(order)
    );

    order.type = OP_SELL;
    order.openPrice = lastCandleClose + (TRAILING_PROFIT_GAIN_CLOSE + 0.1) * order.getStopLossPips() * Pip(order.symbol);

    unitTest.assertTrue(
        closeOrderForTrailingProfit(order)
    );
}
