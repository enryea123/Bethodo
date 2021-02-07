#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "TrendLine.mqh"


/**
 * This class contains drawing informaiton for the trendLines.
 */
class TrendLinesDraw {
    public:
        void drawTrendLines(int & [], int & []);

    private:
        TrendLine trendLine_;

        void drawSingleTrendLine(string, int, int, int, Discriminator);
        void drawDiscriminatedTrendLines(int & [], Discriminator);
};

/**
 * Draws all the trendLines and extremes creating them.
 */
void TrendLinesDraw::drawTrendLines(int & maximums[], int & minimums[]) {
    drawDiscriminatedTrendLines(maximums, Max);
    drawDiscriminatedTrendLines(minimums, Min);
}

/**
 * Draws all the trendLines, discriminated by sign.
 */
void TrendLinesDraw::drawDiscriminatedTrendLines(int & indexes[], Discriminator discriminator) {
    for (int i = 0; i < ArraySize(indexes) - 1; i++) {
        for (int j = i + 1; j < ArraySize(indexes); j++) {
            for (int beam = -TRENDLINE_BEAMS; beam <= TRENDLINE_BEAMS; beam++) {

                // The indexes are passed in reverse order, so they are switched here
                const int indexI = indexes[j];
                const int indexJ = indexes[i];

                if (trendLine_.areTrendLineSetupsGood(indexI, indexJ, discriminator)) {
                    const string trendLineName = trendLine_.buildTrendLineName(
                        indexI, indexJ, beam, discriminator);

                    drawSingleTrendLine(trendLineName, indexI, indexJ, beam, discriminator);
                }

                if (IS_DEBUG && !trendLine_.areTrendLineSetupsGood(indexI, indexJ, discriminator)) {
                    const string badTrendLineName = trendLine_.buildBadTrendLineName(
                        indexI, indexJ, beam, discriminator);

                    drawSingleTrendLine(badTrendLineName, indexI, indexJ, beam, discriminator);
                }
            }
        }
    }
}

/**
 * Draws a single trendLine and sets its properties.
 */
void TrendLinesDraw::drawSingleTrendLine(string trendLineName, int indexI, int indexJ,
                                         int beam, Discriminator discriminator) {

    const double beamFactor = (TRENDLINE_BEAMS != 0) ? (beam / (double) TRENDLINE_BEAMS) : 0;

    ObjectCreate(
        trendLineName,
        OBJ_TREND,
        0,
        Time[indexI],
        iExtreme(discriminator, indexI) + TRENDLINE_TOLERANCE_PIPS * Pip() * beamFactor,
        Time[indexJ],
        iExtreme(discriminator, indexJ) - TRENDLINE_TOLERANCE_PIPS * Pip() * beamFactor
    );

    if (trendLine_.isExistingTrendLineBad(trendLineName, discriminator)) {
        ObjectDelete(trendLineName);
        return;
    }

    const int trendLineWidth = !trendLine_.isBadTrendLineFromName(trendLineName) ?
        TRENDLINE_WIDTH : BAD_TRENDLINE_WIDTH;
    const color trendLineColor = !trendLine_.isBadTrendLineFromName(trendLineName) ?
        TRENDLINE_COLOR : BAD_TRENDLINE_COLOR;

    ObjectSet(trendLineName, OBJPROP_WIDTH, trendLineWidth);
    ObjectSet(trendLineName, OBJPROP_COLOR, trendLineColor);
    ObjectSet(trendLineName, OBJPROP_BACK, true);
}
