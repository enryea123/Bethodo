#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "../pattern/Candle.mqh"
#include "../trendline/TrendLine.mqh"


/**
 * This class contains drawing information for the channels.
 */
class ChannelsDraw {
    public:
        void drawChannels();
        bool isChannel(string);

        double getChannelSlope(string);
        Discriminator getChannelDiscriminator(string);
};

/**
 * Draws all the channels by filtering out the trendLines.
 */
void ChannelsDraw::drawChannels() {
    Candle candle;
    TrendLine trendLine;

    if (!FindPriceGap(CHANNEL_PRICE_GAP_CANDLES, CHANNEL_PRICE_GAP_PIPS)) {
        for (int i = ObjectsTotal() - 1; i >= 0; i--) {
            const string firstTrendLineName = ObjectName(i);
            const Discriminator firstTrendLineDiscriminator = trendLine.getTrendLineDiscriminator(firstTrendLineName);

            if (!trendLine.isGoodTrendLineFromName(firstTrendLineName)) {
                continue;
            }
            if (firstTrendLineDiscriminator == Min) {
                continue;
            }

            const double firstTrendLineSlope = trendLine.getTrendLineSlope(firstTrendLineName);

            for (int j = ObjectsTotal() - 1; j >= 0; j--) {
                const string secondTrendLineName = ObjectName(j);
                const Discriminator secondTrendLineDiscriminator =
                    trendLine.getTrendLineDiscriminator(secondTrendLineName);

                if (!trendLine.isGoodTrendLineFromName(secondTrendLineName)) {
                    continue;
                }
                if (firstTrendLineName == secondTrendLineName) {
                    continue;
                }
                if (firstTrendLineDiscriminator == secondTrendLineDiscriminator) {
                    continue;
                }

                const double trendLinesLengthRatio = trendLine.getTrendLineMaxIndex(secondTrendLineName)
                    / (double) trendLine.getTrendLineMaxIndex(firstTrendLineName);

                if (trendLinesLengthRatio < CHANNEL_BALANCE_RATIO ||
                    trendLinesLengthRatio > 1 / CHANNEL_BALANCE_RATIO) {
                    continue;
                }

                const double channelHeight = MathAbs(ObjectGetValueByShift(secondTrendLineName, 1)
                    - ObjectGetValueByShift(firstTrendLineName, 1));

                if (channelHeight > AverageTrueRange() * MAX_CHANNEL_HEIGHT_ATR * Pip() ||
                    channelHeight < AverageTrueRange() * MIN_CHANNEL_HEIGHT_ATR * Pip()) {
                    continue;
                }

                if (MathAbs(firstTrendLineSlope - trendLine.getTrendLineSlope(secondTrendLineName)) >
                    CHANNEL_PARALLEL_SLOPE_THREHSOLD * Pip()) {
                    continue;
                }

                const int firstTrendLineMinIndex = trendLine.getTrendLineMinIndex(firstTrendLineName);
                const int secondTrendLineMinIndex = trendLine.getTrendLineMinIndex(secondTrendLineName);
                const double maxWickSize = AverageTrueRange() * STOPLOSS_ATR_PERCENTAGE * Pip();

                if (firstTrendLineSlope > 0) {
                    if (candle.candleUpShadow(firstTrendLineMinIndex) > maxWickSize ||
                        firstTrendLineMinIndex < CHANNEL_MIN_OPPOSITE_CONTACT_POINT) {
                        continue;
                    }
                }
                if (firstTrendLineSlope < 0 && candle.candleDownShadow(secondTrendLineMinIndex) > maxWickSize) {
                    if (candle.candleDownShadow(secondTrendLineMinIndex) > maxWickSize ||
                        secondTrendLineMinIndex < CHANNEL_MIN_OPPOSITE_CONTACT_POINT) {
                        continue;
                    }
                }

                ObjectSet(firstTrendLineName, OBJPROP_COLOR, CHANNEL_COLOR);
                ObjectSet(secondTrendLineName, OBJPROP_COLOR, CHANNEL_COLOR);
                ObjectSet(firstTrendLineName, OBJPROP_WIDTH, CHANNEL_LINE_WIDTH);
                ObjectSet(secondTrendLineName, OBJPROP_WIDTH, CHANNEL_LINE_WIDTH);
            }
        }
    }

    if (!IS_DEBUG) {
        for (int i = ObjectsTotal() - 1; i >= 0; i--) {
            const string trendLineName = ObjectName(i);

            if (trendLine.isGoodTrendLineFromName(trendLineName) && !isChannel(trendLineName)) {
                ObjectDelete(trendLineName);
            }
        }
    }
}

/**
 * Draws all the channels by filtering out the trendLines.
 */
bool ChannelsDraw::isChannel(string channelName) {
    TrendLine trendLine;

    if (trendLine.isGoodTrendLineFromName(channelName) &&
        ObjectGet(channelName, OBJPROP_COLOR) == CHANNEL_COLOR &&
        ObjectGet(channelName, OBJPROP_WIDTH) == CHANNEL_LINE_WIDTH) {
        return true;
    }
    return false;
}

/**
 * Returns the slope of the channel.
 */
double ChannelsDraw::getChannelSlope(string channelName) {
    // The denominator of the derivative would be (2 - 1)
    return ObjectGetValueByShift(channelName, 1) - ObjectGetValueByShift(channelName, 2);
}

/**
 * Returns the discriminator of the channel.
 */
Discriminator ChannelsDraw::getChannelDiscriminator(string channelName) {
    if (StringContains(channelName, EnumToString(Max))) {
        return Max;
    }
    return Min;
}
