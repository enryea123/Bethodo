#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "../util/Price.mqh"
#include "Order.mqh"
#include "OrderFilter.mqh"
#include "OrderFind.mqh"


/**
 * This class allows to perform common managing operations on orders,
 * and to check if emergency conditions are met and the bot should be removed.
 */
class OrderManage {
    public:
        bool areThereOpenOrders();
        bool areThereOrdersThisSymbolThisPeriod();

        void deduplicateOrders();
        void emergencySwitchOff();
        void lossLimiter();

        bool findBestOrder(Order &, Order &);

        void deleteAllOrders();
        void deletePendingOrders();
        void deleteOrdersFromList(Order & []);
        void deleteSingleOrder(Order &);

    protected:
        OrderFind orderFind_;

    private:
        void deduplicateDiscriminatedOrders(Discriminator);
};

/**
 * Checks if there are any already opened orders,
 * across all periods and correlated symbols.
 */
bool OrderManage::areThereOpenOrders() {
    OrderFilter orderFilter;
    orderFilter.magicNumber.add(ALLOWED_MAGIC_NUMBERS);
    orderFilter.symbolFamily.add(SymbolFamily());
    orderFilter.type.add(OP_BUY, OP_SELL);

    Order orders[];
    orderFind_.getFilteredOrdersList(orders, orderFilter);

    return (ArraySize(orders) > 0);
}

/**
 * Checks if there are any pending orders,
 * across all periods and correlated symbols.
 */
bool OrderManage::areThereOrdersThisSymbolThisPeriod() {
    OrderFilter orderFilter;
    orderFilter.magicNumber.add(MagicNumber());
    orderFilter.symbol.add(Symbol());

    Order orders[];
    orderFind_.getFilteredOrdersList(orders, orderFilter);

    return (ArraySize(orders) > 0);
}

/**
 * Ensures that only one open or correlated pending order at a time is present.
 * If it finds more orders, it deletes the worst ones.
 */
void OrderManage::deduplicateOrders() {
    deduplicateDiscriminatedOrders(Max);
    deduplicateDiscriminatedOrders(Min);
}

/**
 * Deduplicates correlated orders in one direction.
 */
void OrderManage::deduplicateDiscriminatedOrders(Discriminator discriminator) {
    OrderFilter orderFilter;
    orderFilter.magicNumber.add(ALLOWED_MAGIC_NUMBERS);
    orderFilter.symbolFamily.add(SymbolFamily());

    orderFilter.type.setFilterType(Exclude);

    if (discriminator == Max) {
        orderFilter.type.add(OP_SELLSTOP, OP_SELLLIMIT);
    } else {
        orderFilter.type.add(OP_BUYSTOP, OP_BUYLIMIT);
    }

    Order orders[];
    orderFind_.getFilteredOrdersList(orders, orderFilter);

    if (ArraySize(orders) > 0) {
        int bestOrderIndex = 0;

        for (int i = 0; i < ArraySize(orders); i++) {
            for (int j = 0; j < ArraySize(orders); j++) {
                if (i != j) {
                    bestOrderIndex = findBestOrder(orders[i], orders[j]) ? i : j;
                }
            }
        }

        ArrayRemove(orders, bestOrderIndex);
        deleteOrdersFromList(orders);
    }
}

/**
 * Checks if the emergency order exists. In that case, it deletes all the orders and removes the bot.
 */
void OrderManage::emergencySwitchOff() {
    OrderFilter orderFilter;
    orderFilter.magicNumber.setFilterType(Exclude);
    orderFilter.magicNumber.add(ALLOWED_MAGIC_NUMBERS);

    Order orders[];
    orderFind_.getFilteredOrdersList(orders, orderFilter);

    for (int i = 0; i < ArraySize(orders); i++) {
        if (orders[i].openPrice == EMERGENCY_SWITCHOFF_OPENPRICE &&
            orders[i].stopLoss == EMERGENCY_SWITCHOFF_STOPLOSS &&
            orders[i].takeProfit == EMERGENCY_SWITCHOFF_TAKEPROFIT) {
            deleteAllOrders();

            if (UNIT_TESTS_COMPLETED) {
                ThrowFatalException(__FUNCTION__, StringConcatenate(
                    "Emergency switchOff invoked for order: ", orders[i].toString()));
            }
        }
    }
}

/**
 * Checks if the recent losses of the bot have been too high,
 * and in that case deletes all the orders and removes the bot.
 * It runs once every 5 minutes to improve performance.
 */
void OrderManage::lossLimiter() {
    static datetime timeStamp;
    const datetime thisTime = (datetime) iCandle(I_time, Symbol(), PERIOD_M5, 0);

    if (timeStamp == thisTime && UNIT_TESTS_COMPLETED) {
        return;
    }
    timeStamp = thisTime;

    OrderFilter orderFilter;
    orderFilter.magicNumber.add(ALLOWED_MAGIC_NUMBERS);

    orderFilter.profit.setFilterType(Exclude);
    orderFilter.profit.add(0);

    orderFilter.closeTime.setFilterType(Greater);
    orderFilter.closeTime.add(TimeCurrent() - LOSS_LIMITER_HOURS * 3600);

    Order orders[];
    orderFind_.getFilteredOrdersList(orders, orderFilter, MODE_HISTORY);

    const double maxAllowedLosses = AccountEquity() * LOSS_LIMITER_MAX_ALLOWED_LOSSES_PERCENT / 100;
    double totalLosses = 0;

    for (int order = 0; order < ArraySize(orders); order++) {
        totalLosses -= orders[order].profit;

        if (totalLosses > maxAllowedLosses) {
            deleteAllOrders();

            const string exceptionMessage = StringConcatenate(
                "Emergency switchOff invoked for total losses: ", totalLosses);

            if (UNIT_TESTS_COMPLETED) {
                ThrowFatalException(__FUNCTION__, exceptionMessage);
            } else {
                ThrowException(__FUNCTION__, exceptionMessage);
            }

            return;
        }
    }
}

/**
 * Finds the best of two orders by comparing the type and the stopLoss size. Returns true if the first one is better.
 */
bool OrderManage::findBestOrder(Order & order1, Order & order2) {
    if (order1.isOpen()) {
        return true;
    }
    if (order2.isOpen()) {
        return false;
    }

    if (order1.getStopLossPips() < order2.getStopLossPips() + SMALLER_STOPLOSS_BUFFER_PIPS) {
        return true;
    }

    return false;
}

/**
 * Delete all the orders of the current symbol and period.
 */
void OrderManage::deleteAllOrders() {
    OrderFilter orderFilter;
    orderFilter.magicNumber.add(MagicNumber());
    orderFilter.symbol.add(Symbol());

    Order orders[];
    orderFind_.getFilteredOrdersList(orders, orderFilter);

    deleteOrdersFromList(orders);
}

/**
 * Delete all the pending orders of the current symbol and period.
 */
void OrderManage::deletePendingOrders() {
    OrderFilter orderFilter;
    orderFilter.magicNumber.add(MagicNumber());
    orderFilter.symbol.add(Symbol());

    orderFilter.type.setFilterType(Exclude);
    orderFilter.type.add(OP_BUY, OP_SELL);

    Order orders[];
    orderFind_.getFilteredOrdersList(orders, orderFilter);

    deleteOrdersFromList(orders);
}

/**
 * Delete all the orders from a list.
 */
void OrderManage::deleteOrdersFromList(Order & orders[]) {
    for (int i = ArraySize(orders) - 1; i >= 0; i--) {
        deleteSingleOrder(orders[i]);
    }
}

/**
 * Delete a single order.
 */
void OrderManage::deleteSingleOrder(Order & order) {
    if (!UNIT_TESTS_COMPLETED) {
        // Needed for unit tests
        orderFind_.deleteMockedOrder(order);
        return;
    }

    const int ticket = order.ticket;
    bool deletedOrder = false;

    if (order.isOpen()) {
        deletedOrder = OrderClose(ticket, order.lots, order.closePrice, 3);
    } else {
        deletedOrder = OrderDelete(ticket);
    }

    const int lastError = GetLastError();
    const string errorMessage = StringConcatenate("Error ", lastError, " when trying to delete order: ", ticket);

    if (deletedOrder) {
        Print(__FUNCTION__, MESSAGE_SEPARATOR, "Deleted order: ", ticket);
    } else if (lastError != ERR_INVALID_TRADE_PARAMETERS) {
        // ERR_INVALID_TRADE_PARAMETERS happens when the order has already been deleted by another bot
        ThrowException(__FUNCTION__, errorMessage);
    }
}
