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
  test('does not infer a trend before seven days have elapsed', () {
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

  test('buildCalendarMonthDays generates grid with migraine markers', () {
    final entries = [
      MigraineEntry(
        date: DateTime(2026, 9, 12),
        hadMigraine: true,
        intensity: 8,
        painkillers: true,
        notes: '',
        causes: ['Stress'],
      ),
      MigraineEntry(
        date: DateTime(2026, 9, 20),
        hadMigraine: false,
        intensity: 0,
        painkillers: false,
        notes: '',
        causes: [],
      ),
    ];

    final days = buildCalendarMonthDays(
      month: DateTime(2026, 9),
      entries: entries,
      now: DateTime(2026, 9, 12),
    );

    expect(days.length % 7, 0); // Must be multiple of 7
    final sep12 = days.firstWhere(
      (d) => d.isCurrentMonth && d.date.day == 12,
    );
    expect(sep12.isToday, isTrue);
    expect(sep12.hasMigraine, isTrue);

    final sep20 = days.firstWhere(
      (d) => d.isCurrentMonth && d.date.day == 20,
    );
    expect(sep20.hasMigraine, isFalse);
  });

  test('buildCauseStats computes occurrences, percent and avg intensity', () {
    final entries = [
      MigraineEntry(
        date: DateTime(2026, 9, 2),
        hadMigraine: true,
        intensity: 6,
        painkillers: false,
        notes: '',
        causes: ['Stress', 'Lack of sleep'],
      ),
      MigraineEntry(
        date: DateTime(2026, 9, 4),
        hadMigraine: true,
        intensity: 8,
        painkillers: true,
        notes: '',
        causes: ['Stress'],
      ),
    ];

    final causes = buildCauseStats(entries);
    expect(causes.length, 2);
    expect(causes.first.label, 'Stress');
    expect(causes.first.count, 2);
    expect(causes.first.avgIntensity, 7.0);
    expect(causes[1].label, 'Lack of sleep');
    expect(causes[1].count, 1);
    expect(causes[1].avgIntensity, 6.0);
  });
}
