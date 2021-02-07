#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "../trendline/trendLine.mqh"


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
    TrendLine trendLine;

    for (int i = ObjectsTotal() - 1; i >= 0; i--) {
        const string firstTrendLineName = ObjectName(i);

        if (!trendLine.isGoodTrendLineFromName(firstTrendLineName)) {
            continue;
        }
        if (trendLine.getTrendLineDiscriminator(firstTrendLineName) == Min) {
            continue;
        }

        const double firstTrendLineSlope = trendLine.getTrendLineSlope(firstTrendLineName);

        for (int j = ObjectsTotal() - 1; j >= 0; j--) {
            const string secondTrendLineName = ObjectName(j);

            if (!trendLine.isGoodTrendLineFromName(secondTrendLineName)) {
                continue;
            }
            if (firstTrendLineName == secondTrendLineName) {
                continue;
            }
            if (trendLine.getTrendLineDiscriminator(firstTrendLineName) ==
                trendLine.getTrendLineDiscriminator(secondTrendLineName)) {
                continue;
            }

            const double trendLinesLengthRatio = trendLine.getTrendLineMaxIndex(secondTrendLineName)
                / (double) trendLine.getTrendLineMaxIndex(firstTrendLineName);

            if (trendLinesLengthRatio < CHANNEL_BALANCE_RATIO || trendLinesLengthRatio > 1 / CHANNEL_BALANCE_RATIO) {
                continue;
            }

            const double channelHeight = MathAbs(ObjectGetValueByShift(secondTrendLineName, 1)
                - ObjectGetValueByShift(firstTrendLineName, 1));

            if (channelHeight > MAX_CHANNEL_HEIGHT * Pip() || channelHeight < MIN_CHANNEL_HEIGHT * Pip()) {
                continue;
            }

            if (MathAbs(firstTrendLineSlope - trendLine.getTrendLineSlope(secondTrendLineName)) <
                CHANNEL_PARALLEL_SLOPE_THREHSOLD * Pip()) {
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
