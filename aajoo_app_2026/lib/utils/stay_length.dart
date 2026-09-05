/// How long a stay may run.
///
/// A booking covers at most one MONTH — the real length of the month the stay
/// STARTS in, so 31 nights from January, 30 from April, 28 from February and 29
/// in a leap year. Client rule, 2026-09-05.
///
/// The server owns this rule (utils/preBooking.js) and refuses anything longer;
/// /pricing/quote returns the number as `maxNights`. This copy exists for the
/// one place that needs the answer BEFORE any quote has been asked for: the
/// date picker, which has to stop the guest while they are still choosing.
/// Being stopped at the calendar is a rule; being refused at checkout after
/// choosing is a failure.
///
/// The same few lines exist in the website's `redesign/lib/stayLength.ts`.
/// Kept deliberately tiny and pure so three copies cannot drift in behaviour
/// even though they cannot share code across three repositories.
library;

/// Divisible by 4, except centuries that are not divisible by 400.
bool isLeapYear(int year) =>
    (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

/// How many days a month holds. [month] is 1-12.
int daysInMonth(int year, int month) {
  if (month == 2) return isLeapYear(year) ? 29 : 28;
  const lengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  if (month < 1 || month > 12) return 30;
  return lengths[month - 1];
}

/// The longest stay allowed from this check-in.
///
/// Taken from the month the stay begins in rather than counted forward, so the
/// answer is knowable the moment a check-in is picked — which is exactly when
/// the picker needs it.
int maxNightsFrom(DateTime start) => daysInMonth(start.year, start.month);

/// The latest check-out allowed for a stay starting on [start].
DateTime latestCheckout(DateTime start) =>
    DateTime(start.year, start.month, start.day + maxNightsFrom(start));

/// Human wording for the limit, shown when a guest reaches it.
String stayLimitMessage(int maxNights) =>
    'A stay can run for up to one month at a time — $maxNights nights from '
    'this check-in.';
