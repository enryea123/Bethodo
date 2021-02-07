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
        double trailer(double, double, double);
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
    const double breakEvenStopLoss = calculateBreakEvenStopLoss(order);

    if (!order.isBreakEven()) {
        OrderManage orderManage;
        NewsDraw newsDraw;

        if (GetSpread() > SPREAD_PIPS_CLOSE_MARKET || newsDraw.isNewsTimeWindow()) {
            Print("Closing order: ", order.ticket, " for high spread or news");
            orderManage.deleteSingleOrder(order);
            return;
        }
    }

    updateOrder(order, breakEvenStopLoss);
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
double OrderTrail::trailer(double openPrice, double stopLoss, double takeProfit) {
    const Discriminator discriminator = (takeProfit > openPrice) ? Max : Min;
    const double currentExtreme = iExtreme(discriminator, 0);
    const double currentExtremeToOpenDistance = currentExtreme - openPrice;
    const double profitToOpenDistance = takeProfit - openPrice;

    const double trailerBaseDistance = 2.0;
    const double trailerPercent = 0.0;

    const double trailer = trailerBaseDistance - trailerPercent * currentExtremeToOpenDistance / profitToOpenDistance;

    // This trailing assumes a constant takeProfit factor
    double initialStopLossDistance = profitToOpenDistance / BASE_TAKEPROFIT_FACTOR;
    double trailerStopLoss = currentExtreme - initialStopLossDistance * trailer;

    // Trailing StopLoss
    if (discriminator > 0) {
        stopLoss = MathMax(stopLoss, trailerStopLoss);
    } else {
        stopLoss = MathMin(stopLoss, trailerStopLoss);
    }

    return stopLoss;

    // In the future, implement a stopLoss trailing below the previous minimum

    /*
    // Trailing TakeProfit
    const double takeProfitPercentUpdate = 0.95;

    if ((discriminator > 0 && currentExtremeToOpenDistance > takeProfitPercentUpdate * profitToOpenDistance) ||
        (discriminator < 0 && currentExtremeToOpenDistance < takeProfitPercentUpdate * profitToOpenDistance)) {
        takeProfit += profitToOpenDistance * (1 - takeProfitPercentUpdate);
    }
    return takeProfit;
    */
}
