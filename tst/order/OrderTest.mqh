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
        void getSizeFactorFromCommentTest();
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

    /*
    Order order;

    unitTest.assertEquals(
        -1,
        order.getStopLossPips()
    );

    order.openPrice = 1.1;
    order.stopLoss = 1.10102;

    unitTest.assertEquals(
        -1,
        order.getStopLossPips()
    );

    order.symbol = "EURUSD";

    unitTest.assertEquals(
        10,
        order.getStopLossPips()
    );

    order.openPrice = 1.11;
    order.stopLoss = 1.1;
    order.symbol = "EURJPY";

    unitTest.assertEquals(
        1,
        order.getStopLossPips()
    );
    */
}

void OrderTest::buildCommentTest() {
    UnitTest unitTest("buildCommentTest");
/*
    Order order;
    order.magicNumber = 837060;
    order.symbol = Symbol();
    order.openPrice = GetPrice();
    order.stopLoss = order.openPrice + 10 * Pip();

    order.buildComment(1, 3);

    unitTest.assertEquals(
        "B P60 V1 R3 S10",
        order.comment
    );

    order.magicNumber = 837060;
    order.stopLoss = order.openPrice + 123456789 * Pip();

    order.buildComment(2, 2.5);

    // It truncates a long comment
    unitTest.assertEquals(
        "B P60 V2 R2.5 S123",
        order.comment
    );

    order.magicNumber = -1;
    order.symbol = NULL;
    order.stopLoss = order.openPrice + 10 * Pip();

    order.buildComment(1, 3);

    unitTest.assertEquals(
        "B P-1 V1 R3 S-1",
        order.comment
    );
*/
}

void OrderTest::getSizeFactorFromCommentTest() {
    UnitTest unitTest("getSizeFactorFromCommentTest");

/*
    Order order;
    order.comment = "B P30 M1.3 R3 S10";

    unitTest.assertEquals(
        1.3,
        order.getSizeFactorFromComment()
    );

    order.comment = "B P30 M1 R3 S10";

    unitTest.assertEquals(
        1.0,
        order.getSizeFactorFromComment()
    );

    order.comment = "M0.8";

    unitTest.assertEquals(
        0.8,
        order.getSizeFactorFromComment()
    );

    order.comment = "B P30 W1 R3 S10";

    unitTest.assertEquals(
        -1.0,
        order.getSizeFactorFromComment()
    );

    order.comment = "W1";

    unitTest.assertEquals(
        -1.0,
        order.getSizeFactorFromComment()
    );

    order.comment = "asdasdM123asdasd";

    unitTest.assertEquals(
        123.0,
        order.getSizeFactorFromComment()
    );

    order.comment = NULL;

    unitTest.assertEquals(
        -1.0,
        order.getSizeFactorFromComment()
    );
*/
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
