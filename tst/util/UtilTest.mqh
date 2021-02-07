#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../UnitTest.mqh"
#include "../../src/util/Util.mqh"


class UtilTest {
    public:
        void utilTest();
};

void UtilTest::utilTest() {
    UnitTest unitTest("utilTest");

    unitTest.assertEquals(
        0.0001,
        Pip("EURUSD")
    );

    unitTest.assertEquals(
        0.01,
        Pip("GBPJPY")
    );

    unitTest.assertEquals(
        -1.0,
        Pip("CIAO")
    );

    unitTest.assertEquals(
        1,
        PeriodFactor(PERIOD_M30)
    );

    unitTest.assertEquals(
        2,
        PeriodFactor(PERIOD_H4)
    );

    unitTest.assertTrue(
        StringContains("asdCIAOasd", "CIAO")
    );

    unitTest.assertFalse(
        StringContains("asdCIaOasd", "CIAO")
    );

    unitTest.assertFalse(
        StringContains("", "CIAO")
    );

    unitTest.assertTrue(
        StringContains("CIAOCIAO", "CIAO")
    );

    unitTest.assertTrue(
        SymbolExists("EURUSD")
    );

    unitTest.assertTrue(
        SymbolExists(Symbol())
    );

    unitTest.assertFalse(
        SymbolExists("eurusd")
    );

    unitTest.assertFalse(
        SymbolExists("CIAO")
    );

    unitTest.assertEquals(
        "EUR",
        SymbolFamily("EURUSD")
    );

    unitTest.assertEquals(
        "NZD",
        SymbolFamily("NZDUSD")
    );

    unitTest.assertEquals(
        "USD",
        SymbolFamily("USDCHF")
    );

    unitTest.assertEquals(
        "CIAO",
        SymbolFamily("CIAO")
    );

    unitTest.assertEquals(
        "CI",
        SymbolFamily("CI")
    );

    unitTest.assertEquals(
        (datetime) "2020-06-18",
        GetDate((datetime) "2020-06-18 19.46.12")
    );
}
