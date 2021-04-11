#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../UnitTest.mqh"
#include "../../src/order/Order.mqh"


class OrderTest {
    public:
        void isBreakEvenTest();
        void getPeriodTest();
        void getStopLossPipsTest();
        void buildCommentTest();
        void getVolatilityFromCommentTest();
        void isOpenTest();
        void isBuySellTest();
        void getDiscriminatorTest();
};

void OrderTest::isBreakEvenTest() {
    UnitTest unitTest("isBreakEvenTest");

    Order order;
    order.type = OP_BUY;

    unitTest.assertFalse(
        order.isBreakEven()
    );

    order.openPrice = 1.1;

    unitTest.assertFalse(
        order.isBreakEven()
    );

    order.stopLoss = order.openPrice;

    unitTest.assertTrue(
        order.isBreakEven()
    );

    order.stopLoss = order.openPrice + 10 * Pip();

    unitTest.assertTrue(
        order.isBreakEven()
    );

    order.type = OP_SELL;

    unitTest.assertFalse(
        order.isBreakEven()
    );

    order.stopLoss = order.openPrice - 10 * Pip();

    unitTest.assertTrue(
        order.isBreakEven()
    );
}

void OrderTest::getPeriodTest() {
    UnitTest unitTest("getPeriodTest");

    Order order;

    unitTest.assertEquals(
        -1,
        order.getPeriod()
    );

    order.magicNumber = 123;

    unitTest.assertEquals(
        -1,
        order.getPeriod()
    );

    order.magicNumber = MagicNumber();

    unitTest.assertEquals(
        Period(),
        order.getPeriod()
    );
}

void OrderTest::getStopLossPipsTest() {
    UnitTest unitTest("getStopLossPipsTest");

    Order order;

    unitTest.assertEquals(
        -1,
        order.getStopLossPips()
    );

    order.symbol = "CIAO";

    unitTest.assertEquals(
        -1,
        order.getStopLossPips()
    );

    order.symbol = Symbol();

    unitTest.assertTrue(
        order.getStopLossPips() > 0
    );
}

void OrderTest::buildCommentTest() {
    UnitTest unitTest("buildCommentTest");

    const int stopLoss = (int) MathRound(AverageTrueRange() * STOPLOSS_ATR_PERCENTAGE);

    Order order;
    order.magicNumber = -1;

    order.buildComment(1, 3);

    unitTest.assertEquals(
        "B P-1 V1 R3 S-1",
        order.comment
    );

    order.magicNumber = 837060;
    order.symbol = Symbol();

    order.buildComment(100, 3.5);

    unitTest.assertEquals(
        StringConcatenate("B P60 V100 R3.5 S", stopLoss),
        order.comment
    );

    order.buildComment(1111111111, 5);

    // It truncates a long comment
    unitTest.assertEquals(
        "B P60 V1111111111 R5",
        order.comment
    );
}

void OrderTest::getVolatilityFromCommentTest() {
    UnitTest unitTest("getVolatilityFromCommentTest");

    Order order;
    order.comment = "B P60 V50 R3 S10";

    unitTest.assertEquals(
        50,
        order.getVolatilityFromComment()
    );

    order.comment = "B P60 V150 R3 S10";

    unitTest.assertEquals(
        150,
        order.getVolatilityFromComment()
    );

    order.comment = "V50";

    unitTest.assertEquals(
        50,
        order.getVolatilityFromComment()
    );

    order.comment = "B P60 W1 R3 S10";

    unitTest.assertEquals(
        -1,
        order.getVolatilityFromComment()
    );

    order.comment = "W1";

    unitTest.assertEquals(
        -1,
        order.getVolatilityFromComment()
    );

    order.comment = "asdasdV123asdasd";

    unitTest.assertEquals(
        123,
        order.getVolatilityFromComment()
    );

    order.comment = NULL;

    unitTest.assertEquals(
        -1,
        order.getVolatilityFromComment()
    );
}

void OrderTest::isOpenTest() {
    UnitTest unitTest("isOpenTest");

    Order order;

    unitTest.assertFalse(
        order.isOpen()
    );

    order.type = OP_BUYSTOP;

    unitTest.assertFalse(
        order.isOpen()
    );

    order.type = OP_BUY;

    unitTest.assertTrue(
        order.isOpen()
    );
}

void OrderTest::isBuySellTest() {
    UnitTest unitTest("isBuySellTest");

    Order order;

    unitTest.assertFalse(
        order.isBuy()
    );

    unitTest.assertTrue(
        order.isSell()
    );

    order.type = OP_SELL;

    unitTest.assertFalse(
        order.isBuy()
    );

    unitTest.assertTrue(
        order.isSell()
    );

    order.type = OP_BUYSTOP;

    unitTest.assertTrue(
        order.isBuy()
    );

    unitTest.assertFalse(
        order.isSell()
    );
}

void OrderTest::getDiscriminatorTest() {
    UnitTest unitTest("getDiscriminatorTest");

    Order order;

    unitTest.assertEquals(
        Min,
        order.getDiscriminator()
    );

    order.type = OP_BUY;

    unitTest.assertEquals(
        Max,
        order.getDiscriminator()
    );

    order.type = OP_SELLLIMIT;

    unitTest.assertEquals(
        Min,
        order.getDiscriminator()
    );
}
