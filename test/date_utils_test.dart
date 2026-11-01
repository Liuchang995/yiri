import 'package:flutter_test/flutter_test.dart';
import 'package:yiri/core/date_utils.dart';

void main() {
  test('date key normalizes and parses', () {
    expect(dateKey(DateTime(2025, 6, 2, 23, 59)), '2025-06-02');
    expect(tryParseDateKey('2025-06-02'), DateTime(2025, 6, 2));
    expect(tryParseDateKey('2025-02-30'), isNull);
    expect(tryParseDateKey('not-a-date'), isNull);
    expect(() => tryParseDateKey(null), returnsNormally);
  });

  test('month calculations use Monday-first grid', () {
    expect(daysInMonth(2024, 2), 29);
    expect(daysInMonth(2025, 2), 28);
    // 2025-06-01 is a Sunday, so there are six leading blanks.
    expect(leadingDayCount(2025, 6), 6);
    expect(weekdayLabels, ['一', '二', '三', '四', '五', '六', '日']);
  });

  test('labels and future checks', () {
    final date = DateTime(2025, 6, 12);
    expect(monthLabel(date), '2025 年 6 月');
    expect(fullDateLabel(date), '2025 年 6 月 12 日');
    expect(
      editorDateLabel(date, now: DateTime(2025, 6, 12, 8)),
      '今天 · 6 月 12 日',
    );
    expect(isFutureDay(DateTime(2025, 6, 13), now: date), isTrue);
    expect(isFutureDay(DateTime(2025, 6, 12), now: date), isFalse);
  });
}
