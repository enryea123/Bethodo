#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "../news/NewsDraw.mqh"
#include "../util/Exception.mqh"
#include "../util/Util.mqh"
#include "Holiday.mqh"
#include "MarketTime.mqh"


/**
 * This class allows to run validations on the market conditions, to determine the openness status,
 * and to run other checks to decide whether the bot should be removed.
 */
class Market {
    public:
        Market();

        bool isMarketOpened(datetime);
        bool isEndOfWeek(datetime);
        bool isMarketOpenTime(datetime);
        bool marketConditionsValidation();

    protected:
        bool isAllowedAccountNumber(int);
        bool isAllowedExecutionDate(datetime);
        bool isAllowedPeriod(int);
        bool isAllowedBroker(string);
        bool isAllowedSymbol(string);
        bool isAllowedSymbolPeriodCombo(string, int);
        bool isDemoTrading(int);

        void accountTypeOverride();
        void accountTypeOverrideReset();

    private:
        MarketTime marketTime_;
        bool forceIsLiveAccountForTesting_;
};

Market::Market():
    forceIsLiveAccountForTesting_(false) {
}

/**
 * Checks if the market is opened in the default timezone.
 * It also closes the market in case the spread is too high.
 */
bool Market::isMarketOpened(datetime date = NULL) {
    if (date == NULL) {
        date = marketTime_.timeItaly();
    }

    if (isEndOfWeek(date)) {
        return false;
    }

    if (!isMarketOpenTime(date)) {
        return false;
    }

    Holiday holiday;
    if (holiday.isMajorBankHoliday(date)) {
        return false;
    }

    const double spread = GetSpread();
    if (spread > SPREAD_PIPS_CLOSE_MARKET) {
        SPREAD_TIMESTAMP = PrintTimer(SPREAD_TIMESTAMP, StringConcatenate("Market closed for spread: ", spread));
        return false;
    }

    NewsDraw newsDraw;
    if (newsDraw.isNewsTimeWindow(date)) {
        NEWS_TIMESTAMP = PrintTimer(NEWS_TIMESTAMP, "Market closed for news");
        return false;
    }

    return true;
}

/**
 * Checks if it is the end of the week in the default timezone.
 */
bool Market::isEndOfWeek(datetime date = NULL) {
    if (date == NULL) {
        date = marketTime_.timeItaly();
    }

    const int hour = TimeHour(date);
    const int dayOfWeek = TimeDayOfWeek(date);

    if (dayOfWeek > MARKET_WEEK_CLOSE_DAY || (dayOfWeek == MARKET_WEEK_CLOSE_DAY && hour >= MARKET_WEEK_CLOSE_HOUR)) {
        return true;
    }

    return false;
}

/**
 * Checks if it is the market open time window.
 */
bool Market::isMarketOpenTime(datetime date = NULL) {
    if (date == NULL) {
        date = marketTime_.timeItaly();
    }

    const int hour = TimeHour(date);
    const int minute = TimeMinute(date);

    if ((hour >= MARKET_OPEN_HOUR_1 &&
        (hour < MARKET_CLOSE_HOUR_1 || (hour == MARKET_CLOSE_HOUR_1 && minute < MARKET_CLOSE_MINUTE))) ||
        (hour >= MARKET_OPEN_HOUR_2 &&
        (hour < MARKET_CLOSE_HOUR_2 || (hour == MARKET_CLOSE_HOUR_2 && minute < MARKET_CLOSE_MINUTE)))) {
        return true;
    }

    return false;
}

/**
 * Checks all the market conditions such as AccountNumber, Date, Period,
 * and if there is internet connection it removes the bot.
 */
bool Market::marketConditionsValidation() {
    if (isAllowedAccountNumber() && isAllowedExecutionDate() && isAllowedPeriod() &&
        isAllowedBroker() && isAllowedSymbol() && isAllowedSymbolPeriodCombo()) {

        // This doesn't catch an incorrect clock, only a different timezone
        if (MathAbs(marketTime_.timeItaly() - TimeLocal()) > INCORRECT_CLOCK_ERROR_SECONDS) {
            WRONG_CLOCK_TIMESTAMP = AlertTimer(WRONG_CLOCK_TIMESTAMP,
                "The computer clock is not on the CET timezone, untested scenario");
        }

        return true;
    }

    if (IsConnected() || !UNIT_TESTS_COMPLETED) {
        ThrowFatalException(false, __FUNCTION__, "Market conditions validation failed");
    }

    return false;
}

/**
 * Check if the current account number is allowed to run the bot.
 */
bool Market::isAllowedAccountNumber(int accountNumber = NULL) {
    if (accountNumber == NULL) {
        accountNumber = AccountNumber();
    }

    for (int i = 0; i < ArraySize(ALLOWED_DEMO_ACCOUNT_NUMBERS); i++) {
        if (accountNumber == ALLOWED_DEMO_ACCOUNT_NUMBERS[i]) {
            return true;
        }
    }

    for (int j = 0; j < ArraySize(ALLOWED_LIVE_ACCOUNT_NUMBERS); j++) {
        if (accountNumber == ALLOWED_LIVE_ACCOUNT_NUMBERS[j]) {
            return true;
        }
    }

    return ThrowException(false, __FUNCTION__, StringConcatenate("Unauthorized accountNumber: ", accountNumber));
}

/**
 * Check if the bot has expired and it's no more allowed to run.
 */
bool Market::isAllowedExecutionDate(datetime date = NULL) {
    if (date == NULL) {
        date = TimeGMT();
    }

    if (date < BOT_EXPIRATION_DATE) {
        return true;
    }

    return ThrowException(false, __FUNCTION__, StringConcatenate("Unauthorized execution date: ", date));
}

/**
 * Check if the current period is supported to run the bot.
 */
bool Market::isAllowedPeriod(int period = NULL) {
    if (period == NULL) {
        period = Period();
    }

    for (int i = 0; i < ArraySize(ALLOWED_PERIODS); i++) {
        if (period == ALLOWED_PERIODS[i]) {
            return true;
        }
    }

    return ThrowException(false, __FUNCTION__, StringConcatenate("Unauthorized period: ", period));
}

/**
 * Check if the current symbol is supported to run the bot.
 */
bool Market::isAllowedSymbol(string symbol = NULL) {
    if (symbol == NULL) {
        symbol = Symbol();
    }

    if (isDemoTrading() && SymbolExists(symbol)) {
        return true;
    }

    for (int i = 0; i < ArraySize(ALLOWED_SYMBOLS); i++) {
        if (symbol == ALLOWED_SYMBOLS[i]) {
            return true;
        }
    }

    return ThrowException(false, __FUNCTION__, StringConcatenate("Unauthorized symbol: ", symbol));
}

/**
 * Check if the current broker is supported to run the bot. This is because
 * different brokers with different digits and options haven't been tested yet.
 */
bool Market::isAllowedBroker(string broker = NULL) {
    if (broker == NULL) {
        broker = AccountCompany();
    }

    if (isDemoTrading()) {
        return true;
    }

    for (int i = 0; i < ArraySize(ALLOWED_BROKERS); i++) {
        if (broker == ALLOWED_BROKERS[i]) {
            return true;
        }
    }

    return ThrowException(false, __FUNCTION__, StringConcatenate("Unauthorized broker: ", broker));
}

/**
 * Check if the current period/symbol combo is supported to run the bot.
 */
bool Market::isAllowedSymbolPeriodCombo(string symbol = NULL, int period = NULL) {
    if (symbol == NULL) {
        symbol = Symbol();
    }
    if (period == NULL) {
        period = Period();
    }

    if (isDemoTrading()) {
        return true;
    }

    for (int i = 0; i < RESTRICTED_SYMBOLS.size(); i++) {
        if (RESTRICTED_SYMBOLS.getKeys(i) == symbol && RESTRICTED_SYMBOLS.getValues(i) != period) {
            return ThrowException(false, __FUNCTION__, StringConcatenate("Unauthorized symbol ",
                symbol, " and period ", period, " combination"));
        }
    }

    return true;
}

/**
 * Check if the current account is demo or live. It allows to override the real value for unit tests.
 */
bool Market::isDemoTrading(int accountNumber = NULL) {
    if (accountNumber == NULL) {
        accountNumber = AccountNumber();
    }

    if (forceIsLiveAccountForTesting_) {
        return false;
    }

    for (int i = 0; i < ArraySize(ALLOWED_DEMO_ACCOUNT_NUMBERS); i++) {
        if (accountNumber == ALLOWED_DEMO_ACCOUNT_NUMBERS[i]) {
            return true;
        }
    }

    return false;
}

/**
 * Positively overrides the account type to live for unit tests.
 */
void Market::accountTypeOverride() {
    forceIsLiveAccountForTesting_ = true;
}

/**
 * Resets the account type override for unit tests.
 */
void Market::accountTypeOverrideReset() {
    forceIsLiveAccountForTesting_ = false;
}
