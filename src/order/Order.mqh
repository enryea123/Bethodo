#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../util/Util.mqh"
#include "../util/Price.mqh"


/**
 * This class is an interface for orders. It provides basic attributes
 * and a few methods that allow to get extra information on the order.
 */
class Order {
    public:
        Order();

        int magicNumber;
        int ticket;
        int type;
        double closePrice;
        double openPrice;
        double lots;
        double profit;
        double stopLoss;
        double takeProfit;
        string comment;
        string symbol;
        datetime openTime;
        datetime closeTime;
        datetime expiration;

        bool operator == (const Order &);
        bool operator != (const Order &);

        bool isBreakEven();
        int getPeriod();
        int getStopLossPips();
        string toString();

        void buildComment(int, double);
        int getVolatilityFromComment();

        bool isOpen();
        bool isBuy();
        bool isSell();
        Discriminator getDiscriminator();
};

Order::Order():
    magicNumber(-1),
    ticket(-1),
    type(-1),
    closePrice(-1),
    openPrice(-1),
    lots(-1),
    profit(-1),
    stopLoss(-1),
    takeProfit(-1),
    comment(NULL),
    symbol(NULL),
    openTime(NULL),
    closeTime(NULL),
    expiration(NULL) {
}

bool Order::operator == (const Order & v) {
    return (
        magicNumber == v.magicNumber &&
        ticket == v.ticket &&
        type == v.type &&
        closePrice == v.closePrice &&
        openPrice == v.openPrice &&
        lots == v.lots &&
        profit == v.profit &&
        stopLoss == v.stopLoss &&
        takeProfit == v.takeProfit &&
        comment == v.comment &&
        symbol == v.symbol &&
        openTime == v.openTime &&
        closeTime == v.closeTime &&
        expiration == v.expiration
    );
}

bool Order::operator != (const Order & v) {
    return !(this == v);
}

/**
 * Returns true if the order has reached the breakEven point, based on the comment.
 */
bool Order::isBreakEven() {
    if (type == -1 || openPrice == -1 || stopLoss == -1) {
        return ThrowException(false, __FUNCTION__, "Some order quantities not initialized");
    }

    if ((isBuy() && stopLoss >= openPrice) || (isSell() && stopLoss <= openPrice)) {
        return true;
    }

    return false;
}

/**
 * Calculates the period of an order, starting from the magicNumber.
 * It assumes the magicNumber is set of the form: BASE + Period.
 */
int Order::getPeriod() {
    if (magicNumber == -1) {
        return ThrowException(-1, __FUNCTION__, "Order magicNumber not initialized");
    }

    for (int i = 0; i < ArraySize(ALLOWED_MAGIC_NUMBERS); i++) {
        if (magicNumber == ALLOWED_MAGIC_NUMBERS[i]) {
            return (magicNumber - BASE_MAGIC_NUMBER);
        }
    }

    return ThrowException(-1, __FUNCTION__, "Could not get period for unknown magicNumber");
}

/**
 * Calculates the number of pips of an order stopLoss.
 */
int Order::getStopLossPips() {
    if (symbol == NULL) {
        return ThrowException(-1, __FUNCTION__, "Order symbol not initialized");
    }

    if (symbol != Symbol()) {
        return ThrowException(-1, __FUNCTION__, "Cannot get ATR for a different symbol");
    }

    return (int) MathRound(AverageTrueRange() * STOPLOSS_ATR_PERCENTAGE);
}

/**
 * Returns all the order information as string, so that it can be printed.
 */
string Order::toString() {
    return StringConcatenate("OrderInfo", MESSAGE_SEPARATOR,
        "magicNumber: ", magicNumber, ", "
        "ticket: ", ticket, ", "
        "type: ", type, ", "
        "closePrice: ", NormalizeDouble(closePrice, Digits), ", "
        "openPrice: ", NormalizeDouble(openPrice, Digits), ", "
        "lots: ", NormalizeDouble(lots, 2), ", "
        "profit: ", NormalizeDouble(profit, Digits), ", "
        "stopLoss: ", NormalizeDouble(stopLoss, Digits), ", "
        "takeProfit: ", NormalizeDouble(takeProfit, Digits), ", "
        "comment: ", comment, ", "
        "symbol: ", symbol, ", "
        "openTime: ", openTime, ", "
        "closeTime: ", closeTime, ", "
        "expiration: ", expiration
    );
}

/**
 * Creates the comment for a new pending order, and makes sure it doesn't exceed the maximum length.
 */
void Order::buildComment(int channelVolatility, double takeProfitFactor) {
    comment = StringConcatenate(
        STRATEGY_PREFIX,
        COMMENT_SEPARATOR, PERIOD_COMMENT_IDENTIFIER, getPeriod(),
        COMMENT_SEPARATOR, CHANNEL_VOLATILITY_COMMENT_IDENTIFIER, (int) MathRound(channelVolatility),
        COMMENT_SEPARATOR, TAKEPROFIT_FACTOR_COMMENT_IDENTIFIER, NormalizeDouble(takeProfitFactor, 1),
        COMMENT_SEPARATOR, STOPLOSS_PIPS_COMMENT_IDENTIFIER, (int) MathRound(getStopLossPips())
    );

    if (StringLen(comment) > MAX_ORDER_COMMENT_CHARACTERS) {
        comment = StringSubstr(comment, 0, MAX_ORDER_COMMENT_CHARACTERS);
        ThrowException(__FUNCTION__, "Order comment too long");
    }
}

/**
 * Estrapolates the channel volatility from a well formatted order comment.
 */
int Order::getVolatilityFromComment() {
    if (comment == NULL) {
        return ThrowException(-1, __FUNCTION__, "Order comment not initialized");
    }
    if (!StringContains(comment, StringConcatenate(CHANNEL_VOLATILITY_COMMENT_IDENTIFIER))) {
        return ThrowException(-1, __FUNCTION__, "The order comment does not contain the volatility");
    }

    string splittedComment[];
    StringSplit(comment, StringGetCharacter(COMMENT_SEPARATOR, 0), splittedComment);

    for (int i = 0; i < ArraySize(splittedComment); i++) {
        if (StringContains(splittedComment[i], CHANNEL_VOLATILITY_COMMENT_IDENTIFIER)) {
            StringSplit(splittedComment[i], StringGetCharacter(
                CHANNEL_VOLATILITY_COMMENT_IDENTIFIER, 0), splittedComment);
            break;
        }
    }

    if (ArraySize(splittedComment) == 2) {
        return (int) splittedComment[1];
    }

    return ThrowException(-1, __FUNCTION__, "Could not get the volatility from comment");
}

/**
 * Checks the order type to determine whether it's opened.
 */
bool Order::isOpen() {
    if (type == -1) {
        return ThrowException(false, __FUNCTION__, "Order type not initialized");
    }

    return (type == OP_BUY || type == OP_SELL) ? true : false;
}

/**
 * Checks the order type to determine whether it's of buy type.
 */
bool Order::isBuy() {
    if (type == -1) {
        return ThrowException(false, __FUNCTION__, "Order type not initialized");
    }

    return (getDiscriminator() == Max) ? true : false;
}

/**
 * Checks the order type to determine whether it's of sell type.
 */
bool Order::isSell() {
    return !isBuy();
}

/**
 * Calculates the discriminator of an order from its type.
 */
Discriminator Order::getDiscriminator() {
    if (type == -1) {
        return ThrowException(Min, __FUNCTION__, "Order type not initialized");
    }

    return (type == OP_BUY || type == OP_BUYSTOP || type == OP_BUYLIMIT) ? Max : Min;
}
