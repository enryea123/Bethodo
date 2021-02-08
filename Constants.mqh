#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "src/util/Map.mqh"


/**
 * This file acts like a config, it contains all the variables needed by the program.
 * The Maps defined here need to be initialized in OnInit.
 */

input double PERCENT_RISK = 1.0;

bool UNIT_TESTS_COMPLETED = false;

enum Discriminator {
   Max = 1,
   Min = -1,
};

// Constants start here

const bool IS_DEBUG = false;

const datetime BOT_EXPIRATION_DATE = (datetime) "2021-06-30";

// TimeZone Milano
const int MARKET_ORDER_OPEN_HOUR = 23;
const int MARKET_ORDER_OPEN_MINUTE = 45;
const int MARKET_ORDER_CLOSE_HOUR = 14;
const int MARKET_ORDER_CLOSE_MINUTE = 15;

const int MARKET_CLOSE_HOUR = 21;
const int MARKET_CLOSE_DAY = 5;

const int BASE_MAGIC_NUMBER = 837000;

const int ALLOWED_MAGIC_NUMBERS [] = {
    837060
};

const int ALLOWED_DEMO_ACCOUNT_NUMBERS [] = {
    2100219063, // Enrico
    2100220671, // Enrico
    2100220672, // Enrico
    2100222172, // Enrico
    2100225710, // Eugenio
    2100222405 // Tanya
};

const int ALLOWED_LIVE_ACCOUNT_NUMBERS [] = {
    2100183900, // Enrico
    2100175255, // Eugenio
    2100186686 // Tanya
};

const int ALLOWED_PERIODS [] = {
    PERIOD_H1
};

const int HISTORY_DOWNLOAD_PERIODS [] = {
    PERIOD_H1
};

const string ALLOWED_BROKERS [] = {
    "KEY TO MARKETS NZ Limited",
    "KEY TO MARKETS NZ LIMITED"
};

const string ALLOWED_SYMBOLS [] = {
    "AUDUSD",
    "EURUSD",
    "GBPAUD",
    "GBPUSD",
    "NZDCHF",
    "NZDUSD"
};

const string NAME_SEPARATOR = "_";
const string COMMENT_SEPARATOR = " ";
const string FILTER_SEPARATOR = "|";
const string MESSAGE_SEPARATOR = " | ";

const double BASE_TAKEPROFIT_FACTOR = 4;

const int CANDLES_VISIBLE_IN_GRAPH_3X = 465;
const int CANDLES_VISIBLE_IN_GRAPH_2X = 940;

const int MIN_CHANNEL_HEIGHT = 50;
const int MAX_CHANNEL_HEIGHT = 300;
const double CHANNEL_BALANCE_RATIO = 0.65;
const double CHANNEL_PARALLEL_SLOPE_THREHSOLD = 0.06;
const int CHANNEL_LINE_WIDTH = 5;
const color CHANNEL_COLOR = clrYellow;

const string ARROW_NAME_PREFIX = "Arrow";
const string VALID_ARROW_NAME_SUFFIX = "Valid";
const string LEVEL_NAME_PREFIX = "Level";

const double EMERGENCY_SWITCHOFF_OPENPRICE = 42;
const double EMERGENCY_SWITCHOFF_STOPLOSS = 41;
const double EMERGENCY_SWITCHOFF_TAKEPROFIT = 43;

const int LOSS_LIMITER_HOURS = 8;
const int LOSS_LIMITER_MAX_ALLOWED_LOSSES_PERCENT = 10;

const int FIND_DAY_MAX_YEARS_RANGE = 5;

const int EXTREMES_MAX_CANDLES = 300;
const int EXTREMES_MIN_DISTANCE = 3;
const int LEVELS_MIN_DISTANCE = 4;
const int LEVELS_TOLERANCE_PIPS = 4;

const int INCORRECT_CLOCK_ERROR_SECONDS = 60;

const int SPREAD_PIPS_CLOSE_MARKET = 6;

const int ORDER_SETUP_BUFFER_PIPS = 4;
const int CHANNEL_LEVEL_SETUP_MAX_DISTANCE_PIPS = 4;
const int SETUP_MAX_DISTANCE_PIPS = 20;
const double CHANNEL_MIN_SLOPE_VOLATILITY = 0.0003;

const int ORDER_CANDLES_DURATION = 3;
const int MAX_ORDER_COMMENT_CHARACTERS = 20;

const string STRATEGY_PREFIX = "B";
const string PERIOD_COMMENT_IDENTIFIER = "P";
const string SIZE_FACTOR_COMMENT_IDENTIFIER = "M";
const string TAKEPROFIT_FACTOR_COMMENT_IDENTIFIER = "R";
const string STOPLOSS_PIPS_COMMENT_IDENTIFIER = "S";

const int SMALLER_STOPLOSS_BUFFER_PIPS = 1;

const string LAST_DRAWING_TIME_PREFIX = "LastDrawingTime";

const int TRENDLINE_MIN_CANDLES_LENGTH = 30;
const int TRENDLINE_MIN_EXTREMES_DISTANCE = 10;
const int TRENDLINE_BEAMS = 2;
const int TRENDLINE_TOLERANCE_PIPS = 4;
const int TRENDLINE_WIDTH = 1;
const int BAD_TRENDLINE_WIDTH = 1;
const double TRENDLINE_NEGATIVE_SLOPE_VOLATILITY = 0.0070;
const double TRENDLINE_POSITIVE_SLOPE_VOLATILITY = 0.0070;
const double TRENDLINE_BALANCE_RATIO_THRESHOLD = 0.8;
const color TRENDLINE_COLOR = clrMistyRose;
const color BAD_TRENDLINE_COLOR = clrLightPink;
const string TRENDLINE_NAME_PREFIX = "TrendLine";
const string TRENDLINE_BAD_NAME_SUFFIX = "Bad";
const string TRENDLINE_NAME_BEAM_IDENTIFIER = "b";
const string TRENDLINE_NAME_FIRST_INDEX_IDENTIFIER = "i";
const string TRENDLINE_NAME_SECOND_INDEX_IDENTIFIER = "j";

const string CALENDAR_FILE = "ff_calendar_thisweek.csv";
const string CALENDAR_HEADER = "Title,Country,Date,Time,Impact,Forecast,Previous";

const int NEWS_TIME_WINDOW_MINUTES = 60;
const int NEWS_LABEL_FONT_SIZE = 10;
const int NEWS_LABEL_PIPS_SHIFT = 20;
const string NEWS_LINE_NAME_PREFIX = "NewsLine";
const string NEWS_LABEL_NAME_PREFIX = "NewsLabel";

// Associative Maps
Map<int, double> PERCENT_RISK_ACCOUNT_EXCEPTIONS;
Map<string, int> RESTRICTED_SYMBOLS;
Map<string, int> STOPLOSS_SIZE_PIPS;
Map<string, double> BREAKEVEN_PERCENTAGE;

// Maps need to be initialized by OnInit
void InitializeMaps() {
    PERCENT_RISK_ACCOUNT_EXCEPTIONS.put(2100183900, 1.0);
    PERCENT_RISK_ACCOUNT_EXCEPTIONS.lock();

    // Just here as dummy value for now
    RESTRICTED_SYMBOLS.put("EURJPY", PERIOD_H1);
    RESTRICTED_SYMBOLS.lock();

    STOPLOSS_SIZE_PIPS.put("AUDUSD", 13);
    STOPLOSS_SIZE_PIPS.put("EURUSD", 12);
    STOPLOSS_SIZE_PIPS.put("GBPAUD", 30);
    STOPLOSS_SIZE_PIPS.put("GBPUSD", 17);
    STOPLOSS_SIZE_PIPS.put("NZDCHF", 10);
    STOPLOSS_SIZE_PIPS.put("NZDUSD", 11);
    STOPLOSS_SIZE_PIPS.lock();

    BREAKEVEN_PERCENTAGE.put("AUDUSD", 1.25);
    BREAKEVEN_PERCENTAGE.put("EURUSD", 1.25);
    BREAKEVEN_PERCENTAGE.put("GBPAUD", 1.5);
    BREAKEVEN_PERCENTAGE.put("GBPUSD", 1.5);
    BREAKEVEN_PERCENTAGE.put("NZDCHF", 1.25);
    BREAKEVEN_PERCENTAGE.put("NZDUSD", 1.25);
    BREAKEVEN_PERCENTAGE.lock();
}

datetime NEWS_TIMESTAMP = -1;
datetime SPREAD_TIMESTAMP = -1;
datetime WRONG_CLOCK_TIMESTAMP = -1;

datetime SETUP_TIMESTAMP = -1;
datetime NO_SETUP_TIMESTAMP = -1;

datetime VOLATILITY_TIMESTAMP = -1;
datetime ORDER_MODIFIED_TIMESTAMP = -1;
