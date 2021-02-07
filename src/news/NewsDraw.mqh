#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "../market/MarketTime.mqh"
#include "../util/Exception.mqh"
#include "../util/Util.mqh"
#include "../util/Price.mqh"
#include "News.mqh"
#include "NewsParse.mqh"


/**
 * This class handles the drawings of the news on the chart.
 */
class NewsDraw {
    public:
        void drawNewsLines();
        void drawSingleNewsLine(News &);
        bool isNewsTimeWindow(datetime);

    private:
        color getNewsColorFromImpact(string);
        int getNewsLineWidthFromImpact(string);
};

/**
 * Draws all the news lines.
 */
void NewsDraw::drawNewsLines() {
    News news[];

    NewsParse newsParse;
    newsParse.readNewsFromCalendar(news);

    for (int i = 0; i < ArraySize(news); i++) {
        drawSingleNewsLine(news[i]);
    }
}

/**
 * Draws a single news vertical line and sets its properties.
 * It only draws news relevant to the current symbol, and filters out holidays.
 */
void NewsDraw::drawSingleNewsLine(News & news) {
    const string symbol = Symbol();

    if (!StringContains(symbol, news.country) || news.impact == "Holiday") {
        return;
    }

    const string newsNameIdentified = StringConcatenate(news.title, " ", news.country);
    const string lineName = StringConcatenate(NEWS_LINE_NAME_PREFIX, " ", newsNameIdentified);
    const string labelName = StringConcatenate(NEWS_LABEL_NAME_PREFIX, " ", newsNameIdentified);

    MarketTime marketTime;
    news.date += 3600 * marketTime.timeShiftInHours(marketTime.timeBroker(), marketTime.timeItaly());

    ObjectCreate(0, lineName, OBJ_VLINE, 0, news.date, 0);

    ObjectSet(lineName, OBJPROP_RAY_RIGHT, false);
    ObjectSet(lineName, OBJPROP_COLOR, getNewsColorFromImpact(news.impact));
    ObjectSet(lineName, OBJPROP_BACK, true);
    ObjectSet(lineName, OBJPROP_WIDTH, getNewsLineWidthFromImpact(news.impact));

    ObjectCreate(labelName, OBJ_TEXT, 0, news.date,
        iCandle(I_low, symbol, PERIOD_D1, 1) - NEWS_LABEL_PIPS_SHIFT * Pip(symbol));

    ObjectSetString(0, labelName, OBJPROP_TEXT, newsNameIdentified);
    ObjectSet(labelName, OBJPROP_COLOR, getNewsColorFromImpact(news.impact));
    ObjectSet(labelName, OBJPROP_FONTSIZE, NEWS_LABEL_FONT_SIZE);
    ObjectSet(labelName, OBJPROP_BACK, true);
    ObjectSet(labelName, OBJPROP_ANGLE, 90);
}

/**
 * Returns true if there is a high impact news for the current symbol within the current time window.
 */
bool NewsDraw::isNewsTimeWindow(datetime date = NULL) {
    MarketTime marketTime;

    if (date == NULL) {
        date = marketTime.timeItaly();
    }

    date += 3600 * marketTime.timeShiftInHours(marketTime.timeBroker(), marketTime.timeItaly());

    for (int i = ObjectsTotal() - 1; i >= 0; i--) {
        if (StringContains(ObjectName(i), NEWS_LINE_NAME_PREFIX) &&
            MathAbs(date - ObjectGet(ObjectName(i), OBJPROP_TIME1)) < 60 * NEWS_TIME_WINDOW_MINUTES &&
            ObjectGet(ObjectName(i), OBJPROP_COLOR) == getNewsColorFromImpact("High")) {
            return true;
        }
    }

    return false;
}

/**
 * Returns the color associated with each news type, which is then used to color the line and label.
 */
color NewsDraw::getNewsColorFromImpact(string impact) {
    if (impact == "High") {
        return clrCrimson;
    } else if (impact == "Medium") {
        return clrDarkOrange;
    } else if (impact == "Low") {
        return clrGold;
    } else if (impact == "Holiday") {
        return clrPurple;
    }

    return clrBlack;
}

/**
 * Returns the line width associated with each news type.
 */
int NewsDraw::getNewsLineWidthFromImpact(string impact) {
    if (impact == "High") {
        return 2;
    } else if (impact == "Medium") {
        return 1;
    } else if (impact == "Low") {
        return 1;
    } else if (impact == "Holiday") {
        return 1;
    }

    return 1;
}
