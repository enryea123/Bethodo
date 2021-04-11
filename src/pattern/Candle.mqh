#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "../util/Exception.mqh"
#include "../util/Price.mqh"


/**
 * This class contains information on the basic types of candles that exist,
 * and provides some methods that return candles properties.
 */
class Candle {
    public:
        bool doji(int);
        bool slimDoji(int);
        bool downPinbar(int);
        bool upPinbar(int);
        bool bigBar(int);

        bool isCandleBull(int);
        bool isSupportCandle(int);

        double candleBody(int);
        double candleSize(int);
        double candleUpShadow(int);
        double candleDownShadow(int);
        double candleBodyMidPoint(int);
        double candleBodyMin(int);
        double candleBodyMax(int);
};

/**
 * Returns true if the given candle is a doji.
 */
bool Candle::doji(int timeIndex) {
    if (candleBody(timeIndex) < 6 * PeriodFactor() * Pip() &&
        candleUpShadow(timeIndex) < candleDownShadow(timeIndex) * 9 / 4 &&
        candleDownShadow(timeIndex) < candleUpShadow(timeIndex) * 9 / 4 &&
        candleDownShadow(timeIndex) + candleUpShadow(timeIndex) > candleBody(timeIndex) / 4) {
        return true;
    }

    return false;
}

/**
 * Returns true if the given candle is a slim doji.
 */
bool Candle::slimDoji(int timeIndex) {
    if (doji(timeIndex) && candleBody(timeIndex) < 4 * PeriodFactor() * Pip()) {
        return true;
    }

    return false;
}

/**
 * Returns true if the given candle is a down pinbar.
 */
bool Candle::downPinbar(int timeIndex) {
    if (candleDownShadow(timeIndex) > candleBody(timeIndex) * 4 / 3 &&
        candleUpShadow(timeIndex) < candleDownShadow(timeIndex) * 3 / 4 &&
        candleDownShadow(timeIndex) > (candleBody(timeIndex) + candleUpShadow(timeIndex)) * 3 / 4) {
        return true;
    }

    return false;
}

/**
 * Returns true if the given candle is an up pinbar.
 */
bool Candle::upPinbar(int timeIndex) {
    if (candleUpShadow(timeIndex) > candleBody(timeIndex) * 4 / 3 &&
        candleDownShadow(timeIndex) < candleUpShadow(timeIndex) * 3 / 4 &&
        candleUpShadow(timeIndex) > (candleBody(timeIndex) + candleDownShadow(timeIndex)) * 3 / 4) {
        return true;
    }

    return false;
}

/**
 * Returns true if the given candle is a big bar.
 */
bool Candle::bigBar(int timeIndex) {
    if (candleBody(timeIndex) > 6 * PeriodFactor() * Pip() &&
        candleDownShadow(timeIndex) < candleBody(timeIndex) * 3 / 4 &&
        candleUpShadow(timeIndex) < candleBody(timeIndex) * 3 / 4 &&
        candleDownShadow(timeIndex) + candleUpShadow(timeIndex) < candleBody(timeIndex) * 3 / 2) {
        return true;
    }

    return false;
}

/**
 * Returns true if the given candle is bull, hence it has a white (green) body.
 */
bool Candle::isCandleBull(int timeIndex) {
    if (iCandle(I_close, timeIndex) > iCandle(I_open, timeIndex)) {
        return true;
    }

    return false;
}

/**
 * Returns true if the given candle is a small candle, such as a pinbar or a doji.
 */
bool Candle::isSupportCandle(int timeIndex) {
    if (doji(timeIndex) || slimDoji(timeIndex) || upPinbar(timeIndex) || downPinbar(timeIndex)) {
        return true;
    }

    return false;
}

/**
 * Returns the candle body size.
 */
double Candle::candleBody(int timeIndex) {
    return MathAbs(iCandle(I_open, timeIndex) - iCandle(I_close, timeIndex));
}

/**
 * Returns the candle size, including the shadows.
 */
double Candle::candleSize(int timeIndex) {
    return MathAbs(iCandle(I_high, timeIndex) - iCandle(I_low, timeIndex));
}

/**
 * Returns the candle up shadow size.
 */
double Candle::candleUpShadow(int timeIndex) {
    return MathAbs(iCandle(I_high, timeIndex) - MathMax(iCandle(I_open, timeIndex), iCandle(I_close, timeIndex)));
}

/**
 * Returns the candle down shadow size.
 */
double Candle::candleDownShadow(int timeIndex) {
    return MathAbs(iCandle(I_low, timeIndex) - MathMin(iCandle(I_open, timeIndex), iCandle(I_close, timeIndex)));
}

/**
 * Returns the middle point of the candle body.
 */
double Candle::candleBodyMidPoint(int timeIndex) {
    return MathAbs(iCandle(I_open, timeIndex) + iCandle(I_close, timeIndex)) / 2;
}

/**
 * Returns the minimum of the candle body.
 */
double Candle::candleBodyMin(int timeIndex) {
    return MathMin(iCandle(I_open, timeIndex), iCandle(I_close, timeIndex));
}

/**
 * Returns the maximum of the candle body.
 */
double Candle::candleBodyMax(int timeIndex) {
    return MathMax(iCandle(I_open, timeIndex), iCandle(I_close, timeIndex));
}
