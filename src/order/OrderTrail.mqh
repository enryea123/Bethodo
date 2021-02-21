#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "../market/Holiday.mqh"
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

    private:
        double getPreviousExtreme(Discriminator, int);
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
/*
    if (!order.isBreakEven()) {
        OrderManage orderManage;
        NewsDraw newsDraw;

        if (GetSpread() > SPREAD_PIPS_CLOSE_MARKET || newsDraw.isNewsTimeWindow()) {
            Print("Closing order: ", order.ticket, " for high spread or news");
            orderManage.deleteSingleOrder(order);
            return;
        }
    }
*/

    const double breakEvenStopLoss = calculateBreakEvenStopLoss(order);
    const double trailingStopLoss = calculateTrailingStopLoss(order);

    double newStopLoss;

    if (order.getDiscriminator() == Max) {
        newStopLoss = MathMax(breakEvenStopLoss, trailingStopLoss);
    } else {
        newStopLoss = MathMin(breakEvenStopLoss, trailingStopLoss);
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
            ThrowException(__FUNCTION__, StringConcatenate(
                "Error ", lastError, " when modifying order: ", order.ticket));
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
    const double currentExtreme = iExtreme(discriminator, 0);

    double stopLoss = order.stopLoss;

    double breakEvenPoint = openPrice + discriminator *
        PeriodFactor(period) * Pip(symbol) * order.getStopLossPips() * BREAKEVEN_PERCENTAGE.get(symbol);

    if (discriminator == Max && currentExtreme > breakEvenPoint) {
        stopLoss = MathMax(stopLoss, openPrice);
    }
    if (discriminator == Min && currentExtreme < breakEvenPoint) {
        stopLoss = MathMin(stopLoss, openPrice);
    }

    return stopLoss;
}

/**
 * Trails the stopLoss and the takeProfit for and already existing order.
 */
double OrderTrail::calculateTrailingStopLoss(Order & order) {
    const Discriminator discriminator = order.getDiscriminator();
    const Discriminator antiDiscriminator = (discriminator > 0) ? Min : Max;

    const double currentGain = MathAbs(GetPrice() - order.openPrice) / STOPLOSS_SIZE_PIPS.get(order.symbol);

    double stopLoss = order.stopLoss;

    if (currentGain < 2) {
        stopLoss = order.stopLoss;
    } else if (currentGain > 2 && currentGain < 3) {
        stopLoss = getPreviousExtreme(antiDiscriminator, 8);
    } else if (currentGain > 3 && currentGain < 4) {
        stopLoss = getPreviousExtreme(antiDiscriminator, 4);
    } else if (currentGain > 4 && currentGain < 5) {
        stopLoss = getPreviousExtreme(antiDiscriminator, 2);
    } else if (currentGain > 5) {
        stopLoss = getPreviousExtreme(antiDiscriminator, 1);
    }

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

    for (int i = 1; i < numberOfCandles + 1; i++) {
        if (discriminator > 0) {
            previousExtreme = MathMax(previousExtreme, iExtreme(discriminator, i));
        } else {
            previousExtreme = MathMin(previousExtreme, iExtreme(discriminator, i));
        }
    }

    return previousExtreme;
}
