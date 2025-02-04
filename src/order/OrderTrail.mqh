#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "../market/Holiday.mqh"
#include "../market/MarketTime.mqh"
#include "../news/NewsDraw.mqh"
#include "../order/Order.mqh"
#include "../order/OrderFilter.mqh"
#include "../order/OrderFind.mqh"
#include "../order/OrderManage.mqh"


/**
 * This class allows to modify and trail an already existing opened order.
 */
class OrderTrail {
    public:
        void manageOpenOrders();

    protected:
        OrderFind orderFind_;

        void manageOpenOrder(Order &);
        void updateOrder(Order &, double, double);

        double calculateBreakEvenStopLoss(Order &);
        double calculateTrailingStopLoss(Order &);
        double getPreviousExtreme(Discriminator, int);
        bool closeOrderForTrailingProfit(Order &);
};

/**
 * Gets the list of opened orders that need to be managed.
 */
void OrderTrail::manageOpenOrders() {
    OrderFilter orderFilter;
    orderFilter.magicNumber.add(MagicNumber());
    orderFilter.symbol.add(Symbol());
    orderFilter.type.add(OP_BUY, OP_SELL);

    Order orders[];
    OrderFind orderFind;
    orderFind.getFilteredOrdersList(orders, orderFilter);

    for (int order = 0; order < ArraySize(orders); order++) {
        manageOpenOrder(orders[order]);
    }
}

/**
 * Manages a single opened order, calculates its new stoploss, and updates it.
 */
void OrderTrail::manageOpenOrder(Order & order) {
    if (!order.isBreakEven()) {
        OrderManage orderManage;
        NewsDraw newsDraw;

        if (GetSpread() > SPREAD_PIPS_CLOSE_MARKET || newsDraw.isNewsTimeWindow()) {
            Print("Closing order: ", order.ticket, " for news or spread");
            orderManage.deleteSingleOrder(order);
            return;
        }
    }

    const double breakEvenStopLoss = calculateBreakEvenStopLoss(order);
    const double trailingStopLoss = calculateTrailingStopLoss(order);

    double newStopLoss;

    if (order.getDiscriminator() == Max) {
        newStopLoss = MathMax(breakEvenStopLoss, trailingStopLoss);
    } else {
        newStopLoss = MathMin(breakEvenStopLoss, trailingStopLoss);
    }

    if (order.isBreakEven()) {
        MarketTime marketTime;
        const datetime date = marketTime.timeItaly();

        // Disabling trailing during rollover
        if ((TimeHour(date) == 22 && TimeMinute(date) > 50) ||
            (TimeHour(date) == 23 && TimeMinute(date) < 20)) {
            newStopLoss = order.openPrice;
        }
    }

    if (closeOrderForTrailingProfit(order)) {
        return;
    }

    updateOrder(order, newStopLoss);
}

/**
 * Send the update request for an already existing order, if its stopLoss or takeProfit have changed.
 */
void OrderTrail::updateOrder(Order & order, double newStopLoss, double newTakeProfit = NULL) {
    if (!UNIT_TESTS_COMPLETED || !order.isOpen()) {
        return;
    }

    if (newTakeProfit == NULL) {
        newTakeProfit = order.takeProfit;
    }

    const string symbol = order.symbol;

    if (MathRound(MathAbs(newTakeProfit - order.takeProfit) / Pip(symbol)) > 0 ||
        MathRound(MathAbs(newStopLoss - order.stopLoss) / Pip(symbol)) > 0) {

        ORDER_MODIFIED_TIMESTAMP = PrintTimer(ORDER_MODIFIED_TIMESTAMP, StringConcatenate(
            "Modifying the existing order: ", order.ticket));

        ResetLastError();

        const bool orderModified = OrderModify(
            order.ticket,
            NormalizeDouble(order.openPrice, Digits),
            NormalizeDouble(newStopLoss, Digits),
            NormalizeDouble(newTakeProfit, Digits),
            0
        );

        const int lastError = GetLastError();
        if (lastError != 0 || !orderModified) {
            ThrowException(__FUNCTION__, StringConcatenate("Error ", lastError,
                " when modifying order: ", order.toString(), ", newStopLoss: ", newStopLoss));
        }
    }
}

/**
 * Calculates the new stopLoss for an already existing order that might need to be updated.
 */
double OrderTrail::calculateBreakEvenStopLoss(Order & order) {
    const int period = order.getPeriod();
    const double openPrice = order.openPrice;
    const string symbol = order.symbol;

    if (order.isBreakEven()) {
        return order.stopLoss;
    }

    const Discriminator discriminator = order.getDiscriminator();
    const double currentPrice = GetPrice();

    const double breakEvenPoint = openPrice + discriminator *
        PeriodFactor(period) * Pip(symbol) * order.getStopLossPips() * BREAKEVEN_PERCENTAGE;

    double stopLoss = order.stopLoss;

    if (discriminator == Max && currentPrice > breakEvenPoint) {
        stopLoss = MathMax(stopLoss, openPrice + COMMISSION_SAVER_PIPS * Pip(symbol));
    }
    if (discriminator == Min && currentPrice < breakEvenPoint) {
        stopLoss = MathMin(stopLoss, openPrice - COMMISSION_SAVER_PIPS * Pip(symbol));
    }

    return stopLoss;
}

/**
 * Trails the stopLoss and the takeProfit for and already existing order.
 */
double OrderTrail::calculateTrailingStopLoss(Order & order) {
    const string symbol = order.symbol;
    const Discriminator discriminator = order.getDiscriminator();
    const Discriminator antiDiscriminator = (discriminator > 0) ? Min : Max;

    const double currentGain = MathAbs(GetPrice() - order.openPrice) / Pip(symbol) / order.getStopLossPips();

    if (!order.isBreakEven()) {
        return order.stopLoss;
    }

    double stopLoss = order.stopLoss;

    const int trailingSteps = TRAILING_STEPS.size();

    for (int i = 0; i < trailingSteps; i++) {
        if (i < trailingSteps - 1) {
            if (currentGain > TRAILING_STEPS.getKeys(i) && currentGain < TRAILING_STEPS.getKeys(i + 1)) {
                stopLoss = getPreviousExtreme(antiDiscriminator, TRAILING_STEPS.getValues(i));
            }
        } else {
            if (currentGain > TRAILING_STEPS.getKeys(i)) {
                stopLoss = getPreviousExtreme(antiDiscriminator, TRAILING_STEPS.getValues(i));
            }
        }
    }

    stopLoss -= discriminator * TRAILING_BUFFER_PIPS * Pip(symbol);

    if (discriminator > 0) {
        stopLoss = MathMax(stopLoss, order.stopLoss);
    } else {
        stopLoss = MathMin(stopLoss, order.stopLoss);
    }

    return stopLoss;
}

/**
 * Calculates the previous extreme out of numberOfCandles.
 */
double OrderTrail::getPreviousExtreme(Discriminator discriminator, int numberOfCandles) {
    if (numberOfCandles < 0) {
        return ThrowException(-1, __FUNCTION__, StringConcatenate("Unprocessable numberOfCandles: ", numberOfCandles));
    }

    double previousExtreme = (discriminator > 0) ? -10000 : 10000;

    for (int i = 0; i < numberOfCandles + 1; i++) {
        if (discriminator > 0) {
            previousExtreme = MathMax(previousExtreme, iExtreme(discriminator, i));
        } else {
            previousExtreme = MathMin(previousExtreme, iExtreme(discriminator, i));
        }
    }

    return previousExtreme;
}

/**
 * Calculates if the order can be closed with a trailing profit
 */
bool OrderTrail::closeOrderForTrailingProfit(Order & order) {
    const int ticket = order.ticket;
    const string symbol = order.symbol;

    const double lastCandleCloseGain = MathAbs(iCandle(I_close, 1) - order.openPrice) /
        Pip(symbol) / order.getStopLossPips();

    if (lastCandleCloseGain > TRAILING_PROFIT_GAIN_CLOSE) {
        ResetLastError();

        OrderManage orderManage;
        orderManage.deleteSingleOrder(order);

        const int lastError = GetLastError();

        if (lastError == 0 && UNIT_TESTS_COMPLETED) {
            Print(__FUNCTION__, MESSAGE_SEPARATOR, "Closed order: ", ticket, " for trailing profit");
        } else {
            ThrowException(__FUNCTION__, StringConcatenate(
                "Error ", lastError, " when trying to delete order: ", ticket));
        }

        return true;
    }

    return false;
}
