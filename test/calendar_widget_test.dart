import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yiri/core/app_theme.dart';
import 'package:yiri/core/date_utils.dart';
import 'package:yiri/data/database/diary_repository.dart';
import 'package:yiri/features/calendar/calendar_page.dart';
import 'package:yiri/models/diary_entry.dart';

void main() {
  testWidgets('日历渲染月份、周一起始与空状态', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          diaryEntriesProvider.overrideWith(
            (ref) => Stream<List<DiaryEntry>>.value(const []),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const CalendarPage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(monthLabel(DateTime.now())), findsOneWidget);
    expect(find.text('一'), findsOneWidget);
    expect(find.text('日'), findsOneWidget);
    expect(find.text('从今天开始，留一页给自己'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
  });
}
