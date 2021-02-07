#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../UnitTest.mqh"
#include "../../src/market/Holiday.mqh"


class HolidayTest: public Holiday {
    public:
        void isMajorBankHolidayTest();
        void isMinorBankHolidayTest();
};

void HolidayTest::isMajorBankHolidayTest() {
    UnitTest unitTest("isMajorBankHolidayTest");

    unitTest.assertTrue(
        isMajorBankHoliday((datetime) "2020-01-01")
    );

    unitTest.assertFalse(
        isMajorBankHoliday((datetime) "2020-03-01 07.18.01")
    );

    // Pasquetta
    unitTest.assertTrue(
        isMajorBankHoliday((datetime) "2020-04-13")
    );

    // Not Pasquetta
    unitTest.assertFalse(
        isMajorBankHoliday((datetime) "2021-04-13")
    );

    // Not Pasquetta
    unitTest.assertFalse(
        isMajorBankHoliday((datetime) "2020-04-05")
    );

    // Pasquetta
    unitTest.assertTrue(
        isMajorBankHoliday((datetime) "2021-04-05")
    );

    // Ascension
    unitTest.assertTrue(
        isMajorBankHoliday((datetime) "2021-05-13")
    );

    // Ascension
    unitTest.assertTrue(
        isMajorBankHoliday((datetime) "2025-05-29")
    );

    // Pentecoste
    unitTest.assertTrue(
        isMajorBankHoliday((datetime) "2023-05-28")
    );

    // Pentecoste
    unitTest.assertTrue(
        isMajorBankHoliday((datetime) "2024-05-19")
    );

    // Columbus day
    unitTest.assertTrue(
        isMajorBankHoliday((datetime) "2022-10-10")
    );

    unitTest.assertTrue(
        isMajorBankHoliday((datetime) "2022-12-25 18:00")
    );

    unitTest.assertFalse(
        isMajorBankHoliday((datetime) "9999-01-01")
    );
}

void HolidayTest::isMinorBankHolidayTest() {
    UnitTest unitTest("isMinorBankHolidayTest");

    unitTest.assertFalse(
        isMinorBankHoliday((datetime) "2021-01-10")
    );

    unitTest.assertTrue(
        isMinorBankHoliday((datetime) "2024-06-02 08:08:00")
    );

    unitTest.assertTrue(
        isMinorBankHoliday((datetime) "2022-08-29")
    );
}
