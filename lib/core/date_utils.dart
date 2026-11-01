/// 日期只保留年月日，全应用统一使用本地时区。
DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _two(int value) => value.toString().padLeft(2, '0');

String dateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${_two(value.month)}-${_two(value.day)}';

DateTime? tryParseDateKey(String? value) {
  if (value == null) return null;
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value.trim());
  if (match == null) return null;
  final year = int.tryParse(match.group(1)!);
  final month = int.tryParse(match.group(2)!);
  final day = int.tryParse(match.group(3)!);
  if (year == null || month == null || day == null) return null;
  final parsed = DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return null;
  }
  return parsed;
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool isFutureDay(DateTime value, {DateTime? now}) =>
    dateOnly(value).isAfter(dateOnly(now ?? DateTime.now()));

String monthLabel(DateTime month) => '${month.year} 年 ${month.month} 月';

String fullDateLabel(DateTime date) =>
    '${date.year} 年 ${date.month} 月 ${date.day} 日';

String editorDateLabel(DateTime date, {DateTime? now}) {
  if (isSameDay(date, now ?? DateTime.now())) {
    return '今天 · ${date.month} 月 ${date.day} 日';
  }
  return fullDateLabel(date);
}

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// 周一起始：周一返回 0，周日返回 6。
int leadingDayCount(int year, int month) =>
    DateTime(year, month, 1).weekday - DateTime.monday;

const List<String> weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

String exportDateStamp(DateTime now) =>
    '${now.year}${_two(now.month)}${_two(now.day)}';

String monthStamp(DateTime month) => '${month.year}${_two(month.month)}';

String yearMonthStamp(DateTime month) => '${month.year}-${_two(month.month)}';
