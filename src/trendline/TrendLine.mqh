#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "../util/Exception.mqh"
#include "../util/Price.mqh"
#include "../util/Util.mqh"


/**
 * This class allows to determine the properties of a trendLine.
 */
class TrendLine {
    public:
        bool areTrendLineSetupsGood(int, int, Discriminator);
        bool isExistingTrendLineBad(string, Discriminator);
        bool isBadTrendLineFromName(string);
        bool isGoodTrendLineFromName(string, int);

        int getTrendLineMaxIndex(string);
        int getTrendLineMinIndex(string);
        double getTrendLineSlope(string);
        Discriminator getTrendLineDiscriminator(string);

        string buildTrendLineName(int, int, int, Discriminator);
        string buildBadTrendLineName(int, int, int, Discriminator);

    private:
        int getTrendLineIndex(string, string);
        double getMaxTrendLineSlope(double);
        double getMinTrendLineSlope(double);
};

/**
 * Checks if the setups of a trendLine are good, before it has been created.
 * It checks the indexes, length, balance, slope, steepness.
 */
bool TrendLine::areTrendLineSetupsGood(int indexI, int indexJ, Discriminator discriminator) {
    if (indexI < indexJ) {
        return ThrowException(false, __FUNCTION__, "indexI < indexJ");
    }

    if (indexI < 1 || indexJ < 1) {
        return ThrowException(false, __FUNCTION__, "indexI < 1 || indexJ < 1");
    }

    if (indexI < TRENDLINE_MIN_CANDLES_LENGTH && indexJ < TRENDLINE_MIN_CANDLES_LENGTH) {
        return false;
    }

    if (MathAbs(indexI - indexJ) < TRENDLINE_MIN_EXTREMES_DISTANCE) {
        return false;
    }

    const double trendLineBalanceRatio = MathAbs(indexI - indexJ) / (double) indexI;

    if (trendLineBalanceRatio < 1 - TRENDLINE_BALANCE_RATIO_THRESHOLD) {
        return false;
    }

    const double trendLineSlope = (iExtreme(discriminator, indexJ)
        - iExtreme(discriminator, indexI)) / (indexI - indexJ);

    if (MathAbs(trendLineSlope) < getMinTrendLineSlope(trendLineSlope)) {
        return false;
    }

    return true;
}

/**
 * Checks if an already existing trendLine had bad setups.
 * The validations are in the order that gives optimal performance.
 */
bool TrendLine::isExistingTrendLineBad(string trendLineName, Discriminator discriminator) {
    const double trendLineSlope = getTrendLineSlope(trendLineName);

    if (MathAbs(trendLineSlope) < getMinTrendLineSlope(trendLineSlope) && !isBadTrendLineFromName(trendLineName)) {
        return true;
    }

    const int indexI = getTrendLineMaxIndex(trendLineName);
    const int indexJ = getTrendLineMinIndex(trendLineName);

    // Broken TrendLine
    for (int k = 0; k < indexI; k++) {
        if (ObjectGetValueByShift(trendLineName, k) - iExtreme(discriminator, k) >
            TRENDLINE_TOLERANCE_PIPS * PeriodFactor() * Pip() && discriminator == Min) {
            return true;
        }
        if (ObjectGetValueByShift(trendLineName, k) - iExtreme(discriminator, k) <
            -TRENDLINE_TOLERANCE_PIPS * PeriodFactor() * Pip() && discriminator == Max) {
            return true;
        }

        /*
        // Third contact point
        if (MathAbs(ObjectGetValueByShift(trendLineName, k) - iExtreme(discriminator, k)) <
            TRENDLINE_TOLERANCE_PIPS * PeriodFactor() * Pip() &&
            MathAbs(k - indexI) > TRENDLINE_MIN_EXTREMES_DISTANCE &&
            MathAbs(k - indexJ) > TRENDLINE_MIN_EXTREMES_DISTANCE) {
            hasThirdLeg = true;
        }
        */
    }

    /*
    if (!hasThirdLeg) {
        return true;
    }
    */

    return false;
}

/**
 * Returns true if the given name identifies a bad trendLine.
 */
bool TrendLine::isBadTrendLineFromName(string trendLineName) {
    if (StringContains(trendLineName, TRENDLINE_NAME_PREFIX) &&
        StringContains(trendLineName, TRENDLINE_BAD_NAME_SUFFIX)) {
        return true;
    }

    return false;
}

/**
 * Returns true if the given name identifies a good trendLine. In order to be good,
 * the minimum index of the trendLine needs to be far enough from the input timeIndex.
 */
bool TrendLine::isGoodTrendLineFromName(string trendLineName, int timeIndex = 0) {
    if (!StringContains(trendLineName, TRENDLINE_NAME_PREFIX) ||
        StringContains(trendLineName, TRENDLINE_BAD_NAME_SUFFIX)) {
        return false;
    }

    // Needed for orders set in the past
    if (getTrendLineMinIndex(trendLineName) <= timeIndex) {
        return false;
    }

    return true;
}

/**
 * Returns the value of the trendLine given inxed.
 */
int TrendLine::getTrendLineIndex(string trendLineName, string indexDisambiguator) {
    if (!StringContains(trendLineName, TRENDLINE_NAME_PREFIX)) {
        return -1;
    }

    if (indexDisambiguator != TRENDLINE_NAME_FIRST_INDEX_IDENTIFIER &&
        indexDisambiguator != TRENDLINE_NAME_SECOND_INDEX_IDENTIFIER) {
        return -1;
    }

    const int positionInName = (indexDisambiguator == TRENDLINE_NAME_FIRST_INDEX_IDENTIFIER) ? 1 : 2;

    string splittedTrendLineName[];
    StringSplit(trendLineName, StringGetCharacter(NAME_SEPARATOR, 0), splittedTrendLineName);

    if (ArraySize(splittedTrendLineName) <= positionInName) {
        return -1;
    }

    StringSplit(splittedTrendLineName[positionInName], StringGetCharacter(indexDisambiguator, 0),
        splittedTrendLineName);

    if (ArraySize(splittedTrendLineName) < 2) {
        return -1;
    }

    return StrToInteger(splittedTrendLineName[1]);
}

/**
 * Returns the value of the first index of the trendLine.
 */
int TrendLine::getTrendLineMaxIndex(string trendLineName) {
    return getTrendLineIndex(trendLineName, TRENDLINE_NAME_FIRST_INDEX_IDENTIFIER);
}

/**
 * Returns the value of the second index of the trendLine.
 */
int TrendLine::getTrendLineMinIndex(string trendLineName) {
    return getTrendLineIndex(trendLineName, TRENDLINE_NAME_SECOND_INDEX_IDENTIFIER);
}

/**
 * Returns the slope of the trendLine.
 */
double TrendLine::getTrendLineSlope(string trendLineName) {
    // The denominator of the derivative would be (2 - 1)
    return ObjectGetValueByShift(trendLineName, 1) - ObjectGetValueByShift(trendLineName, 2);
}

/**
 * Returns the maximum accepted slope for a trendLine to be good.
 */
double TrendLine::getMaxTrendLineSlope(double trendLineSlope) {
    const double maxVolatilityPercentage = trendLineSlope > 0 ?
        TRENDLINE_POSITIVE_SLOPE_VOLATILITY : TRENDLINE_NEGATIVE_SLOPE_VOLATILITY;
    return MathAbs(maxVolatilityPercentage * GetMarketVolatility());
}

/**
 * Returns the minimum accepted slope for a trendLine to be good.
 */
double TrendLine::getMinTrendLineSlope(double trendLineSlope) {
    return MathAbs(TRENDLINE_MIN_SLOPE_VOLATILITY * GetMarketVolatility());
}

/**
 * Returns the discriminator of the trendLine.
 */
Discriminator TrendLine::getTrendLineDiscriminator(string trendLineName) {
    if (StringContains(trendLineName, EnumToString(Max))) {
        return Max;
    }
    return Min;
}

/**
 * Builds the trendLine name.
 */
string TrendLine::buildTrendLineName(int indexI, int indexJ, int beam, Discriminator discriminator) {
    return StringConcatenate(TRENDLINE_NAME_PREFIX,
        NAME_SEPARATOR, TRENDLINE_NAME_FIRST_INDEX_IDENTIFIER, indexI,
        NAME_SEPARATOR, TRENDLINE_NAME_SECOND_INDEX_IDENTIFIER, indexJ,
        NAME_SEPARATOR, TRENDLINE_NAME_BEAM_IDENTIFIER, beam,
        NAME_SEPARATOR, EnumToString(discriminator));
}

/**
 * Builds the bad trendLine name.
 */
string TrendLine::buildBadTrendLineName(int indexI, int indexJ, int beam, Discriminator discriminator) {
    return StringConcatenate(buildTrendLineName(indexI, indexJ, beam, discriminator),
        NAME_SEPARATOR, TRENDLINE_BAD_NAME_SUFFIX);
}
