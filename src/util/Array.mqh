#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict


/**
 * Implementation of ArrayCopy for class Objects that are passed by reference.
 */
template <typename T> void ArrayCopyClass(T & destination[], T & source[]) {
    ArrayResize(destination, ArraySize(source));

    for (int i = 0; i < ArraySize(source); i++) {
        destination[i] = source[i];
    }
}

/**
 * Removes one element from an array, by replacing it with the last one.
 */
template <typename T> void ArrayRemove(T & array[], int index) {
    int last = ArraySize(array) - 1;

    if (last <= 0) {
        ArrayFree(array);
    } else {
        array[index] = array[last];
        ArrayResize(array, last);
    }
}

/**
 * Removes one element from an array, keeping the order of all the successive elements.
 */
template <typename T> void ArrayRemoveOrdered(T & array[], int index) {
    int last = ArraySize(array) - 1;

    for(int i = index; i < last; i++) {
        array[i] = array[i + 1];
    }

    if (last <= 0) {
        ArrayFree(array);
    } else {
        ArrayResize(array, last);
    }
}
