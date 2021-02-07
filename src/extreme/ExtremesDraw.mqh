#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "ArrowStyle.mqh"
#include "Extreme.mqh"


/**
 * This class handles the drawings of the extremes on the chart.
 */
class ExtremesDraw {
    public:
        void drawExtremes(int & [], int & []);

    private:
        void drawDiscriminatedExtremes(int & [], Discriminator);
};

/**
 * Draws the extremes on the graph.
 */
void ExtremesDraw::drawExtremes(int & maximums[], int & minimums[]) {
    drawDiscriminatedExtremes(maximums, Max);
    drawDiscriminatedExtremes(minimums, Min);
}

/**
 * Draws the discriminated extremes on the graph.
 */
void ExtremesDraw::drawDiscriminatedExtremes(int & allExtremes[], Discriminator discriminator) {
    ArrowStyle arrowStyle;
    Extreme extreme;

    extreme.calculateAllExtremes(allExtremes, discriminator, EXTREMES_MIN_DISTANCE);

    for (int i = 0; i < ArraySize(allExtremes); i++) {
        arrowStyle.drawExtremeArrow(allExtremes[i], discriminator, false);
    }
}
