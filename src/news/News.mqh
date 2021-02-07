#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"


/**
 * This class is an interface for market news. It provides basic attributes
 * and a few methods that allow to get extra information on the news.
 */
class News {
    public:
        News();

        string title;
        string country;
        string impact;
        datetime date;

        bool operator == (const News &);
        bool operator != (const News &);

        string toString();
};

News::News():
    title(NULL),
    country(NULL),
    impact(NULL),
    date(-1) {
}

bool News::operator == (const News & v) {
    return (
        title == v.title &&
        country == v.country &&
        impact == v.impact &&
        date == v.date
    );
}

bool News::operator != (const News & v) {
    return !(this == v);
}

/**
 * Returns all the news information as string, so that it can be printed.
 */
string News::toString() {
    return StringConcatenate("NewsInfo", MESSAGE_SEPARATOR,
        "title: ", title, ", "
        "country: ", country, ", "
        "impact: ", impact, ", "
        "date: ", date
    );
}
