#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "Exception.mqh"
#include "Util.mqh"


enum CandleSeriesType {
    I_high,
    I_low,
    I_open,
    I_close,
    I_time
};

/**
 * Used to get iHigh and iLow from iCandle.
 */
double iExtreme(Discriminator discriminator, int timeIndex) {
    if (discriminator == Max) {
        return iCandle(I_high, timeIndex);
    }

    if (discriminator == Min) {
        return iCandle(I_low, timeIndex);
    }

    return ThrowException(-1, __FUNCTION__, "Could not get value");
}

/**
 * Used to get market information from candle series for this symbol and period.
 */
double iCandle(CandleSeriesType candleSeriesType, int timeIndex) {
    return iCandle(candleSeriesType, Symbol(), Period(), timeIndex);
}

/**
 * Used to get market information from candle series. Assumes DownloadHistory has been executed before.
 */
double iCandle(CandleSeriesType candleSeriesType, string symbol, int period, int timeIndex) {
    if (!SymbolExists(symbol)) {
        return ThrowException(-1, __FUNCTION__, "Unknown symbol");
    }

    if (timeIndex < 0) {
        if (candleSeriesType == I_time) {
            return (double) TimeCurrent();
        }
        return ThrowException(-1, __FUNCTION__, "timeIndex < 0");
    }

    ResetLastError();
    double value = 0;

    if (candleSeriesType == I_high) {
        value = iHigh(symbol, period, timeIndex);
    } else if (candleSeriesType == I_low) {
        value = iLow(symbol, period, timeIndex);
    } else if (candleSeriesType == I_open) {
        value = iOpen(symbol, period, timeIndex);
    } else if (candleSeriesType == I_close) {
        value = iClose(symbol, period, timeIndex);
    } else if (candleSeriesType == I_time) {
        value = (double) iTime(symbol, period, timeIndex);
    } else {
        return ThrowException(-1, __FUNCTION__, StringConcatenate("Unsupported candleSeriesType: ", candleSeriesType));
    }

    const int lastError = GetLastError();

    if ((lastError == 0 || lastError == ERR_HISTORY_WILL_UPDATED) && value != 0) {
        return value;
    }

    return ThrowException(value, __FUNCTION__, StringConcatenate("Error ", lastError,
        " for candleSeriesType: ", EnumToString(candleSeriesType), ", value: ", value));
}

/**
 * Returns true if a price gap of the given pips is detected in the given range.
 */
bool FindPriceGap(int candles, double maxGap) {
    for (int i = 0; i < candles; i++) {
        const double gap = MathAbs(iCandle(I_close, i + 1) - iCandle(I_open, i)) / Pip();

        if (gap > maxGap) {
            PRICE_GAP_TIMESTAMP = PrintTimer(PRICE_GAP_TIMESTAMP,
                StringConcatenate("Found price gap of ", gap, " pips"));

            return true;
        }
    }
    return false;
}

/**
 * Returns the market spread for the specified symbol.
 * If a high spread is detected, it caches it for 5 minutes.
 */
double GetSpread(string symbol = NULL) {
    const datetime thisTime = (datetime) iCandle(I_time, Symbol(), PERIOD_M5, 0);

    static string cachedSymbol;
    static datetime timeStamp;
    static double spread;

    if (spread > SPREAD_PIPS_CLOSE_MARKET && symbol == cachedSymbol && timeStamp == thisTime && UNIT_TESTS_COMPLETED) {
        return spread;
    }

    cachedSymbol = symbol;
    timeStamp = thisTime;
    spread = MarketInfo(symbol, MODE_SPREAD) / 10;

    return spread;
}

/**
 * Downloads history data for all the periods enabled on the bot.
 * It retries a few times if needed, and waits between attempts.
 */
bool DownloadHistory() {
    const string symbol = Symbol();

    const int maxAttempts = 20;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
        int dateError = 0;
        int totalError = 0;
        ResetLastError();

        for (int i = 0; i < ArraySize(HISTORY_DOWNLOAD_PERIODS); i++) {
            int period = HISTORY_DOWNLOAD_PERIODS[i];

            // This is to make sure that more than 1 candle is downloaded
            iTime(symbol, period, 50);

            const datetime time = iTime(symbol, period, 0);

            if (GetLastError() != 0) {
                totalError++;
            }

            // Give a date error only for long periods
            const datetime expectedTime = CalculateDateByTimePeriod(TimeCurrent(), period);
            if (period > PERIOD_H4 && GetDate(time) != GetDate(expectedTime) && GetDate(time) != 0) {
                dateError++;
            }
        }

        if (dateError != 0) {
            Print("Date error during history data download");
            return false;
        }

        if (totalError == 0) {
            return true;
        } else if (attempt != maxAttempts - 1) {
            Print("Downloading missing history data, attempt: ", attempt + 1);
            Sleep(500);
        }
    }

    return ThrowException(false, __FUNCTION__, StringConcatenate(
        "Could not download history data, error:", GetLastError()));
}

/**
 * Calculates the market volatility at the trendLines zoom.
 */
double GetMarketVolatility() {
    static double volatility;

    if (VOLATILITY_TIMESTAMP != Time[0] || volatility == 0) {
        double marketMax = -10000, marketMin = 10000;

        for (int i = 0; i < CANDLES_VISIBLE_IN_GRAPH_3X; i++) {
            marketMax = MathMax(marketMax, iExtreme(Max, i));
            marketMin = MathMin(marketMin, iExtreme(Min, i));
        }

        volatility = MathAbs(marketMax - marketMin);
        VOLATILITY_TIMESTAMP = Time[0];
    }

    return volatility;
}

/**
 * Calculates the Average True Range for this symbol and period.
 */
double AverageTrueRange() {
    const datetime thisTime = (datetime) iCandle(I_time, Symbol(), PERIOD_D1, 0);

    static datetime timeStamp;
    static double averageTrueRange;

    if (timeStamp == thisTime && UNIT_TESTS_COMPLETED) {
        return averageTrueRange;
    }

    timeStamp = thisTime;
    averageTrueRange = iATR(Symbol(), Period(), ATR_AVERAGE_CANDLES, 0) / Pip();

    return averageTrueRange;
}
