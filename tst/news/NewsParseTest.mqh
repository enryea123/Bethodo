#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../UnitTest.mqh"
#include "../../src/news/News.mqh"
#include "../../src/news/NewsParse.mqh"


class NewsParseTest: public NewsParse {
    public:
        NewsParseTest();
        ~NewsParseTest();

        void readNewsFromCalendarTest();
        void parseDateTest();

};

NewsParseTest::NewsParseTest() {
    deleteTestCalendarFile();
}

NewsParseTest::~NewsParseTest() {
    if (!IS_DEBUG) {
        deleteTestCalendarFile();
    }
}

void NewsParseTest::readNewsFromCalendarTest() {
    UnitTest unitTest("readNewsFromCalendarTest");

    News news[];
    readNewsFromCalendar(news);

    unitTest.assertEquals(
        0,
        ArraySize(news)
    );

    createTestCalendarFileBadHeader();
    ArrayFree(news);
    readNewsFromCalendar(news);

    unitTest.assertEquals(
        0,
        ArraySize(news)
    );

    News testNews;
    testNews.title = "Invented stuff 1";
    testNews.country = "EUR";
    testNews.impact = "High";
    testNews.date = (datetime) "2020.12.30 10:00";

    createTestCalendarFile();
    ArrayFree(news);
    readNewsFromCalendar(news);

    unitTest.assertEquals(
        8,
        ArraySize(news)
    );
    unitTest.assertEquals(
        testNews,
        news[0]
    );

    unitTest.assertEquals(
        "CIAO",
        news[1].country
    );

    unitTest.assertEquals(
        "Medium",
        news[2].impact
    );

    unitTest.assertEquals(
        (datetime) 0,
        news[6].date
    );
}

void NewsParseTest::parseDateTest() {
    UnitTest unitTest("parseDateTest");

    unitTest.assertEquals(
        (datetime) "2020.12.27 22:34",
        parseDate("12-27-2020", "9:34pm")
    );

    unitTest.assertEquals(
        (datetime) "2020.12.27 10:12",
        parseDate("12-27-2020", "9:12am")
    );

    unitTest.assertEquals(
        (datetime) "2020.12.27 01:00",
        parseDate("12-27-2020", "12:00am")
    );

    unitTest.assertEquals(
        (datetime) "2020.12.27 13:10",
        parseDate("12-27-2020", "12:10pm")
    );

    unitTest.assertEquals(
        (datetime) "2020.12.27 00:30",
        parseDate("12-26-2020", "11:30pm")
    );

    unitTest.assertEquals(
        (datetime) 0,
        parseDate("2020-12-27", "1:00pm")
    );

    unitTest.assertEquals(
        (datetime) "2020.12.27 23:00",
        parseDate("12-27-2020", "22:00am")
    );

    unitTest.assertEquals(
        (datetime) "2020.12.27 11:00",
        parseDate("12-27-2020", "10:00")
    );

    unitTest.assertEquals(
        (datetime) "2020.12.27 15:59:00",
        parseDate("12-27-2020", "2:99pm")
    );

    unitTest.assertEquals(
        (datetime) "2020.12.27 12:00",
        parseDate("12-27-2020", "-11:00am")
    );

    unitTest.assertEquals(
        (datetime) "2020.12.28",
        parseDate("12-27-2020", "-11:00pm")
    );

    unitTest.assertEquals(
        (datetime) 0,
        parseDate("12-27-0", "9:00am")
    );

    unitTest.assertEquals(
        (datetime) 0,
        parseDate("12-27-2020", "900am")
    );

    unitTest.assertEquals(
        (datetime) 0,
        parseDate("12-27.2020", "9:00am")
    );

    unitTest.assertEquals(
        (datetime) 0,
        parseDate("12-27--0", "9:00am")
    );
}
