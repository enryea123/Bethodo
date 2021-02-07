#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../src/util/Exception.mqh"


/**
 * This class represents a framework for unit tests.
 */
class UnitTest {
    public:
        UnitTest(string);
        ~UnitTest();

        template <typename T> bool assertEquals(T, T, string);
        template <typename T> bool assertEquals(T &, T &, string);
        template <typename T> bool assertEquals(T & [], T & [], string);
        template <typename T> bool assertNotEquals(T, T, string);
        template <typename T> bool assertNotEquals(T &, T &, string);
        bool assertTrue(bool, string);
        bool assertFalse(bool, string);

        bool hasDateDependentTestExpired(datetime);

    private:
        uint passedAssertions_;
        uint totalAssertions_;
        string testName_;

        template <typename T> bool setFailure(T, T, string);
        bool setSuccess(string);
        void getTestResult();
};

UnitTest::UnitTest(string testName):
    testName_(testName),
    passedAssertions_(0),
    totalAssertions_(0) {
}

UnitTest::~UnitTest() {
    getTestResult();
}

/**
 * Asserts that two given values are equal.
 */
template <typename T> bool UnitTest::assertEquals(T expected, T actual, string message = NULL) {
    if (expected == actual) {
        return setSuccess(message);
    } else {
        return setFailure(expected, actual, message);
    }
}

/**
 * Asserts that two given objects are equal.
 */
template <typename T> bool UnitTest::assertEquals(T & expected, T & actual, string message = NULL) {
    if (expected == actual) {
        return setSuccess(message);
    } else {
        return setFailure(expected.toString(), actual.toString(), message);
    }
}

/**
 * Asserts that two given arrays are equal.
 */
template <typename T> bool UnitTest::assertEquals(T & expected[], T & actual[], string message = NULL) {
    if (!assertEquals(StringConcatenate("size: ", ArraySize(expected)),
        StringConcatenate("size: ", ArraySize(actual)), message)) {
        return false;
    }

    for (int i = 0; i < ArraySize(expected); i++) {
        if (!assertEquals(expected[i], actual[i], message)) {
            return false;
        }
    }

    return setSuccess(message);
}

/**
 * Asserts that two given values are not equal.
 */
template <typename T> bool UnitTest::assertNotEquals(T expected, T actual, string message = NULL) {
    if (expected != actual) {
        return setSuccess(message);
    } else {
        return setFailure(expected, actual, message);
    }
}

/**
 * Asserts that two given objects are not equal. Assumes the objects have a toString method.
 */
template <typename T> bool UnitTest::assertNotEquals(T & expected, T & actual, string message = NULL) {
    if (expected != actual) {
        return setSuccess(message);
    } else {
        return setFailure(expected.toString(), actual.toString(), message);
    }
}

/**
 * Asserts that a condition is true.
 */
bool UnitTest::assertTrue(bool condition, string message = NULL) {
    if (condition) {
        return setSuccess(message);
    } else {
        return setFailure("true", "false", message);
    }
}

/**
 * Asserts that a condition is false.
 */
bool UnitTest::assertFalse(bool condition, string message = NULL) {
    if (!condition) {
        return setSuccess(message);
    } else {
        return setFailure("false", "true", message);
    }
}

/**
 * Checks if a unit test that depends on an hardcoded date has expired.
 */
bool UnitTest::hasDateDependentTestExpired(datetime expiration) {
    if (TimeGMT() > expiration) {
        return ThrowException(true, __FUNCTION__, StringConcatenate("Skipped expired test: ", testName_));
    }

    return false;
}

/**
 * Sets the failure scenario for unit tests, in case one or more assertions failed.
 */
template <typename T> bool UnitTest::setFailure(T expected, T actual, string message = NULL) {
    totalAssertions_++;
    Print("Assertion failed");

    if (message != NULL && message != "") {
        Print("Assertion failure message: ", message);
    }

    Print("Expected <", expected, "> Actual <", actual, ">");

    return false;
}

/**
 * Sets the success scenario for unit tests, in case all assertions succeeded.
 */
bool UnitTest::setSuccess(string message = NULL) {
    passedAssertions_++;
    totalAssertions_++;

    if (IS_DEBUG && message != NULL && message != "") {
        Print("Assertion succeeded: ", message);
    }

    return true;
}

/**
 * Wraps up the test when the destructor is invoked, and removes the bot in case of failure.
 */
void UnitTest::getTestResult() {
    const string baseMessage = StringConcatenate("UnitTest ", testName_,
        " %s with ", passedAssertions_, "/", totalAssertions_);

    if (passedAssertions_ == totalAssertions_) {
        Print(StringFormat(baseMessage, "PASSED"));
    } else {
        Alert(StringFormat(baseMessage, "FAILED"));
    }
}
