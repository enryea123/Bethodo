#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../UnitTest.mqh"
#include "../../src/util/Price.mqh"


class PriceTest {
    public:
        void priceTest();
};

void PriceTest::priceTest() {
    UnitTest unitTest("priceTest");

    unitTest.assertEquals(
        iHigh(Symbol(), Period(), 10),
        iExtreme(Max, 10)
    );

    unitTest.assertEquals(
        iLow(Symbol(), Period(), 1),
        iExtreme(Min, 1)
    );

    unitTest.assertEquals(
        -1.0,
        iExtreme(Max, -10)
    );

    unitTest.assertEquals(
        -1.0,
        iCandle(I_open, "CIAO", PERIOD_H1, 5)
    );

    unitTest.assertEquals(
        0.0,
        iCandle(I_open, Symbol(), 9999, 5)
    );

    unitTest.assertTrue(
        MathAbs(iCandle(I_time, -5) - TimeCurrent()) < 10
    );

    unitTest.assertTrue(
        FindPriceGap(50, -1)
    );

    unitTest.assertTrue(
        FindPriceGap(50, 10 * Pip())
    );

    unitTest.assertFalse(
        FindPriceGap(50, 100)
    );
}
