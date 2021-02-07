#property copyright "2021 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "../market/MarketTime.mqh"
#include "../util/Exception.mqh"
#include "../util/Util.mqh"
#include "News.mqh"


/**
 * This class retrieves market news information from a calendar file and processes it, to determine when
 * the market should be closed because of a news. The calendar file is located in the MQL4/Files directory
 * of MetaTrader, and is downloaded periodically from ForexFactory. The file can be downloaded manually,
 * or by using the script below, which needs to be externally set up to run on the computer running
 * the MetaTrader terminal. If no file is found, no news information is processed.
 *
 * cd "/home/enry/.wine/drive_c/Program Files"; rm -rf ff_calendar_thisweek.csv;
 * wget https://cdn-nfs.faireconomy.media/ff_calendar_thisweek.csv;
 * for folder in MT4-*; do cp ff_calendar_thisweek.csv $folder/MQL4/Files/; done;
 * rm -rf ff_calendar_thisweek.csv;
 */
class NewsParse {
    public:
        void readNewsFromCalendar(News & []);

    protected:
        datetime parseDate(string, string);

        void createTestCalendarFile();
        void createTestCalendarFileBadHeader();
        void deleteTestCalendarFile();
        string buildTestCalendarFileName();
};

/**
 * Reads the local csv calendar file and parses its lines into an array of News objects.
 */
void NewsParse::readNewsFromCalendar(News & news[]) {
    const string calendarFile = (UNIT_TESTS_COMPLETED) ? CALENDAR_FILE : buildTestCalendarFileName();

    if (!FileIsExist(calendarFile)) {
        return;
    }

    int fileHandle = INVALID_HANDLE;

    const int maxAttempts = 10;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
        ResetLastError();

        fileHandle = FileOpen(calendarFile, FILE_READ|FILE_TXT);

        const int lastError = GetLastError();

        if (fileHandle != INVALID_HANDLE && lastError == 0) {
            break;
        } else if (lastError != ERR_FILE_CANNOT_OPEN) {
            // ERR_FILE_CANNOT_OPEN can happen once or twice while the file is opened by another bot
            Print("Error ", lastError, " when opening calendar file, attempt: ", attempt + 1);
        }

        Sleep(100);
    }

    if (fileHandle == INVALID_HANDLE) {
        ThrowException(__FUNCTION__, StringConcatenate("Error when opening calendar file: ", calendarFile));
        FileClose(fileHandle);
        return;
    }

    // The first line of the file is the header
    const string fileHeader = FileReadString(fileHandle);

    if (fileHeader != CALENDAR_HEADER) {
        ThrowException(__FUNCTION__, StringConcatenate("Badly formatted calendar file: ", calendarFile));
        FileClose(fileHandle);
        return;
    }

    int index = 0;

    while (!FileIsEnding(fileHandle)) {
        const string line = FileReadString(fileHandle);

        string splitLine[];
        StringSplit(line, StringGetCharacter(",", 0), splitLine);

        if (ArraySize(splitLine) == 7) {
            ArrayResize(news, index + 1, 100);
            news[index].title = splitLine[0];
            news[index].country = splitLine[1];
            news[index].impact = splitLine[4];
            news[index].date = parseDate(splitLine[2], splitLine[3]);
            index++;
        } else {
            ThrowException(__FUNCTION__, StringConcatenate("Could not parse news line: ", line));
        }
    }

    FileClose(fileHandle);
}

/**
 * Parses the date format of the csv calendar, to transform it into a datetime object in the Italian timezone.
 * It currently works for a date of the format: 12-27-2020 9:00pm.
 */
datetime NewsParse::parseDate(string date, string time) {
    const string errorMessage = StringConcatenate("Could not parse date from news line: ", date, " ", time);

    string splitDate[], splitTime[];

    StringSplit(date, StringGetCharacter("-", 0), splitDate);
    StringSplit(time, StringGetCharacter(":", 0), splitTime);

    if (ArraySize(splitDate) != 3 || ArraySize(splitTime) != 2) {
        return ThrowException(0, __FUNCTION__, errorMessage);
    }

    const int year = MathAbs((int) splitDate[2]);
    const int month = MathAbs((int) splitDate[0]);
    const int day = MathAbs((int) splitDate[1]);

    int hour = MathAbs((int) splitTime[0]);
    const int minute = MathAbs((int) splitTime[1]);

    if (year == 0 || month == 0 || day == 0 || hour == 0) {
        return ThrowException(0, __FUNCTION__, errorMessage);
    }

    if (StringContains(splitTime[1], "pm") && hour < 12) {
        hour += 12;
    } else if (StringContains(splitTime[1], "am") && hour == 12) {
        hour = 0;
    }

    datetime parsedDate = (datetime) StringConcatenate(year, ".", month, ".", day, " ", hour, ":", minute);

    // Converting the date from UTC to the Italian timezone
    MarketTime marketTime;
    parsedDate += 3600 * marketTime.timeShiftInHours(marketTime.timeItaly(), TimeGMT());

    if (TimeYear(parsedDate) > Year() + 50) {
        return ThrowException(0, __FUNCTION__, errorMessage);
    }

    return parsedDate;
}

/**
 * Creates a fake calendar file to be used during unit tests.
 */
void NewsParse::createTestCalendarFile() {
    const string testCalendarFile = buildTestCalendarFileName();
    FileDelete(testCalendarFile);

    const int fileHandle = FileOpen(testCalendarFile, FILE_WRITE|FILE_TXT);

    FileWriteString(fileHandle, StringConcatenate(CALENDAR_HEADER, "\n"));
    FileWriteString(fileHandle, "Invented stuff 1,EUR,12-30-2020,9:00am,High,,\n");
    FileWriteString(fileHandle, "badly,formatted,line\n");
    FileWriteString(fileHandle, "Invented stuff 2,CIAO,12-31-2020,2:20pm,Low,1.5%,19abc\n");
    FileWriteString(fileHandle, "Invented stuff 3,GBP,12-28-2020,11:00am,Medium,,\n");
    FileWriteString(fileHandle, "Invented stuff 4,USD,12-28-2020,3:35pm,Medium,,\n");
    FileWriteString(fileHandle, "Invented stuff 5,USD,12-29-2020,4:15pm,SuperMedium,,\n");
    FileWriteString(fileHandle, ",EUR,12-29-2020,11:10am,High,,\n");
    FileWriteString(fileHandle, "Invented stuff 6,USD,2020_12_28,3:50pm,Low,,\n");
    FileWriteString(fileHandle, "Invented stuff 7,USD,12-28-2020,15:50,Low,,\n");

    FileClose(fileHandle);
}

/**
 * Creates a fake calendar file to be used during unit tests, that has a badly formatted header.
 */
void NewsParse::createTestCalendarFileBadHeader() {
    const string testCalendarFile = buildTestCalendarFileName();
    FileDelete(testCalendarFile);

    const int fileHandle = FileOpen(testCalendarFile, FILE_WRITE|FILE_TXT);

    FileWriteString(fileHandle, StringConcatenate("CiaoBadlyFormatted,Header", "\n"));
    FileWriteString(fileHandle, "Invented stuff 1,EUR,12-30-2020,9:00am,High,,\n");
    FileWriteString(fileHandle, "Invented stuff 2,CIAO,12-31-2020,2:20pm,Low,1.5%,19abc\n");
    FileWriteString(fileHandle, "Invented stuff 3,GBP,12-28-2020,11:00am,Medium,,\n");

    FileClose(fileHandle);
}

/**
 * Deletes the fake calendar file used by unit tests.
 */
void NewsParse::deleteTestCalendarFile() {
    FileDelete(buildTestCalendarFileName());
}

/**
 * Builds a testing news calendar file that is unique for the symbol and period.
 */
string NewsParse::buildTestCalendarFileName() {
    return StringConcatenate("Test", NAME_SEPARATOR, Symbol(), Period(), NAME_SEPARATOR, CALENDAR_FILE);
}
