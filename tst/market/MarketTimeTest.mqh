#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../UnitTest.mqh"
#include "../../src/market/MarketTime.mqh"


class MarketTimeTest: public MarketTime {
    public:
        void hasDateChangedTest();
        void findDayOfWeekOccurrenceInMonthTest();
        void getDaylightSavingCorrectionsTest();
        void timeAtMidnightTest();
        void timeShiftInHoursTest();
};

void MarketTimeTest::hasDateChangedTest() {
    UnitTest unitTest("hasDateChangedTest");

    unitTest.assertTrue(
        hasDateChanged((datetime) "2020-04-05 12:00")
    );

    unitTest.assertFalse(
        hasDateChanged((datetime) "2020-04-05 12:30")
    );

    unitTest.assertTrue(
        hasDateChanged((datetime) "2020-04-06")
    );

    unitTest.assertFalse(
        hasDateChanged((datetime) "2020-04-06 05:00")
    );
}

void MarketTimeTest::findDayOfWeekOccurrenceInMonthTest() {
    UnitTest unitTest("findDayOfWeekOccurrenceInMonthTest");

    unitTest.assertEquals(
        (datetime) "2020-04-05",
        findDayOfWeekOccurrenceInMonth(2020, APRIL, SUNDAY, 1)
    );

    unitTest.assertEquals(
        (datetime) "2019-06-04",
        findDayOfWeekOccurrenceInMonth(2019, JUNE, TUESDAY, 1)
    );

    unitTest.assertEquals(
        (datetime) "2019-06-04",
        findDayOfWeekOccurrenceInMonth(2019, JUNE, TUESDAY, -4)
    );

    unitTest.assertEquals(
        (datetime) "2019-06-04",
        findDayOfWeekOccurrenceInMonth(2019, JUNE, TUESDAY, -16)
    );

    unitTest.assertEquals(
        (datetime) "2021-03-29",
        findDayOfWeekOccurrenceInMonth(2021, MARCH, MONDAY, -1)
    );

    unitTest.assertEquals(
        (datetime) "2020-02-29", // testing leap year
        findDayOfWeekOccurrenceInMonth(2020, FEBRUARY, SATURDAY, -1)
    );

    unitTest.assertEquals(
        (datetime) "2022-02-15", // testing non leap year
        findDayOfWeekOccurrenceInMonth(2022, FEBRUARY, TUESDAY, -2)
    );

    unitTest.assertEquals(
        (datetime) -1,
        findDayOfWeekOccurrenceInMonth(2020, 27, MONDAY, 1)
    );

    unitTest.assertEquals(
        (datetime) -1,
        findDayOfWeekOccurrenceInMonth(2020, 0, MONDAY, 1)
    );

    unitTest.assertEquals(
        (datetime) -1,
        findDayOfWeekOccurrenceInMonth(2021, MAY, MONDAY, 0)
    );

    unitTest.assertEquals(
        (datetime) -1,
        findDayOfWeekOccurrenceInMonth(2021, MAY, 19, 1)
    );

    unitTest.assertEquals(
        (datetime) -1,
        findDayOfWeekOccurrenceInMonth(1, MAY, WEDNESDAY, 2)
    );

    unitTest.assertEquals(
        (datetime) -1,
        findDayOfWeekOccurrenceInMonth(3000, MAY, WEDNESDAY, 2)
    );
}

void MarketTimeTest::getDaylightSavingCorrectionsTest() {
    UnitTest unitTest("getDaylightSavingCorrectionsTest");

    unitTest.assertEquals(
        0,
        getDaylightSavingCorrectionCET((datetime) "2020-03-28")
    );

    unitTest.assertEquals(
        1,
        getDaylightSavingCorrectionCET((datetime) "2020-03-30")
    );

    unitTest.assertEquals(
        1,
        getDaylightSavingCorrectionCET((datetime) "2020-10-24")
    );

    unitTest.assertEquals(
        0,
        getDaylightSavingCorrectionCET((datetime) "2020-10-26")
    );

    unitTest.assertEquals(
        0,
        getDaylightSavingCorrectionUSA((datetime) "2021-03-13")
    );

    unitTest.assertEquals(
        1,
        getDaylightSavingCorrectionUSA((datetime) "2021-03-15")
    );

    unitTest.assertEquals(
        1,
        getDaylightSavingCorrectionUSA((datetime) "2021-11-6")
    );

    unitTest.assertEquals(
        0,
        getDaylightSavingCorrectionUSA((datetime) "2021-11-8")
    );

    unitTest.assertEquals(
        1,
        getDaylightSavingCorrectionCET((datetime) "2018-06-30")
    );

    unitTest.assertEquals(
        0,
        getDaylightSavingCorrectionUSA((datetime) "2022-12-30")
    );
}

void MarketTimeTest::timeAtMidnightTest() {
    UnitTest unitTest("timeAtMidnightTest");

    unitTest.assertEquals(
        (datetime) "2021-06-30",
        timeAtMidnight((datetime) "2021-06-30 18:45:01")
    );
}
void MarketTimeTest::timeShiftInHoursTest() {
    UnitTest unitTest("timeShiftInHoursTest");

    unitTest.assertEquals(
        0,
        timeShiftInHours((datetime) "2018-06-30 12:00", (datetime) "2018-06-30 12:02:01")
    );

    unitTest.assertEquals(
        2,
        timeShiftInHours((datetime) "2018-06-30 12:02", (datetime) "2018-06-30 10:00:14")
    );

    unitTest.assertEquals(
        -3,
        timeShiftInHours((datetime) "2018-06-30 14:02", (datetime) "2018-06-30 16:56:14")
    );

    unitTest.assertEquals(
        24,
        timeShiftInHours((datetime) "2018-06-30 09:00", (datetime) "2018-06-29 09:00")
    );
}
