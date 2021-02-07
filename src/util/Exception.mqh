#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"


/**
 * Allows to throw an exception by producing an alert and returning a particular error value.
 */
template <typename T> T ThrowException(T returnValue, string function, string message) {
    ThrowException(function, message);
    return returnValue;
}

/**
 * Allows to throw an exception by producing an alert.
 */
void ThrowException(string function, string message) {
    OptionalAlert(StringConcatenate(function, MESSAGE_SEPARATOR, "ThrowException: ", message));
}

/**
 * Allows to throw a fatal exception that will interrupt the program,
 * and to produde an alert and return a particular error value.
 */
template <typename T> T ThrowFatalException(T returnValue, string function, string message) {
    ThrowFatalException(function, message);
    return returnValue;
}

/**
 * Allows to throw a fatal exception that will interrupt the program and remove the bot.
 */
void ThrowFatalException(string function, string message) {
    Alert(buildAlertMessage(StringConcatenate(function, MESSAGE_SEPARATOR, "ThrowFatalException: ", message)));
    ExpertRemove();
}

/**
 * Allows to print information based on a timeStamp, so that the information can be printed once per time interval.
 */
datetime PrintTimer(datetime timeStamp, string message) {
    if (timeStamp != Time[0]) {
        if (UNIT_TESTS_COMPLETED || IS_DEBUG) {
            Print(message);
        }
        timeStamp = Time[0];
    }

    return timeStamp;
}

/**
 * Allows to alert information based on a timeStamp, so that the information can be alerted once per time interval.
 */
datetime AlertTimer(datetime timeStamp, string message) {
    if (timeStamp != Time[0]) {
        OptionalAlert(message);
        timeStamp = Time[0];
    }

    return timeStamp;
}

/**
 * Produces an alert only if the unit tests have already been completed.
 */
void OptionalAlert(string message) {
    if (UNIT_TESTS_COMPLETED) {
        Alert(buildAlertMessage(message));
    } else if (IS_DEBUG) {
        Print(message);
    }
}

/**
 * Enriches an alert message by adding information on the symbol and period.
 */
string buildAlertMessage(string message) {
    return StringConcatenate(Symbol(), NAME_SEPARATOR, Period(), MESSAGE_SEPARATOR, message);
}
