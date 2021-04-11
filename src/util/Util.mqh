#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "Exception.mqh"


/**
 * Returns the magicNumber associated with the current period.
 */
int MagicNumber() {
    return (BASE_MAGIC_NUMBER + Period());
}

/**
 * Returns the pip size in digits for the specified symbol.
 */
double Pip(string symbol = NULL) {
    if (symbol == NULL) {
        symbol = Symbol();
    }
    if (!SymbolExists(symbol)) {
        return ThrowException(-1, __FUNCTION__, "Unexistent symbol for Pip");
    }

    return 10 * MarketInfo(symbol, MODE_TICKSIZE);
}

/**
 * Returns the period multiplication factor for the specified period.
 */
int PeriodFactor(int period = NULL) {
    if (period == NULL) {
        period = Period();
    }

    if (period == PERIOD_H4) {
        return 2;
    }

    return 1;
}

/**
 * Returns the market value for the specified symbol, by averaging ask and bid.
 */
double GetPrice(string symbol = NULL) {
    return (MarketInfo(symbol, MODE_ASK) + MarketInfo(symbol, MODE_BID)) / 2;
}

/**
 * Returns true if the given string contains the given substring.
 */
bool StringContains(string inputString, string inputSubString) {
    if (StringFind(inputString, inputSubString) != -1) {
        return true;
    }

    return false;
}

/**
 * Returns true if the given symbol exists.
 */
bool SymbolExists(string symbol) {
    ResetLastError();
    MarketInfo(symbol, MODE_TICKSIZE);

    if (GetLastError() != ERR_UNKNOWN_SYMBOL) {
        return true;
    }

    return ThrowException(false, __FUNCTION__, StringConcatenate("Unexistent symbol: ", symbol));
}

/**
 * Returns the symbol family of a symbol. If no family is specified explicitly
 * in the priority list, it returns the first 3 letters of the symbol.
 */
string SymbolFamily(string symbol = NULL) {
    if (symbol == NULL) {
        symbol = Symbol();
    }

    if (!SymbolExists(symbol)) {
        return ThrowException(symbol, __FUNCTION__, "Unexistent symbol for SymbolFamily");;
    }

    if (StringContains(symbol, "USD")) {
        return "USD";
    } else if (StringContains(symbol, "EUR")) {
        return "EUR";
    } else if (StringContains(symbol, "GBP")) {
        return "GBP";
    } else if (StringContains(symbol, "AUD")) {
        return "AUD";
    } else if (StringContains(symbol, "NZD")) {
        return "NZD";
    } else {
        return StringSubstr(symbol, 0, 3);
    }
}

/**
 * Returns a date by stripping out the time.
 */
datetime GetDate(datetime date) {
    // Same as MarketTime::timeAtMidnight(datetime)
    return CalculateDateByTimePeriod(date, PERIOD_D1);
}

/**
 * Returns the date in which the given period last candle has started.
 */
datetime CalculateDateByTimePeriod(datetime date, int period) {
    if (period <= PERIOD_D1) {
        return date - date % (PERIOD_D1 * 60);
    }

    if (period == PERIOD_W1) {
        datetime time = date - date % (PERIOD_D1 * 60);

        while (TimeDayOfWeek(time) != SUNDAY) {
            time -= PERIOD_D1 * 60;
        }
        return time;
    }

    if (period == PERIOD_MN1) {
        int year = TimeYear(date);
        int month = TimeMonth(date);

        return StringToTime(StringConcatenate(year, ".", month, ".01"));
    }

    return ThrowException(-1, __FUNCTION__, StringConcatenate("Unsupported period: ", period));
}
