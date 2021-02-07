#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "Order.mqh"
#include "OrderFilter.mqh"


/**
 * This class allows to find orders and to filter them based on some attributes.
 * It also allows to mock orders to improve unit tests functionalities.
 */
class OrderFind {
    public:
        void getFilteredOrdersList(Order & [], OrderFilter &, int);
        void getOrdersList(Order & [], int);

        void setMockedOrders(Order &);
        void setMockedOrders(Order & []);
        void getMockedOrders(Order & []);
        void deleteMockedOrder(Order &);
        void deleteAllMockedOrders();

    private:
        Order mockedOrders_[];
};

/**
 * Gets a list of orders in a pool, filtered based on the provided filter.
 */
void OrderFind::getFilteredOrdersList(Order & orders[], OrderFilter & orderFilter, int pool = MODE_TRADES) {
    getOrdersList(orders, pool);

    for (int i = ArraySize(orders) - 1; i >= 0; i--) {
        if (orderFilter.closeTime.get(orders[i].closeTime) ||
            orderFilter.magicNumber.get(orders[i].magicNumber) ||
            orderFilter.profit.get(orders[i].profit) ||
            orderFilter.symbol.get(orders[i].symbol) ||
            orderFilter.symbolFamily.get(SymbolFamily(orders[i].symbol)) ||
            orderFilter.type.get(orders[i].type)) {
            ArrayRemove(orders, i);
        }
    }
}

/**
 * Gets the list of all the orders beloning to a certain pool. The default pool is opened or pending orders.
 */
void OrderFind::getOrdersList(Order & orders[], int pool = MODE_TRADES) {
    if (ArraySize(mockedOrders_) > 0 && !UNIT_TESTS_COMPLETED) {
        getMockedOrders(orders);
        return;
    }

    const int previouslySelectedOrder = OrderTicket();

    if (pool != MODE_TRADES && pool != MODE_HISTORY) {
        ThrowException(__FUNCTION__, StringConcatenate("Unsupported pool: ", pool));
        return;
    }

    const bool isModeTrades = (pool == MODE_TRADES);

    const int poolOrders = isModeTrades ? OrdersTotal() : OrdersHistoryTotal();
    const int baseArraySize = isModeTrades ? 10 : 500;
    ArrayResize(orders, baseArraySize, baseArraySize);

    int index = 0;
    for (int order = poolOrders - 1; order >= 0; order--) {
        if (!OrderSelect(order, SELECT_BY_POS, pool)) {
            continue;
        }

        ArrayResize(orders, index + 1, baseArraySize);
        orders[index].magicNumber = OrderMagicNumber();
        orders[index].ticket = OrderTicket();
        orders[index].type = OrderType();
        orders[index].lots = OrderLots();
        orders[index].openPrice = OrderOpenPrice();
        orders[index].closePrice = OrderClosePrice();
        orders[index].profit = OrderProfit();
        orders[index].stopLoss = OrderStopLoss();
        orders[index].takeProfit = OrderTakeProfit();
        orders[index].comment = OrderComment();
        orders[index].symbol = OrderSymbol();
        orders[index].openTime = OrderOpenTime();
        orders[index].closeTime = OrderCloseTime();
        orders[index].expiration = OrderExpiration();
        index++;
    }

    ArrayResize(orders, index);

    const bool selectSucceeded = OrderSelect(previouslySelectedOrder, SELECT_BY_TICKET);
    const int lastError = GetLastError();
    if (previouslySelectedOrder != 0 && !selectSucceeded && lastError != 4051) {
        ThrowException(__FUNCTION__, StringConcatenate(
            "Could not select back previous order: ", previouslySelectedOrder, ", error: ", lastError));
    }
}

/**
 * Allows to create one mocked order.
 */
void OrderFind::setMockedOrders(Order & order) {
    ArrayResize(mockedOrders_, 1);
    mockedOrders_[0] = order;
}

/**
 * Allows to create a list of mocked orders.
 */
void OrderFind::setMockedOrders(Order & orders[]) {
    ArrayCopyClass(mockedOrders_, orders);
}

/**
 * Allows to get the list of mocked orders.
 */
void OrderFind::getMockedOrders(Order & orders[]) {
    ArrayCopyClass(orders, mockedOrders_);
}

/**
 * Allows to delete a mocked order.
 */
void OrderFind::deleteMockedOrder(Order & order) {
    for (int i = 0; i < ArraySize(mockedOrders_); i++) {
        if (mockedOrders_[i] == order) {
            ArrayRemove(mockedOrders_, i);
            return;
        }
    }
}

/**
 * Allows to delete all mocked order.
 */
void OrderFind::deleteAllMockedOrders() {
    ArrayFree(mockedOrders_);
}
