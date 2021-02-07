#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "Array.mqh"


/**
 * This class represents a map object, where entries are associative, with a key and a value.
 * It is not based on an hash function, and accessing elements costs O(N),
 * but the maps needed by the bot should be small enough for it to not be a problem.
 */
template <typename K, typename V> class Map {
    public:
        Map(): locked_(false) {}

        /**
         * Puts an element in the map, associating it with a specific key.
         */
        void put(K key, V value) {
            if (locked_) {
                return;
            }

            const int prevSize = ArraySize(keys);
            for (int i = 0; i < prevSize; i++) {
                if (keys[i] == key) {
                    values[i] = value;
                    return;
                }
            }

            ArrayResize(keys, prevSize + 1, 10);
            ArrayResize(values, prevSize + 1, 10);

            keys[prevSize] = key;
            values[prevSize] = value;
        }

        /**
         * Gets the value in the map associated with the given key.
         */
        V get(K key) {
            for (int i = 0; i < ArraySize(keys); i++) {
                if (keys[i] == key) {
                    return values[i];
                }
            }
            return NULL;
        }

        /**
         * Gets the key in the map that is at the given index.
         */
        K getKeys(int i) {
            if (i < ArraySize(keys)) {
                return keys[i];
            }
            return NULL;
        }

        /**
         * Gets the value in the map that is at the given index.
         */
        V getValues(int i) {
            if (i < ArraySize(values)) {
                return values[i];
            }
            return NULL;
        }

        /**
         * Returns true if the map contains the specified key.
         */
        bool containsKey(K key) {
            for (int i = 0; i < ArraySize(keys); i++) {
                if (keys[i] == key) {
                    return true;
                }
            }
            return false;
        }

        /**
         * Returns true if the map contains the specified value.
         */
        bool containsValue(V value) {
            for (int i = 0; i < ArraySize(values); i++) {
                if (values[i] == value) {
                    return true;
                }
            }
            return false;
        }

        /**
         * Returns the number of keys in the map.
         */
        int size() {
            return ArraySize(keys);
        }

        /**
         * Allows to lock the map and disable modifications. It acts like a "const".
         */
        void lock() {
            locked_ = true;
        }

        /**
         * Removes from the map the element with the specified key.
         */
        void remove(K key) {
            if (locked_) {
                return;
            }

            for (int i = 0; i < ArraySize(keys); i++) {
                if (keys[i] == key) {
                    ArrayRemove(keys, i);
                    ArrayRemove(values, i);
                    return;
                }
            }
        }

    private:
        K keys[];
        V values[];

        bool locked_;
};
