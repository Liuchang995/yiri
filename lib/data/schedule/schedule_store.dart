import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/date_utils.dart';
import '../../data/preferences/preferences.dart';

class ScheduleItem {
  const ScheduleItem({required this.id, required this.title});

  final String id;
  final String title;

  Map<String, dynamic> toJson() => {'id': id, 'title': title};

  factory ScheduleItem.fromJson(Map<String, dynamic> json) => ScheduleItem(
    id: (json['id'] as String?) ?? '',
    title: (json['title'] as String?) ?? '',
  );
}

final scheduleStoreProvider = Provider<ScheduleStore>((ref) {
  return ScheduleStore(ref.watch(sharedPreferencesProvider));
});

class ScheduleStore {
  ScheduleStore(this.preferences);

  final SharedPreferences preferences;

  String _key(DateTime date) => 'schedules_${dateKey(date)}';

  List<ScheduleItem> read(DateTime date) {
    final raw = preferences.getString(_key(date));
    if (raw == null || raw.isEmpty) return const [];
    try {
      final value = jsonDecode(raw);
      if (value is! List) return const [];
      return value
          .whereType<Map>()
          .map((item) => ScheduleItem.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.title.trim().isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Set<String> allMarkedDates() {
    final dates = <String>{};
    for (final key in preferences.getKeys()) {
      if (!key.startsWith('schedules_') || key == 'schedules_onboarded') {
        continue;
      }
      final raw = preferences.getString(key);
      if (raw != null && raw != '[]') {
        dates.add(key.substring('schedules_'.length));
      }
    }
    return dates;
  }

  Future<void> write(DateTime date, List<ScheduleItem> items) async {
    await preferences.setString(
      _key(date),
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}
