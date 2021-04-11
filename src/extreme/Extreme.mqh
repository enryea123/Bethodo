#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "../util/Price.mqh"


/**
 * This class calculates all the extremes.
 */
class Extreme {
    public:
        void calculateAllExtremes(int & [], Discriminator, int);
        void calculateValidExtremes(int & [], Discriminator, int);
};

/**
 * Calculates all the extremes on the graph.
 */
void Extreme::calculateAllExtremes(int & allExtremes[], Discriminator discriminator, int extremesMinDistance) {
    ArrayFree(allExtremes);
    ArrayResize(allExtremes, EXTREMES_MAX_CANDLES);

    int numberOfExtremes = 0;

    for (int i = 1; i < EXTREMES_MAX_CANDLES; i++) {
        bool isBeatingNeighbours = true;

        for (int j = -extremesMinDistance; j < extremesMinDistance + 1; j++) {
            if (i + j < 0 || i < 0) {
                continue;
            }

            if ((iExtreme(discriminator, i) > iExtreme(discriminator, i + j) && discriminator == Min) ||
                (iExtreme(discriminator, i) < iExtreme(discriminator, i + j) && discriminator == Max)) {
                isBeatingNeighbours = false;
                break;
            }
        }

        if (isBeatingNeighbours) {
            allExtremes[numberOfExtremes] = i;
            numberOfExtremes++;
            i += extremesMinDistance;
        }
    }

    ArrayResize(allExtremes, numberOfExtremes);
}

/**
 * Calculates the valid extremes on the graph.
 */
void Extreme::calculateValidExtremes(int & validExtremes[], Discriminator discriminator, int extremesMinDistance) {
    ArrayFree(validExtremes);
    ArrayResize(validExtremes, EXTREMES_MAX_CANDLES);

    int allExtremes[];
    calculateAllExtremes(allExtremes, discriminator, extremesMinDistance);

    int numberOfValidExtremes = 0;
    int lastFoundValidExtremeIndex = LEVELS_TRANSPARENT_CANDLES;

    for (int i = 0; i < ArraySize(allExtremes); i++) {
        bool isValidExtreme = true;
        const int indexI = allExtremes[i];

        for (int j = lastFoundValidExtremeIndex; j < indexI; j++) {
            if ((discriminator == Min && iExtreme(discriminator, indexI) >
                iExtreme(discriminator, j) + LEVELS_TOLERANCE_PIPS * Pip()) ||
                (discriminator == Max && iExtreme(discriminator, indexI) <
                iExtreme(discriminator, j) - LEVELS_TOLERANCE_PIPS * Pip())) {
                isValidExtreme = false;
                break;
            }
        }

        if (isValidExtreme) {
            validExtremes[numberOfValidExtremes] = indexI;
            lastFoundValidExtremeIndex = indexI;
            numberOfValidExtremes++;
        }
    }

    ArrayResize(validExtremes, numberOfValidExtremes);
}
