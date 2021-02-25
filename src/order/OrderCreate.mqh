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
        bool areThereBetterOrders(Order &);

        string findOrderChannelSetup(int);
        double calculateOrderOpenPriceFromSetups(int, string);
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

    const string channelSetup = findOrderChannelSetup(index);

    if (channelSetup == "") {
        return;
    }

    order.openPrice = calculateOrderOpenPriceFromSetups(index, channelSetup);
    order.type = calculateOrderTypeFromOpenPrice(order.openPrice);

    const bool isBuy = order.isBuy();
    const Discriminator discriminator = isBuy ? Max : Min;

    order.stopLoss = order.openPrice - discriminator * Pip(order.symbol) * STOPLOSS_SIZE_PIPS.get(order.symbol);

    const double takeProfitFactor = BASE_TAKEPROFIT_FACTOR;
    order.takeProfit = order.openPrice + discriminator * takeProfitFactor * order.getStopLossPips() * Pip(order.symbol);

    order.lots = calculateOrderLots(order.getStopLossPips(), order.symbol);

    ChannelsDraw channelsDraw;
    const int channelVolatility = (int) MathRound(1000 * GetMarketVolatility() *
        MathAbs(channelsDraw.getChannelSlope(channelSetup)) / Pip(order.symbol));

    order.buildComment(channelVolatility, takeProfitFactor);
    order.expiration = Time[0] + (ORDER_CANDLES_DURATION + 1 - index) * order.getPeriod() * 60;

    if (areThereBetterOrders(order)) {
        return;
    }

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
 * Checks if there are any valid channel setups, and in that case returns the channel name.
 */
string OrderCreate::findOrderChannelSetup(int index) {
    if (index < 0) {
        return ThrowException("", __FUNCTION__, StringConcatenate("Unprocessable index: ", index));
    }

    const double currentMarketValue = GetPrice();
    const string symbol = Symbol();

    ChannelsDraw channelsDraw;

    double previousChannelDistance = 100000;
    string channelSetupName = "";

    for (int i = ObjectsTotal() - 1; i >= 0; i--) {
        const string channelName = ObjectName(i);

        if (!channelsDraw.isChannel(channelName)) {
            continue;
        }

        const double channelSetupValue = ObjectGetValueByShift(channelName, index);
        const double channelSetupDistance = MathAbs(currentMarketValue - channelSetupValue);

        if (channelSetupDistance > ORDER_SETUP_BUFFER_PIPS * Pip()) {
            continue;
        }

        if ((channelsDraw.getChannelDiscriminator(channelName) == Max &&
            channelsDraw.getChannelSlope(channelName) <= 0) ||
            (channelsDraw.getChannelDiscriminator(channelName) == Min &&
            channelsDraw.getChannelSlope(channelName) >= 0)) {

            if (channelSetupDistance < previousChannelDistance) {
                previousChannelDistance = channelSetupDistance;
                channelSetupName = channelName;
            }
        }
    }

    if (channelSetupName == "") {
        NO_SETUP_TIMESTAMP = PrintTimer(NO_SETUP_TIMESTAMP, StringConcatenate(
            "No setup found at time: ", TimeToStr(Time[index])));
    } else {
        SETUP_TIMESTAMP = PrintTimer(SETUP_TIMESTAMP, StringConcatenate(
            "Found setup at time: ", TimeToStr(Time[index]), " for channel: ", channelSetupName));
    }

    return channelSetupName;
}

/**
 * Checks if there are any valid setups, and in that case returns the order openPrice.
 */
double OrderCreate::calculateOrderOpenPriceFromSetups(int index, string channelName) {
    if (index < 0) {
        return ThrowException(-1, __FUNCTION__, StringConcatenate("Unprocessable index: ", index));
    }

    const string symbol = Symbol();

    ChannelsDraw channelsDraw;
    Discriminator channelDiscriminator = channelsDraw.getChannelDiscriminator(channelName);

    double openPrice = ObjectGetValueByShift(channelName, index) -
        channelDiscriminator * ORDER_ENTER_BUFFER_PIPS * Pip();

    return openPrice;
}

/**
 * Returns the appropriate order type depending on the openPrice.
 */
int OrderCreate::calculateOrderTypeFromOpenPrice(double openPrice) {
    if (openPrice == -1) {
        return ThrowException(-1, __FUNCTION__, StringConcatenate("Unprocessable openPrice: ", openPrice));
    }

    if (openPrice > GetPrice()) {
        return OP_BUYSTOP;
    } else {
        return OP_SELLSTOP;
    }
}

/**
 * Checks if there have been any recent correlated open orders, so that it can be waited before placing new ones.
 */
bool OrderCreate::areThereRecentOrders(datetime date = NULL) {
    const int period = Period();
    const string symbol = Symbol();

    if (date == NULL) {
        // order.closeTime is in the broker time zone
        date = TimeCurrent();
    }

    // Putting a few candles back, and then rounding up to the end of the current half hour
    date = (datetime) (date - 60 * period * MathRound(CANDLES_BETWEEN_ORDERS / PeriodFactor(period)));
    date = date - date % (PERIOD_M30 * 60) + PERIOD_M30 * 60;

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
bool OrderCreate::areThereBetterOrders(Order & newOrder) {
    OrderFilter orderFilter;
    orderFilter.magicNumber.add(ALLOWED_MAGIC_NUMBERS);
    orderFilter.symbolFamily.add(SymbolFamily(newOrder.symbol));
    orderFilter.type.add(newOrder.type, OP_BUY, OP_SELL);

    Order orders[];
    orderFind_.getFilteredOrdersList(orders, orderFilter);

    OrderManage orderManage;

    for (int i = 0; i < ArraySize(orders); i++) {
        if (orderManage.findBestOrder(orders[i], newOrder)) {
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
