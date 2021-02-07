#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"


enum FilterType {
    Include,
    Exclude,
    Greater,
    Smaller,
};

/**
 * This class provides a base filter that supports different types of filtering.
 */
class Filter {
    public:
        Filter(): values_(NULL), filterType_(Include) {}

        void setFilterType(FilterType filterType) {
            filterType_ = filterType;
            values_ = NULL;
        }

        /**
         * Setter and overloads.
         */
        template <typename T> void add(T v) {
            if (filterType_ == Include || filterType_ == Exclude) {
                values_ = StringConcatenate(values_, FILTER_SEPARATOR, v, FILTER_SEPARATOR);
            }
            if (filterType_ == Greater || filterType_ == Smaller) {
                values_ = (string) (double) v;
            }
        }
        template <typename T> void add(T v1, T v2) {add(v1); add(v2);}
        template <typename T> void add(T v1, T v2, T v3) {add(v1); add(v2); add(v3);}
        template <typename T> void add(T v1, T v2, T v3, T v4) {add(v1); add(v2); add(v3); add(v4);}
        template <typename T> void add(T & v[]) {for (int i = 0; i < ArraySize(v); i++) {add(v[i]);}}

        /**
         * Getter.
         */
        template <typename T> bool get(T v) {
            if (values_ == NULL) {
                return false;
            }

            if (filterType_ == Include || filterType_ == Exclude) {
                return StringContains(values_, StringConcatenate(FILTER_SEPARATOR, v, FILTER_SEPARATOR)) ?
                    !(filterType_ == Include) : (filterType_ == Include);
            }
            if (filterType_ == Greater || filterType_ == Smaller) {
                return ((double) v > (double) values_) ?
                    !(filterType_ == Greater) : (filterType_ == Greater);
            }

            return false;
        }

    private:
        string values_;
        FilterType filterType_;
};


/**
 * This class provides a set of filters for some order attributes.
 */
class OrderFilter {
    public:
        Filter closeTime;
        Filter magicNumber;
        Filter profit;
        Filter symbol;
        Filter symbolFamily;
        Filter type;
};
