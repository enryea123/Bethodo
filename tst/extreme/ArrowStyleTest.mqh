#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../UnitTest.mqh"
#include "../../src/extreme/ArrowStyle.mqh"


class ArrowStyleTest: public ArrowStyle {
    public:
        void drawExtremeArrowTest();
};

void ArrowStyleTest::drawExtremeArrowTest() {
    UnitTest unitTest("drawExtremeArrowTest");

    drawExtremeArrow(10, Max, true);
    drawExtremeArrow(5, Min, false);

    unitTest.assertTrue(
        ObjectFind("Arrow_10_Max_Valid") >= 0
    );

    unitTest.assertEquals(
        clrOrange,
        (color) ObjectGet("Arrow_10_Max_Valid", OBJPROP_COLOR)
    );

    unitTest.assertTrue(
        ObjectFind("Arrow_5_Min") >= 0
    );

    unitTest.assertEquals(
        clrRed,
        (color) ObjectGet("Arrow_5_Min", OBJPROP_COLOR)
    );

    ObjectDelete("Arrow_10_Max_Valid");
    ObjectDelete("Arrow_5_Min");
}
