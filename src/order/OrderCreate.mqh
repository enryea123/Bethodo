#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "../channel/ChannelsDraw.mqh"
#include "../extreme/LevelsDraw.mqh"
#include "../market/Holiday.mqh"
#include "../market/Market.mqh"
#include "../order/OrderManage.mqh"
#include "../trendline/TrendLine.mqh"


/**
 * This class allows to place new orders.
 */
class OrderCreate {
    public:
        void newOrder();

        bool areThereRecentOrders(datetime);
        bool areThereBetterOrders(string, int, double, double);

        double calculateOrderOpenPriceFromSetups(int);
        int calculateOrderTypeFromOpenPrice(double);
        double calculateOrderLots(int, string);
        double getPercentRisk();

    protected:
        OrderFind orderFind_;

        void createNewOrder(int);
        void sendOrder(Order &);
};

/**
 * Checks if some preconditions are met, and then tries to create new orders.
 */
void OrderCreate::newOrder() {
    Market market;

    if (Minute() == 0 || Minute() == 59 || Minute() == 30 || Minute() == 29) {
        return;
    }
    if (areThereRecentOrders()) {
        return;
    }

    createNewOrder(0);
}

/**
 * Creates a new pending order.
 */
void OrderCreate::createNewOrder(int index) {
    if (index < 0) {
        ThrowException(__FUNCTION__, StringConcatenate("Unprocessable index: ", index));
        return;
    }

    Order order;
    order.symbol = Symbol();
    order.magicNumber = MagicNumber();
    order.openPrice = calculateOrderOpenPriceFromSetups(index);

    if (order.openPrice == -1) {
        return;
    }

    order.type = calculateOrderTypeFromOpenPrice(order.openPrice);

    const bool isBuy = order.isBuy();
    const Discriminator discriminator = isBuy ? Max : Min;

    order.stopLoss = order.openPrice - discriminator * Pip(order.symbol) * STOPLOSS_SIZE_PIPS.get(order.symbol);

    const double takeProfitFactor = BASE_TAKEPROFIT_FACTOR;
    order.takeProfit = order.openPrice + discriminator * takeProfitFactor * order.getStopLossPips() * Pip(order.symbol);

    order.lots = calculateOrderLots(order.getStopLossPips(), order.symbol);

    if (areThereBetterOrders(order.symbol, order.type, order.openPrice, order.stopLoss)) {
        return;
    }

    order.expiration = Time[0] + (ORDER_CANDLES_DURATION + 1 - index) * order.getPeriod() * 60;
    order.buildComment(1.0, takeProfitFactor);

    sendOrder(order);
}

/**
 * Creates a new pending order.
 */
void OrderCreate::sendOrder(Order & order) {
    if (!UNIT_TESTS_COMPLETED) {
        return;
    }

    ResetLastError();

    order.ticket = OrderSend(
        order.symbol,
        order.type,
        order.lots,
        NormalizeDouble(order.openPrice, Digits),
        3,
        NormalizeDouble(order.stopLoss, Digits),
        NormalizeDouble(order.takeProfit, Digits),
        order.comment,
        order.magicNumber,
        order.expiration
    );

    int lastError = GetLastError();

    if (lastError != 0) {
        ThrowException(__FUNCTION__, StringConcatenate(
            "Error ", lastError, " when creating order: ", order.ticket));
    }

    if (order.ticket > 0) {
        const int previouslySelectedOrder = OrderTicket();
        const int selectedOrder = OrderSelect(order.ticket, SELECT_BY_TICKET);

        Print("New order created with ticket: ", order.ticket);
        OrderPrint();

        if (order.type != OrderType() || order.lots != OrderLots() || order.comment != OrderComment() ||
            order.magicNumber != OrderMagicNumber() || order.expiration != OrderExpiration()) {
            Print(order.toString());
            ThrowException(__FUNCTION__, StringConcatenate("Mismatching information ",
                "in newly created order with ticket: ", order.ticket, ", error: ", GetLastError()));
        }

        const bool selectSucceeded = OrderSelect(previouslySelectedOrder, SELECT_BY_TICKET);
        lastError = GetLastError();

        if (previouslySelectedOrder != 0 && !selectSucceeded && lastError != 4051) {
            ThrowException(__FUNCTION__, StringConcatenate(
                "Could not select back previous order: ", previouslySelectedOrder, ", error: ", lastError));
        }
    }
}

/**
 * Checks if there are any valid setups, and in that case returns the order openPrice.
 */
double OrderCreate::calculateOrderOpenPriceFromSetups(int index) {
    if (index < 0) {
        return ThrowException(-1, __FUNCTION__, StringConcatenate("Unprocessable index: ", index));
    }

    const string symbol = Symbol();

    LevelsDraw levelsDraw;
    ChannelsDraw channelsDraw;

    double openPriceMax = -1;
    double openPriceMin = -1;

    for (int i = ObjectsTotal() - 1; i >= 0; i--) {
        const string levelName = ObjectName(i);

        if (!levelsDraw.isLevelFromName(levelName)) {
            continue;
        }

        const double levelSetupValue = ObjectGetValueByShift(levelName, index);

        if (MathAbs(GetPrice() - levelSetupValue) > SETUP_MAX_DISTANCE_PIPS * Pip(symbol)) {
            continue;
        }

        for (int j = ObjectsTotal() - 1; j >= 0; j--) {
            const string channelName = ObjectName(j);

            if (!channelsDraw.isChannel(channelName)) {
                continue;
            }

            if (levelsDraw.getLevelDiscriminator(levelName) != channelsDraw.getChannelDiscriminator(channelName)) {
                continue;
            }

            const double channelSetupValue = ObjectGetValueByShift(channelName, index);

            if (MathAbs(channelSetupValue - levelSetupValue) > CHANNEL_LEVEL_SETUP_MAX_DISTANCE_PIPS * Pip()) {
                continue;
            }

            //// Implement threshold of 3 degrees for opposed slope, with CHANNEL_MIN_SLOPE_VOLATILITY
            if (channelsDraw.getChannelDiscriminator(channelName) == Max &&
                channelsDraw.getChannelSlope(channelName) <= 0) {
                openPriceMax = MathMin(openPriceMax, levelSetupValue);
            }
            if (channelsDraw.getChannelDiscriminator(channelName) == Min &&
                channelsDraw.getChannelSlope(channelName) >= 0) {
                openPriceMin = MathMax(openPriceMin, levelSetupValue);
            }
        }
    }

    double openPrice = -1;

    if (MathAbs(GetPrice() - openPriceMax) < MathAbs(GetPrice() - openPriceMin)) {
        openPrice = openPriceMax - ORDER_SETUP_BUFFER_PIPS * Pip();
    } else {
        openPrice = openPriceMin + ORDER_SETUP_BUFFER_PIPS * Pip();
    }

    if (openPrice == -1) {
        NO_SETUP_TIMESTAMP = PrintTimer(NO_SETUP_TIMESTAMP, StringConcatenate(
            "No setups found at time: ", TimeToStr(Time[index])));
    } else {
        SETUP_TIMESTAMP = PrintTimer(SETUP_TIMESTAMP, StringConcatenate(
            "Found setup at time: ", TimeToStr(Time[index]), " for Level: ", openPrice));
    }

    return openPrice;
}

/**
 * Returns the appropriate order type depending on the openPrice.
 */
int OrderCreate::calculateOrderTypeFromOpenPrice(double openPrice) {
    if (openPrice == -1) {
        return ThrowException(-1, __FUNCTION__, StringConcatenate("Unprocessable openPrice: ", openPrice));
    }

    LevelsDraw levelsDraw;
    Discriminator orderDiscriminator = Min;

    for (int i = ObjectsTotal() - 1; i >= 0; i--) {
        const string levelName = ObjectName(i);

        if (!levelsDraw.isLevelFromName(levelName)) {
            continue;
        }

        const double levelSetupValue = ObjectGetValueByShift(levelName, 1);

        if (levelsDraw.getLevelDiscriminator(levelName) == Max &&
            levelSetupValue == openPrice + ORDER_SETUP_BUFFER_PIPS * Pip()) {
            orderDiscriminator = Min;
            break;
        }
        if (levelsDraw.getLevelDiscriminator(levelName) == Min &&
            levelSetupValue == openPrice - ORDER_SETUP_BUFFER_PIPS * Pip()) {
            orderDiscriminator = Max;
            break;
        }
    }

    if (orderDiscriminator == Min) {
        if (openPrice > GetPrice()) {
            return OP_SELLLIMIT;
        } else {
            return OP_SELLSTOP;
        }
    } else {
        if (openPrice < GetPrice()) {
            return OP_BUYLIMIT;
        } else {
            return OP_BUYSTOP;
        }
    }
}

/**
 * Checks if there have been any recent correlated open orders, so that it can be waited before placing new ones.
 */
bool OrderCreate::areThereRecentOrders(datetime date = NULL) {
    const int period = Period();
    const string symbol = Symbol();

    if (date == NULL) {
        date = (datetime) (TimeCurrent() - 60 * period * MathRound(ORDER_CANDLES_DURATION / PeriodFactor(period)));
        // Rounding up to the beginning of the last half hour
        date -= date % (PERIOD_M30 * 60);
    }

    const datetime thisTime = Time[0];

    static datetime cachedDate;
    static datetime timeStamp;

    static bool recentOrders;

    if (cachedDate == date && timeStamp == thisTime && UNIT_TESTS_COMPLETED) {
        return recentOrders;
    }

    cachedDate = date;
    timeStamp = thisTime;

    OrderFilter orderFilter;
    orderFilter.magicNumber.add(ALLOWED_MAGIC_NUMBERS);
    orderFilter.symbolFamily.add(SymbolFamily(symbol));
    orderFilter.type.add(OP_BUY, OP_SELL);

    orderFilter.closeTime.setFilterType(Greater);
    orderFilter.closeTime.add(date);

    Order orders[];
    orderFind_.getFilteredOrdersList(orders, orderFilter, MODE_HISTORY);

    recentOrders = false;
    if (ArraySize(orders) > 0) {
        recentOrders = true;
    }

    return recentOrders;
}

/**
 * Checks if there are other pending orders. In case they are with worst setups it deletes them.
 */
bool OrderCreate::areThereBetterOrders(string symbol, int type, double openPrice, double stopLoss) {
    OrderFilter orderFilter;
    orderFilter.magicNumber.add(ALLOWED_MAGIC_NUMBERS);
    orderFilter.symbolFamily.add(SymbolFamily(symbol));
    orderFilter.type.add(type, OP_BUY, OP_SELL);

    Order orders[];
    orderFind_.getFilteredOrdersList(orders, orderFilter);

    Order newOrder;
    newOrder.symbol = symbol;
    newOrder.type = type;
    newOrder.openPrice = openPrice;
    newOrder.stopLoss = stopLoss;

    OrderManage orderManage;

    for (int order = 0; order < ArraySize(orders); order++) {
        if (orderManage.findBestOrder(orders[order], newOrder)) {
            return true;
        }
    }

    return false;
}

/**
 * Calculates the size for a new order, and makes sure that it's divisible by 2,
 * so that the position can be later split.
 */
double OrderCreate::calculateOrderLots(int stopLossPips, string symbol) {
    const double absoluteRisk = getPercentRisk() * AccountEquity() / MarketInfo(symbol, MODE_TICKVALUE);
    const int stopLossTicks = stopLossPips * 10;

    const double rawOrderLots = absoluteRisk / stopLossTicks;

    double lots = 2 * NormalizeDouble(rawOrderLots / 2, 2);
    lots = MathMax(lots, 0.02);

    return NormalizeDouble(lots, 2);
}

/**
 * Returns the percent risk for a position, depending on the account.
 */
double OrderCreate::getPercentRisk() {
    const double exceptionPercentRisk = PERCENT_RISK_ACCOUNT_EXCEPTIONS.get(AccountNumber());
    const double percentRisk = (exceptionPercentRisk != NULL) ? exceptionPercentRisk : PERCENT_RISK;

    return percentRisk / 100;
}
