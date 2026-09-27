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

  test('calculateTriggerCorrelations finds co-occurring trigger pairs', () {
    final entries = [
      MigraineEntry(
        date: DateTime(2026, 9, 1),
        hadMigraine: true,
        intensity: 7,
        painkillers: true,
        notes: '',
        causes: ['Stress', 'Lack of sleep'],
      ),
      MigraineEntry(
        date: DateTime(2026, 9, 3),
        hadMigraine: true,
        intensity: 8,
        painkillers: true,
        notes: '',
        causes: ['Stress', 'Lack of sleep', 'Weather'],
      ),
      MigraineEntry(
        date: DateTime(2026, 9, 5),
        hadMigraine: true,
        intensity: 5,
        painkillers: false,
        notes: '',
        causes: ['Stress'],
      ),
    ];

    final correlations = calculateTriggerCorrelations(entries);
    expect(correlations.isNotEmpty, isTrue);
    final top = correlations.first;
    expect(top.causeA, 'Lack of sleep');
    expect(top.causeB, 'Stress');
    expect(top.coOccurrences, 2);
    expect(top.correlationPercent, 100.0);
  });

  test('calculateTriggerRiskMultipliers calculates intensity delta per cause', () {
    final entries = [
      MigraineEntry(
        date: DateTime(2026, 9, 1),
        hadMigraine: true,
        intensity: 9,
        painkillers: true,
        notes: '',
        causes: ['Stress'],
      ),
      MigraineEntry(
        date: DateTime(2026, 9, 3),
        hadMigraine: true,
        intensity: 3,
        painkillers: false,
        notes: '',
        causes: ['Food'],
      ),
    ];

    final multipliers = calculateTriggerRiskMultipliers(entries);
    expect(multipliers.length, 2);
    final stress = multipliers.firstWhere((m) => m.cause == 'Stress');
    expect(stress.avgIntensityWith, 9.0);
    expect(stress.avgIntensityWithout, 3.0);
    expect(stress.intensityDelta, 6.0);
  });

  test('calculateCycleIntervalMetrics calculates periodicity and regularity', () {
    final entries = [
      MigraineEntry(
        date: DateTime(2026, 9, 1),
        hadMigraine: true,
        intensity: 6,
        painkillers: false,
        notes: '',
        causes: [],
      ),
      MigraineEntry(
        date: DateTime(2026, 9, 5), // gap 4d
        hadMigraine: true,
        intensity: 7,
        painkillers: false,
        notes: '',
        causes: [],
      ),
      MigraineEntry(
        date: DateTime(2026, 9, 10), // gap 5d
        hadMigraine: true,
        intensity: 5,
        painkillers: false,
        notes: '',
        causes: [],
      ),
    ];

    final metrics = calculateCycleIntervalMetrics(entries);
    expect(metrics.intervalCount, 2);
    expect(metrics.meanIntervalDays, 4.5);
    expect(metrics.minIntervalDays, 4);
    expect(metrics.maxIntervalDays, 5);
    expect(metrics.intervals4to7Days, 2);
  });

  test('calculateWeekdayDistribution counts day of week attacks and peak', () {
    // 2026-09-06 is Sunday, 2026-09-07 is Monday
    final entries = [
      MigraineEntry(
        date: DateTime(2026, 9, 6),
        hadMigraine: true,
        intensity: 7,
        painkillers: false,
        notes: '',
        causes: [],
      ),
      MigraineEntry(
        date: DateTime(2026, 9, 7),
        hadMigraine: true,
        intensity: 8,
        painkillers: false,
        notes: '',
        causes: [],
      ),
      MigraineEntry(
        date: DateTime(2026, 9, 13), // Sunday
        hadMigraine: true,
        intensity: 6,
        painkillers: false,
        notes: '',
        causes: [],
      ),
    ];

    final dist = calculateWeekdayDistribution(entries);
    expect(dist.peakDayName, 'Sunday');
    expect(dist.peakDayCount, 2);
    expect(dist.isWeekendPeak, isTrue);
  });

  test('calculateSeverityDistribution brackets mild, moderate, severe', () {
    final entries = [
      entry(DateTime(2026, 9, 1), 2), // mild
      entry(DateTime(2026, 9, 2), 5), // moderate
      entry(DateTime(2026, 9, 3), 8), // severe
    ];

    final dist = calculateSeverityDistribution(entries);
    expect(dist.mildCount, 1);
    expect(dist.moderateCount, 1);
    expect(dist.severeCount, 1);
    expect(dist.totalCount, 3);
  });

  test('calculateMedicationRisk flags MOH risk on 10+ medication days', () {
    final entries = List.generate(11, (i) {
      return MigraineEntry(
        date: DateTime(2026, 9, i + 1),
        hadMigraine: true,
        intensity: 6,
        painkillers: true,
        notes: '',
        causes: [],
      );
    });

    final risk = calculateMedicationRisk(
      entries,
      DateTime(2026, 9),
      now: DateTime(2026, 9, 15),
    );
    expect(risk.riskLevel, MedicationOveruseLevel.high);
    expect(risk.medicationDaysThisMonth, 11);
  });
}
