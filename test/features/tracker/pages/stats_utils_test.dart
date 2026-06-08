import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/tracker/models/migraine_entry.dart';
import 'package:migraine_tracker/features/tracker/pages/_utils/stats_utils.dart';

MigraineEntry entry(DateTime date, int intensity) {
  return MigraineEntry(
    date: date,
    hadMigraine: true,
    intensity: intensity,
    painkillers: false,
    notes: '',
    causes: const [],
  );
}

void main() {
  test('does not infer a trend during the first seven days', () {
    final comparison = buildMonthlyProgressComparison(
      allEntries: [
        entry(DateTime(2026, 6, 2), 3),
        entry(DateTime(2026, 6, 4), 4),
        entry(DateTime(2026, 5, 2), 7),
        entry(DateTime(2026, 5, 4), 8),
      ],
      selectedMonth: DateTime(2026, 6),
      now: DateTime(2026, 6, 5),
    );

    expect(comparison.status, MonthlyProgressStatus.insufficient);
    expect(comparison.title, 'Too early to compare');
  });

  test('compares only matching elapsed days and reports improvement', () {
    final comparison = buildMonthlyProgressComparison(
      allEntries: [
        entry(DateTime(2026, 6, 2), 3),
        entry(DateTime(2026, 6, 7), 4),
        entry(DateTime(2026, 5, 1), 7),
        entry(DateTime(2026, 5, 4), 8),
        entry(DateTime(2026, 5, 8), 6),
        entry(DateTime(2026, 5, 20), 10),
      ],
      selectedMonth: DateTime(2026, 6),
      now: DateTime(2026, 6, 8),
    );

    expect(comparison.status, MonthlyProgressStatus.better);
    expect(comparison.currentCount, 2);
    expect(comparison.previousCount, 3);
    expect(comparison.previousAverage, 7);
  });

  test('keeps conflicting frequency and intensity changes mixed', () {
    final comparison = buildMonthlyProgressComparison(
      allEntries: [
        entry(DateTime(2026, 6, 2), 3),
        entry(DateTime(2026, 6, 5), 3),
        entry(DateTime(2026, 6, 8), 3),
        entry(DateTime(2026, 5, 2), 7),
        entry(DateTime(2026, 5, 5), 7),
      ],
      selectedMonth: DateTime(2026, 6),
      now: DateTime(2026, 6, 8),
    );

    expect(comparison.status, MonthlyProgressStatus.mixed);
  });
}
