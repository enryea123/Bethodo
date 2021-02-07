#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../UnitTest.mqh"
#include "../../src/util/Array.mqh"


class ArrayTest {
    public:
        void arrayTest();
};

void ArrayTest::arrayTest() {
    UnitTest unitTest("arrayTest");

    int array1[] = {1, 2, 3, 4};
    int array2[];

    ArrayCopyClass(array2, array1);

    unitTest.assertEquals(
        ArraySize(array1),
        ArraySize(array2)
    );

    unitTest.assertEquals(
        (int) array1[1],
        (int) array2[1]
    );

    ArrayRemove(array2, 1);

    unitTest.assertEquals(
        ArraySize(array1) - 1,
        ArraySize(array2)
    );

    unitTest.assertEquals(
        (int) array1[3],
        (int) array2[1]
    );

    ArrayRemoveOrdered(array2, 0);

    unitTest.assertEquals(
        ArraySize(array1) - 2,
        ArraySize(array2)
    );

    unitTest.assertEquals(
        (int) array1[2],
        (int) array2[1]
    );
}
