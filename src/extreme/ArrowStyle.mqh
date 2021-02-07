#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "../util/Price.mqh"


/**
 * This class contains styling information for the arrows that represent extremes.
 */
class ArrowStyle {
    public:
        void drawExtremeArrow(int, Discriminator, bool);

    private:
        color getArrowColor(bool);
        int getArrowSize(bool);
        int getArrowObjectType(Discriminator);
        double getArrowAnchor(Discriminator);
        string buildArrowName(int, Discriminator, bool);
};

/**
 * Draws an extreme arrow and sets its properties.
 */
void ArrowStyle::drawExtremeArrow(int timeIndex, Discriminator discriminator, bool isValidExtreme) {
    string arrowName = buildArrowName(timeIndex, discriminator, isValidExtreme);

    ObjectCreate(
        arrowName,
        getArrowObjectType(discriminator),
        0,
        Time[timeIndex],
        iExtreme(discriminator, timeIndex)
    );

    ObjectSet(arrowName, OBJPROP_ANCHOR, getArrowAnchor(discriminator));
    ObjectSet(arrowName, OBJPROP_COLOR, getArrowColor(isValidExtreme));
    ObjectSet(arrowName, OBJPROP_WIDTH, getArrowSize(isValidExtreme));
}

/**
 * Returns the arrow color depending on the extreme being valid or not.
 */
color ArrowStyle::getArrowColor(bool isValidExtreme) {
    return isValidExtreme ? clrOrange : clrRed;
}

/**
 * Returns the arrow size depending on the extreme being valid or not.
 */
int ArrowStyle::getArrowSize(bool isValidExtreme) {
    return isValidExtreme ? 5 : 1;
}

/**
 * Returns the arrow anchor position depending on the type of extreme (Max, Min).
 */
double ArrowStyle::getArrowAnchor(Discriminator discriminator) {
    return (discriminator == Max) ? ANCHOR_BOTTOM : ANCHOR_TOP;
}

/**
 * Returns the arrow object to draw depending on the type of extreme (Max, Min).
 */
int ArrowStyle::getArrowObjectType(Discriminator discriminator) {
    return (discriminator == Max) ? OBJ_ARROW_DOWN : OBJ_ARROW_UP;
}

/**
 * Builds the arrow name.
 */
string ArrowStyle::buildArrowName(int timeIndex, Discriminator discriminator, bool isValidExtreme) {
    string arrowName = StringConcatenate(ARROW_NAME_PREFIX, NAME_SEPARATOR,
        timeIndex, NAME_SEPARATOR, EnumToString(discriminator));

    if (isValidExtreme) {
        arrowName = StringConcatenate(arrowName, NAME_SEPARATOR, VALID_ARROW_NAME_SUFFIX);
    }

    return arrowName;
}
