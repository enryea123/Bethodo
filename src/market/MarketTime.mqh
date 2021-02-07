#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "../util/Exception.mqh"

enum MonthNumber {
    JANUARY = 1,
    FEBRUARY = 2,
    MARCH = 3,
    APRIL = 4,
    MAY = 5,
    JUNE = 6,
    JULY = 7,
    AUGUST = 8,
    SEPTEMBER = 9,
    OCTOBER = 10,
    NOVEMBER = 11,
    DECEMBER = 12,
};


/**
 * This class contains time information related to the market, such as
 * market opening/closing, timezones, DTS corrections.
 */
class MarketTime {
    public:
        datetime timeItaly();
        datetime timeBroker();

        bool hasDateChanged(datetime);
        datetime timeAtMidnight(datetime);
        int timeShiftInHours(datetime, datetime);

    protected:
        datetime findDayOfWeekOccurrenceInMonth(int, int, int, int);
        int getDaylightSavingCorrectionCET(datetime);
        int getDaylightSavingCorrectionUSA(datetime);

    private:
        int getDaysInMonth(int, int);
        bool isLeapYear(int);
};

/**
 * Returns the time in Italy, by manually calculating the DST correction.
 */
datetime MarketTime::timeItaly() {
    return TimeGMT() + 3600 * (1 + getDaylightSavingCorrectionCET());
}

/**
 * Returns the time of the Broker, by manually calculating the DST US correction.
 */
datetime MarketTime::timeBroker() {
    const string broker = AccountCompany();

    for (int i = 0; i < ArraySize(ALLOWED_BROKERS); i++) {
        if (broker == ALLOWED_BROKERS[i]) {
            return TimeGMT() + 3600 * (2 + getDaylightSavingCorrectionUSA());
        }
    }

    return ThrowException(-1, __FUNCTION__, StringConcatenate("Error for broker:", broker));
}

bool MarketTime::hasDateChanged(datetime date) {
    const datetime newToday = timeAtMidnight(date);
    static datetime today;

    if (today != newToday) {
        today = newToday;
        return true;
    }

    return false;
}

/**
 * Returns the date without time information.
 */
datetime MarketTime::timeAtMidnight(datetime date) {
    return date - (date % (PERIOD_D1 * 60));
}

/**
 * Returns the time shift between two datetimes. It can also be negative.
 */
int MarketTime::timeShiftInHours(datetime date1, datetime date2) {
    return (int) MathRound((date1 - date2) / (double) 3600);
}

/**
 * Returns true if the daylight saving time correction is on in EU.
 */
int MarketTime::getDaylightSavingCorrectionCET(datetime date = NULL) {
    if (date == NULL) {
        date = TimeGMT();
    }

    const int year = TimeYear(date);

    // Changes at Midnight GMT rather than 01:00, but it doesn't matter
    const datetime lastSundayOfMarch = findDayOfWeekOccurrenceInMonth(year, MARCH, SUNDAY, -1);
    const datetime lastSundayOfOctober = findDayOfWeekOccurrenceInMonth(year, OCTOBER, SUNDAY, -1);

    if (date > lastSundayOfMarch && date < lastSundayOfOctober) {
        return 1;
    }

    return 0;
}

/**
 * Returns true if the daylight saving time correction is on in US.
 */
int MarketTime::getDaylightSavingCorrectionUSA(datetime date = NULL) {
    if (date == NULL) {
        date = TimeGMT();
    }

    const int year = TimeYear(date);

    // Changes at Midnight GMT rather than 01:00, but it doesn't matter
    const datetime secondSundayOfMarch = findDayOfWeekOccurrenceInMonth(year, MARCH, SUNDAY, 2);
    const datetime firstSundayOfNovember = findDayOfWeekOccurrenceInMonth(year, NOVEMBER, SUNDAY, 1);

    if (date > secondSundayOfMarch && date < firstSundayOfNovember) {
        return 1;
    }

    return 0;
}

/**
 * Allows to find the date of a certain occurrence of a day in a month, e.g. the third Monday of September 2021.
 * It also supports negative indexes, in case the last or penultimate occurrence are required.
 * The occurrence index 0 is the only unsupported one.
 */
datetime MarketTime::findDayOfWeekOccurrenceInMonth(int year, int month, int dayOfWeek, int occurrence) {
    const int daysInMonth = getDaysInMonth(year, month);

    if (daysInMonth < 0 || occurrence == 0 || MathAbs(TimeYear(TimeGMT()) - year) > FIND_DAY_MAX_YEARS_RANGE) {
        return ThrowException(-1, __FUNCTION__, StringConcatenate("Could not get days in month: ",
            month, " with occurrence: ", occurrence));
    }

    int startDay, endDay;

    if (occurrence > 0) {
        startDay = MathMin(1 + 7 * (occurrence - 1), daysInMonth - 7);
        endDay = MathMin(7 * occurrence, daysInMonth);
    } else if (occurrence < 0) {
        startDay = MathMax(1 + daysInMonth + 7 * occurrence, 1);
        endDay = MathMax(daysInMonth + 7 * (occurrence + 1), 7);
    } else {
        return ThrowException(-1, __FUNCTION__, StringConcatenate("Invalid occurrence: ", occurrence));
    }

    for (int day = startDay; day <= endDay; day++) {
        const datetime date = StringToTime(StringConcatenate(year, ".", month, ".", day));

        if (TimeDayOfWeek(date) == dayOfWeek) {
            return date;
        }
    }

    return ThrowException(-1, __FUNCTION__, "Could not calculate date");
}

/**
 * Contains information on the number of days for each month. It accounts for leap years.
 */
int MarketTime::getDaysInMonth(int year, int month) {
    if (month == JANUARY) {
        return 31;
    }
    if (month == FEBRUARY) {
        return isLeapYear(year) ? 29 : 28;
    }
    if (month == MARCH) {
        return 31;
    }
    if (month == APRIL) {
        return 30;
    }
    if (month == MAY) {
        return 31;
    }
    if (month == JUNE) {
        return 30;
    }
    if (month == JULY) {
        return 31;
    }
    if (month == AUGUST) {
        return 31;
    }
    if (month == SEPTEMBER) {
        return 30;
    }
    if (month == OCTOBER) {
        return 31;
    }
    if (month == NOVEMBER) {
        return 30;
    }
    if (month == DECEMBER) {
        return 31;
    }

    return ThrowException(-1, __FUNCTION__, StringConcatenate("Could not calculate days in month: ", month));
}

/**
 * Returns true if the given year is a leap year.
 */
bool MarketTime::isLeapYear(int year) {
    bool leapYearCondition = (year % 4 == 0) && (year % 100 != 0 || year % 400 == 0);
    return leapYearCondition;
}
