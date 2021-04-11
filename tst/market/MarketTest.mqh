#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../UnitTest.mqh"
#include "../../src/market/Market.mqh"
#include "../../src/news/News.mqh"
#include "../../src/news/NewsDraw.mqh"


class MarketTest: public Market {
    public:
        void isMarketOpenedTest();
        void isAllowedAccountNumberTest();
        void isAllowedExecutionDateTest();
        void isAllowedPeriodTest();
        void isAllowedBrokerTest();
        void isAllowedSymbolTest();
        void isAllowedSymbolPeriodComboTest();
        void isDemoTradingTest();
};

void MarketTest::isMarketOpenedTest() {
    UnitTest unitTest("isMarketOpenedTest");

    if (GetSpread() > SPREAD_PIPS_CLOSE_MARKET - 1) {
        if (IS_DEBUG) {
            Print("isMarketOpenedTest: skipped for high spread..");
        }
        return;
    }

    unitTest.assertFalse(
        isMarketOpened((datetime) "2020-04-06 23:55")
    );

    unitTest.assertTrue(
        isMarketOpened((datetime) "2020-04-07 00:01")
    );

    unitTest.assertTrue(
        isMarketOpened((datetime) "2021-06-30 13:02")
    );

    unitTest.assertFalse(
        isMarketOpened((datetime) "2021-06-30 15:30")
    );

    unitTest.assertFalse(
        isMarketOpened((datetime) "2020-12-25 12:00"),"12" // Vacation
    );

    News news;
    news.title = "Fake news for MarketTest";
    news.country = Symbol();
    news.impact = "High";
    news.date = (datetime) "2020-04-07 10:50";

    NewsDraw newsDraw;
    newsDraw.drawSingleNewsLine(news);

    unitTest.assertTrue(
        isMarketOpened((datetime) "2020-04-07 9:45")
    );

    unitTest.assertFalse(
        isMarketOpened((datetime) "2020-04-07 9:55")
    );

    unitTest.assertFalse(
        isMarketOpened((datetime) "2020-04-07 10:50")
    );

    unitTest.assertTrue(
        isMarketOpened((datetime) "2020-04-07 11:55")
    );

    unitTest.assertFalse(
        isMarketOpened((datetime) "2020-04-07 11:45")
    );

    ObjectsDeleteAll();
}

void MarketTest::isAllowedAccountNumberTest() {
    UnitTest unitTest("isAllowedAccountNumberTest");

    unitTest.assertTrue(
        isAllowedAccountNumber(2100219063)
    );

    unitTest.assertFalse(
        isAllowedAccountNumber(123)
    );
}

void MarketTest::isAllowedExecutionDateTest() {
    UnitTest unitTest("isAllowedExecutionDateTest");

    unitTest.assertTrue(
        isAllowedExecutionDate((datetime) "2020-03-12")
    );

    unitTest.assertFalse(
        isAllowedExecutionDate((datetime) "2021-07-12")
    );
}

void MarketTest::isAllowedPeriodTest() {
    UnitTest unitTest("isAllowedPeriodTest");

    unitTest.assertTrue(
        isAllowedPeriod()
    );

    unitTest.assertTrue(
        isAllowedPeriod(PERIOD_H1)
    );

    unitTest.assertFalse(
        isAllowedPeriod(PERIOD_D1)
    );
}

void MarketTest::isAllowedSymbolTest() {
    UnitTest unitTest("isAllowedSymbolTest");

    unitTest.assertTrue(
        isAllowedSymbol()
    );

    unitTest.assertTrue(
        isAllowedSymbol("GBPUSD")
    );

    if (isDemoTrading()) {
        unitTest.assertTrue(
            isAllowedSymbol("EURNOK")
        );
    }

    accountTypeOverride();

    unitTest.assertFalse(
        isAllowedSymbol("EURNOK")
    );

    accountTypeOverrideReset();

    unitTest.assertFalse(
        isAllowedSymbol("CIAO")
    );
}

void MarketTest::isAllowedBrokerTest() {
    UnitTest unitTest("isAllowedBrokerTest");

    const string randomBrokerName = "RandomBrokerName";

    unitTest.assertTrue(
        isAllowedBroker(AccountCompany())
    );

    if (isDemoTrading()) {
        unitTest.assertTrue(
            isAllowedBroker(randomBrokerName)
        );
    } else {
        unitTest.assertFalse(
            isAllowedBroker(randomBrokerName)
        );
    }

    accountTypeOverride();

    unitTest.assertFalse(
        isAllowedBroker(randomBrokerName)
    );

    accountTypeOverrideReset();
}

void MarketTest::isAllowedSymbolPeriodComboTest() {
    UnitTest unitTest("isAllowedSymbolPeriodComboTest");

    accountTypeOverride();

    unitTest.assertFalse(
        isAllowedSymbolPeriodCombo("EURJPY", PERIOD_M30)
    );

    unitTest.assertTrue(
        isAllowedSymbolPeriodCombo("EURJPY", PERIOD_H1)
    );

    unitTest.assertTrue(
        isAllowedSymbolPeriodCombo("EURUSD", PERIOD_H1)
    );

    accountTypeOverrideReset();
}

void MarketTest::isDemoTradingTest() {
    UnitTest unitTest("isDemoTradingTest");

    unitTest.assertTrue(
        isDemoTrading(2100219063)
    );

    accountTypeOverride();

    unitTest.assertFalse(
        isDemoTrading(2100219063)
    );

    accountTypeOverrideReset();

    unitTest.assertFalse(
        isDemoTrading(2100175255)
    );

    unitTest.assertFalse(
        isDemoTrading(123)
    );
}
