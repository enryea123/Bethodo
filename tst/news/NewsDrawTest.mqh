#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../UnitTest.mqh"
#include "../../src/news/NewsDraw.mqh"
#include "../../src/news/News.mqh"


class NewsDrawTest: public NewsDraw {
    public:
        void isNewsTimeWindowTest();
};

void NewsDrawTest::isNewsTimeWindowTest() {
    UnitTest unitTest("isNewsTimeWindowTest");


    News news;
    news.title = "Fake news for NewsDrawTest";
    news.country = Symbol();
    news.impact = "High";
    news.date = (datetime) "2020-04.07 13:50";

    drawSingleNewsLine(news);

    unitTest.assertTrue(
        isNewsTimeWindow((datetime) "2020-04.07 13:50")
    );

    unitTest.assertFalse(
        isNewsTimeWindow((datetime) "2020-04.07 12:45")
    );

    unitTest.assertTrue(
        isNewsTimeWindow((datetime) "2020-04.07 12:55")
    );

    unitTest.assertFalse(
        isNewsTimeWindow((datetime) "2020-04.07 14:55")
    );

    unitTest.assertTrue(
        isNewsTimeWindow((datetime) "2020-04.07 14:45")
    );

    ObjectsDeleteAll();

    news.impact = "CIAO";
    drawSingleNewsLine(news);

    unitTest.assertFalse(
        isNewsTimeWindow((datetime) "2020-04.07 13:50")
    );

    ObjectsDeleteAll();
}
