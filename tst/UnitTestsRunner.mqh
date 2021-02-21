#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../Constants.mqh"
#include "extreme/ArrowStyleTest.mqh"
#include "market/HolidayTest.mqh"
#include "market/MarketTest.mqh"
#include "market/MarketTimeTest.mqh"
#include "news/NewsDrawTest.mqh"
#include "news/NewsParseTest.mqh"
#include "order/OrderTest.mqh"
#include "order/OrderFindTest.mqh"
#include "order/OrderCreateTest.mqh"
#include "order/OrderManageTest.mqh"
#include "order/OrderTrailTest.mqh"
#include "trendline/TrendLineTest.mqh"
#include "util/ArrayTest.mqh"
#include "util/PriceTest.mqh"
#include "util/UtilTest.mqh"


/**
 * This class allows to run all the unit tests.
 */
class UnitTestsRunner {
    public:
        void runAllUnitTests();
};

/**
 * Runs all the unit tests and prints the execution time.
 */
void UnitTestsRunner::runAllUnitTests() {
    const ulong startTime = GetTickCount();

    ArrayTest arrayTest;
    arrayTest.arrayTest();

    PriceTest priceTest;
    priceTest.priceTest();

    UtilTest utilTest;
    utilTest.utilTest();

    ArrowStyleTest arrowStyleTest;
    arrowStyleTest.drawExtremeArrowTest();

    HolidayTest holidayTest;
    holidayTest.isMajorBankHolidayTest();
    holidayTest.isMinorBankHolidayTest();

    MarketTest marketTest;
    marketTest.isMarketOpenedTest();
    marketTest.isAllowedAccountNumberTest();
    marketTest.isAllowedExecutionDateTest();
    marketTest.isAllowedPeriodTest();
    marketTest.isAllowedBrokerTest();
    marketTest.isAllowedSymbolTest();
    marketTest.isAllowedSymbolPeriodComboTest();
    marketTest.isDemoTradingTest();

    MarketTimeTest marketTimeTest;
    marketTimeTest.hasDateChangedTest();
    marketTimeTest.findDayOfWeekOccurrenceInMonthTest();
    marketTimeTest.getDaylightSavingCorrectionsTest();
    marketTimeTest.timeAtMidnightTest();
    marketTimeTest.timeShiftInHoursTest();

    NewsDrawTest newsDrawTest;
    newsDrawTest.isNewsTimeWindowTest();

    NewsParseTest newsParseTest;
    newsParseTest.readNewsFromCalendarTest();
    newsParseTest.parseDateTest();

    OrderCreateTest orderCreateTest;
    orderCreateTest.areThereRecentOrdersTest();
    orderCreateTest.areThereBetterOrdersTest();
    orderCreateTest.calculateOrderOpenPriceFromSetupsTest();
    orderCreateTest.calculateOrderLotsTest();
    orderCreateTest.getPercentRiskTest();

    OrderTest orderTest;
    orderTest.isBreakEvenTest();
    orderTest.getPeriodTest();
    orderTest.getStopLossPipsTest();
    orderTest.buildCommentTest();
    orderTest.getSizeFactorFromCommentTest();
    orderTest.isOpenTest();
    orderTest.isBuySellTest();
    orderTest.getDiscriminatorTest();

    OrderFindTest orderFindTest;
    orderFindTest.getOrdersListTest();
    orderFindTest.getFilteredOrdersListTest();

    OrderManageTest orderManageTest;
    orderManageTest.areThereOpenOrdersTest();
    orderManageTest.areThereOrdersThisSymbolThisPeriodTest();
    orderManageTest.findBestOrderTest();
    orderManageTest.deduplicateOrdersTest();
    orderManageTest.emergencySwitchOffTest();
    orderManageTest.lossLimiterTest();
    orderManageTest.deleteAllOrdersTest();
    orderManageTest.deletePendingOrdersTest();

    OrderTrailTest orderTrailTest;
    orderTrailTest.calculateBreakEvenStopLossTest();

    TrendLineTest trendLineTest;
    trendLineTest.isGoodTrendLineFromNameTest();
    trendLineTest.getTrendLineIndexesTest();
    trendLineTest.trendLineNameTest();
    trendLineTest.trendLineSetupsTest();

    UNIT_TESTS_COMPLETED = true;
    Print("All UnitTests run in ", GetTickCount() - startTime, " ms");
}
