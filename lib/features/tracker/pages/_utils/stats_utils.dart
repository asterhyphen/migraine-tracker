import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:migraine_tracker/core/utils/date_utils.dart';
import 'package:migraine_tracker/features/tracker/models/migraine_entry.dart';

/// Data class for bar chart items.
class BarDatum {
  BarDatum(this.label, this.value);

  final String label;
  final double value;
}

/// Data class for cause statistics.
class CauseDatum {
  CauseDatum(this.label, this.count, this.total, {this.avgIntensity = 0.0});

  final String label;
  final int count;
  final int total;
  final double avgIntensity;

  double get percent => total == 0 ? 0 : count / total;
}

/// Data class for summary items.
class SummaryItem {
  SummaryItem(this.title, this.value, this.subtitle, {this.onTap});

  final String title;
  final String value;
  final String subtitle;
  final VoidCallback? onTap;
}

/// Data class for comparison items between months.
class ComparisonItem {
  ComparisonItem({
    required this.title,
    required this.selectedValue,
    required this.compareValue,
    required this.deltaLabel,
    required this.subtitle,
  });

  final String title;
  final String selectedValue;
  final String compareValue;
  final String deltaLabel;
  final String subtitle;
}

enum MonthlyProgressStatus { better, worse, steady, mixed, insufficient }

/// A conservative comparison with the same elapsed period in the prior month.
class MonthlyProgressComparison {
  const MonthlyProgressComparison({
    required this.status,
    required this.title,
    required this.message,
    required this.periodLabel,
    required this.currentCount,
    required this.previousCount,
    this.currentAverage,
    this.previousAverage,
  });

  final MonthlyProgressStatus status;
  final String title;
  final String message;
  final String periodLabel;
  final int currentCount;
  final int previousCount;
  final double? currentAverage;
  final double? previousAverage;
}

/// Compare a selected month with the equivalent elapsed days one month earlier.
///
/// Current-month comparisons wait for at least seven elapsed days. A directional
/// result also requires at least two entries in each period so that one isolated
/// migraine does not decide whether the month is better or worse.
MonthlyProgressComparison buildMonthlyProgressComparison({
  required List<MigraineEntry> allEntries,
  required DateTime selectedMonth,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final selected = DateTime(selectedMonth.year, selectedMonth.month);
  final current = DateTime(today.year, today.month);
  final previous = DateTime(selected.year, selected.month - 1);
  final isCurrentMonth = isSameMonth(selected, current);
  final elapsedDays = isCurrentMonth
      ? today.day
      : DateTime(selected.year, selected.month + 1, 0).day;
  final previousMonthDays = DateTime(previous.year, previous.month + 1, 0).day;
  final comparisonDays = elapsedDays.clamp(1, previousMonthDays);

  final selectedEntries = allEntries.where((entry) {
    return entry.hadMigraine &&
        isSameMonth(entry.date, selected) &&
        entry.date.day <= elapsedDays;
  }).toList();
  final previousEntries = allEntries.where((entry) {
    return entry.hadMigraine &&
        isSameMonth(entry.date, previous) &&
        entry.date.day <= comparisonDays;
  }).toList();

  final periodLabel = isCurrentMonth
      ? "Days 1-$comparisonDays vs ${monthLabel(previous)} 1-$comparisonDays"
      : "${monthLabelFull(selected)} vs ${monthLabelFull(previous)}";
  final selectedAverage = _averageIntensity(selectedEntries);
  final previousAverage = _averageIntensity(previousEntries);

  MonthlyProgressComparison result(
    MonthlyProgressStatus status,
    String title,
    String message,
  ) {
    return MonthlyProgressComparison(
      status: status,
      title: title,
      message: message,
      periodLabel: periodLabel,
      currentCount: selectedEntries.length,
      previousCount: previousEntries.length,
      currentAverage: selectedAverage,
      previousAverage: previousAverage,
    );
  }

  if (isCurrentMonth && elapsedDays < 7) {
    return result(
      MonthlyProgressStatus.insufficient,
      "Too early to compare",
      "A trend will appear once 7 days have elapsed, using the same days from last month.",
    );
  }
  if (selectedEntries.length < 2 || previousEntries.length < 2) {
    return result(
      MonthlyProgressStatus.insufficient,
      "Not enough comparable data",
      "At least 2 migraine entries in each period are needed for a trend.",
    );
  }

  final countDelta = selectedEntries.length - previousEntries.length;
  final intensityDelta = selectedAverage! - previousAverage!;
  final frequencySignal = countDelta.compareTo(0);
  final intensitySignal = intensityDelta.abs() < 0.5
      ? 0
      : intensityDelta.compareTo(0);
  final hasBetterSignal = frequencySignal < 0 || intensitySignal < 0;
  final hasWorseSignal = frequencySignal > 0 || intensitySignal > 0;

  if (hasBetterSignal && !hasWorseSignal) {
    return result(
      MonthlyProgressStatus.better,
      "Looking better",
      "Migraine frequency or intensity is lower, with no measured worsening.",
    );
  }
  if (hasWorseSignal && !hasBetterSignal) {
    return result(
      MonthlyProgressStatus.worse,
      "Looking worse",
      "Migraine frequency or intensity is higher, with no measured improvement.",
    );
  }
  if (!hasBetterSignal && !hasWorseSignal) {
    return result(
      MonthlyProgressStatus.steady,
      "About the same",
      "Frequency is unchanged and average intensity differs by less than 0.5.",
    );
  }
  return result(
    MonthlyProgressStatus.mixed,
    "Mixed changes",
    "Frequency and average intensity are moving in different directions.",
  );
}

double? _averageIntensity(List<MigraineEntry> entries) {
  if (entries.isEmpty) return null;
  return entries.map((entry) => entry.intensity).reduce((a, b) => a + b) /
      entries.length;
}

/// Build weekly frequency data for a month.
List<BarDatum> buildWeeklyFrequency(
  List<MigraineEntry> source,
  DateTime month,
) {
  final counts = List<int>.filled(5, 0);
  for (final entry in source) {
    if (entry.date.year != month.year || entry.date.month != month.month) {
      continue;
    }
    final bucket = ((entry.date.day - 1) / 7).floor().clamp(0, 4);
    counts[bucket] += 1;
  }
  return List<BarDatum>.generate(
    5,
    (i) => BarDatum("W${i + 1}", counts[i].toDouble()),
  );
}

/// Build weekly average intensity data for a month.
List<BarDatum> buildWeeklyAverages(List<MigraineEntry> source, DateTime month) {
  final buckets = List<List<int>>.generate(5, (_) => []);
  for (final entry in source) {
    if (entry.date.year != month.year || entry.date.month != month.month) {
      continue;
    }
    final bucket = ((entry.date.day - 1) / 7).floor().clamp(0, 4);
    buckets[bucket].add(entry.intensity);
  }
  return List<BarDatum>.generate(5, (i) {
    final values = buckets[i];
    if (values.isEmpty) return BarDatum("W${i + 1}", 0);
    final avg = values.reduce((a, b) => a + b) / values.length;
    return BarDatum("W${i + 1}", avg);
  });
}

/// Build list of available months from entries.
List<DateTime> buildMonthOptions(List<MigraineEntry> entries) {
  final set = <String, DateTime>{};
  final now = DateTime.now();
  set["${now.year}-${now.month}"] = DateTime(now.year, now.month);
  for (final e in entries) {
    final month = DateTime(e.date.year, e.date.month);
    set["${month.year}-${month.month}"] = month;
  }
  final months = set.values.toList()..sort((a, b) => b.compareTo(a));
  return months;
}

/// Validate compare month selection.
DateTime? validatedCompareMonth({
  required List<DateTime> options,
  required DateTime selectedMonth,
  required DateTime? currentCompare,
}) {
  if (currentCompare == null) {
    return null;
  }
  if (isSameMonth(currentCompare, selectedMonth)) {
    return null;
  }
  final hasCompare = options.any((month) => isSameMonth(month, currentCompare));
  return hasCompare ? currentCompare : null;
}

/// Build cause statistics from entries.
List<CauseDatum> buildCauseStats(List<MigraineEntry> source) {
  final Map<String, int> counts = {};
  final Map<String, List<int>> intensities = {};
  for (final entry in source) {
    for (final cause in entry.causes) {
      counts[cause] = (counts[cause] ?? 0) + 1;
      intensities.putIfAbsent(cause, () => []).add(entry.intensity);
    }
  }
  final total = counts.values.fold<int>(0, (sum, v) => sum + v);
  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sorted.map((e) {
    final list = intensities[e.key] ?? [];
    final avg = list.isEmpty ? 0.0 : list.reduce((a, b) => a + b) / list.length;
    return CauseDatum(e.key, e.value, total, avgIntensity: avg);
  }).toList();
}

/// Data class for a calendar day item.
class CalendarDayInfo {
  const CalendarDayInfo({
    required this.date,
    required this.isCurrentMonth,
    required this.isToday,
    this.entry,
  });

  final DateTime date;
  final bool isCurrentMonth;
  final bool isToday;
  final MigraineEntry? entry;

  bool get hasMigraine => entry != null && entry!.hadMigraine;
}

/// Build the grid of days (Monday through Sunday) for an Apple-style calendar.
List<CalendarDayInfo> buildCalendarMonthDays({
  required DateTime month,
  required List<MigraineEntry> entries,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final year = month.year;
  final m = month.month;
  final firstDayOfMonth = DateTime(year, m, 1);
  final daysInMonth = DateTime(year, m + 1, 0).day;
  final daysInPrevMonth = DateTime(year, m, 0).day;

  // Weekday: Monday is 1, Sunday is 7.
  final leadingDays = firstDayOfMonth.weekday - 1;

  final result = <CalendarDayInfo>[];

  // Map entries for quick O(1) lookup by date string 'yyyy-MM-dd'
  final entryMap = <String, MigraineEntry>{};
  for (final entry in entries) {
    final key = "${entry.date.year}-${entry.date.month}-${entry.date.day}";
    if (!entryMap.containsKey(key) ||
        (entry.hadMigraine && !entryMap[key]!.hadMigraine)) {
      entryMap[key] = entry;
    }
  }

  // Leading days from previous month
  for (int i = leadingDays - 1; i >= 0; i--) {
    final dayNum = daysInPrevMonth - i;
    final date = DateTime(year, m - 1, dayNum);
    final key = "${date.year}-${date.month}-${date.day}";
    final isTodayDate =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    result.add(
      CalendarDayInfo(
        date: date,
        isCurrentMonth: false,
        isToday: isTodayDate,
        entry: entryMap[key],
      ),
    );
  }

  // Days in current month
  for (int day = 1; day <= daysInMonth; day++) {
    final date = DateTime(year, m, day);
    final key = "${date.year}-${date.month}-${date.day}";
    final isTodayDate =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    result.add(
      CalendarDayInfo(
        date: date,
        isCurrentMonth: true,
        isToday: isTodayDate,
        entry: entryMap[key],
      ),
    );
  }

  // Trailing days from next month to complete the row (total 35 or 42 cells)
  final totalCells = result.length <= 35 ? 35 : 42;
  final trailingDays = totalCells - result.length;
  for (int day = 1; day <= trailingDays; day++) {
    final date = DateTime(year, m + 1, day);
    final key = "${date.year}-${date.month}-${date.day}";
    final isTodayDate =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    result.add(
      CalendarDayInfo(
        date: date,
        isCurrentMonth: false,
        isToday: isTodayDate,
        entry: entryMap[key],
      ),
    );
  }

  return result;
}

/// Calculate painkiller usage percentage.
double painkillerUsage(List<MigraineEntry> source) {
  if (source.isEmpty) return 0;
  final used = source.where((e) => e.painkillers).length;
  return used / source.length;
}

/// Format month as abbreviated label (e.g., "Jan").
String monthLabel(DateTime month) {
  const labels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return labels[month.month - 1];
}

/// Format month with year (e.g., "Jan 2026").
String monthLabelFull(DateTime month) {
  return "${monthLabel(month)} ${month.year}";
}

/// Check if two dates are in the same month and year.
bool isSameMonth(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month;
}

/// Build summary items from entries.
List<SummaryItem> buildSummary(
  List<MigraineEntry> source, {
  VoidCallback? onHighestPainDayTap,
}) {
  if (source.isEmpty) {
    return [
      SummaryItem("Total Entries", "0", "No logs in selected month"),
      SummaryItem("Avg. Intensity", "-", "No data yet"),
      SummaryItem("Highest Pain Day", "-", "No data yet"),
      SummaryItem("Top Cause", "-", "No data yet"),
      SummaryItem("Painkiller Rate", "0%", "For selected month"),
    ];
  }

  final total = source.length;
  final avgIntensity =
      source.map((e) => e.intensity).reduce((a, b) => a + b) / total;
  final maxIntensity = source
      .map((e) => e.intensity)
      .reduce((a, b) => a > b ? a : b);
  final minIntensity = source
      .map((e) => e.intensity)
      .reduce((a, b) => a < b ? a : b);

  final causeCounts = <String, int>{};
  for (final entry in source) {
    for (final cause in entry.causes) {
      causeCounts[cause] = (causeCounts[cause] ?? 0) + 1;
    }
  }
  String topCause = "Unknown";
  if (causeCounts.isNotEmpty) {
    final sorted = causeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    topCause = sorted.first.key;
  }

  final painkillerRate = (painkillerUsage(source) * 100).round();
  final highestPainEntry = source.reduce((a, b) {
    if (a.intensity == b.intensity) {
      return a.date.isAfter(b.date) ? a : b;
    }
    return a.intensity > b.intensity ? a : b;
  });

  return [
    SummaryItem(
      "Total Entries",
      "$total",
      "Max $maxIntensity • Min $minIntensity",
    ),
    SummaryItem(
      "Avg. Intensity",
      avgIntensity.toStringAsFixed(1),
      "For selected month",
    ),
    SummaryItem(
      "Highest Pain Day",
      formatDdMmYyyy(highestPainEntry.date),
      "Intensity ${highestPainEntry.intensity}/10",
      onTap: onHighestPainDayTap,
    ),
    SummaryItem("Top Cause", topCause, "Most frequent trigger"),
    SummaryItem("Painkiller Rate", "$painkillerRate%", "For selected month"),
  ];
}

/// Build comparison items between two months.
List<ComparisonItem> buildComparisonItems({
  required List<MigraineEntry> selectedSource,
  required List<MigraineEntry> compareSource,
  required DateTime selectedMonth,
  required DateTime compareMonth,
}) {
  final selectedAvg = selectedSource.isEmpty
      ? 0.0
      : selectedSource.map((e) => e.intensity).reduce((a, b) => a + b) /
            selectedSource.length;
  final compareAvg = compareSource.isEmpty
      ? 0.0
      : compareSource.map((e) => e.intensity).reduce((a, b) => a + b) /
            compareSource.length;
  final selectedPainkiller = (painkillerUsage(selectedSource) * 100).round();
  final comparePainkiller = (painkillerUsage(compareSource) * 100).round();

  return [
    ComparisonItem(
      title: "Total Entries",
      selectedValue: "${selectedSource.length}",
      compareValue: "${compareSource.length}",
      deltaLabel: signedDelta(selectedSource.length - compareSource.length),
      subtitle: "${monthLabel(selectedMonth)} vs ${monthLabel(compareMonth)}",
    ),
    ComparisonItem(
      title: "Avg. Intensity",
      selectedValue: selectedSource.isEmpty
          ? "-"
          : selectedAvg.toStringAsFixed(1),
      compareValue: compareSource.isEmpty ? "-" : compareAvg.toStringAsFixed(1),
      deltaLabel: signedDoubleDelta(selectedAvg - compareAvg),
      subtitle: "Selected month compared with comparison month",
    ),
    ComparisonItem(
      title: "Painkiller Rate",
      selectedValue: "$selectedPainkiller%",
      compareValue: "$comparePainkiller%",
      deltaLabel: signedDelta(
        selectedPainkiller - comparePainkiller,
        unit: "%",
      ),
      subtitle: "Medication use across both months",
    ),
  ];
}

/// Format a signed integer delta with optional unit.
String signedDelta(int value, {String unit = ''}) {
  if (value == 0) return "No change";
  final sign = value > 0 ? "+" : "";
  return "$sign$value$unit";
}

/// Format a signed double delta.
String signedDoubleDelta(double value) {
  if (value.abs() < 0.05) return "No change";
  final sign = value > 0 ? "+" : "";
  return "$sign${value.toStringAsFixed(1)}";
}

// ==========================================
// ADVANCED STATISTICAL ANALYTICS MODELS
// ==========================================

/// Advanced Trigger Co-occurrence Correlation
class TriggerCorrelation {
  const TriggerCorrelation({
    required this.causeA,
    required this.causeB,
    required this.coOccurrences,
    required this.correlationPercent,
  });

  final String causeA;
  final String causeB;
  final int coOccurrences;
  final double correlationPercent;
}

/// Cause impact on intensity (intensity multiplier)
class TriggerRiskMultiplier {
  const TriggerRiskMultiplier({
    required this.cause,
    required this.occurrences,
    required this.avgIntensityWith,
    required this.avgIntensityWithout,
    required this.intensityDelta,
  });

  final String cause;
  final int occurrences;
  final double avgIntensityWith;
  final double avgIntensityWithout;
  final double intensityDelta;
}

/// Cycle & periodicity intervals
class CycleIntervalMetrics {
  const CycleIntervalMetrics({
    required this.intervalCount,
    required this.meanIntervalDays,
    required this.medianIntervalDays,
    required this.minIntervalDays,
    required this.maxIntervalDays,
    required this.intervalStandardDeviation,
    required this.regularityScore,
    required this.intervalsUnder4Days,
    required this.intervals4to7Days,
    required this.intervals8to14Days,
    required this.intervals15PlusDays,
  });

  final int intervalCount;
  final double meanIntervalDays;
  final double medianIntervalDays;
  final int minIntervalDays;
  final int maxIntervalDays;
  final double intervalStandardDeviation;
  final double regularityScore;
  final int intervalsUnder4Days;
  final int intervals4to7Days;
  final int intervals8to14Days;
  final int intervals15PlusDays;
}

/// Day of week distribution
class WeekdayDayMetric {
  const WeekdayDayMetric({
    required this.weekdayName,
    required this.shortName,
    required this.count,
    required this.percent,
    required this.avgIntensity,
  });

  final String weekdayName;
  final String shortName;
  final int count;
  final double percent;
  final double avgIntensity;
}

class WeekdayDistribution {
  const WeekdayDistribution({
    required this.days,
    required this.peakDayName,
    required this.peakDayCount,
    required this.isWeekendPeak,
  });

  final List<WeekdayDayMetric> days;
  final String peakDayName;
  final int peakDayCount;
  final bool isWeekendPeak;
}

/// Severity classification
class SeverityDistribution {
  const SeverityDistribution({
    required this.mildCount,
    required this.mildPercent,
    required this.moderateCount,
    required this.moderatePercent,
    required this.severeCount,
    required this.severePercent,
    required this.totalCount,
    required this.standardDeviation,
  });

  final int mildCount;
  final double mildPercent;
  final int moderateCount;
  final double moderatePercent;
  final int severeCount;
  final double severePercent;
  final int totalCount;
  final double standardDeviation;
}

/// Medication Overuse & Rebound Risk
enum MedicationOveruseLevel { low, caution, high }

class MedicationRiskMetrics {
  const MedicationRiskMetrics({
    required this.medicationDaysThisMonth,
    required this.medicationDaysLast30Days,
    required this.totalDaysInMonth,
    required this.riskLevel,
    required this.riskMessage,
    required this.consecutiveDaysMax,
  });

  final int medicationDaysThisMonth;
  final int medicationDaysLast30Days;
  final int totalDaysInMonth;
  final MedicationOveruseLevel riskLevel;
  final String riskMessage;
  final int consecutiveDaysMax;
}

// ==========================================
// ADVANCED STATISTICAL COMPUTATION FUNCTIONS
// ==========================================

/// Calculate pairwise trigger co-occurrences.
List<TriggerCorrelation> calculateTriggerCorrelations(
  List<MigraineEntry> entries, {
  int minCoOccurrences = 1,
}) {
  final migraineEntries = entries.where((e) => e.hadMigraine).toList();
  if (migraineEntries.isEmpty) return const [];

  final pairCounts = <String, int>{};
  final causeCounts = <String, int>{};

  for (final entry in migraineEntries) {
    final uniqueCauses = entry.causes.toSet().toList()..sort();
    for (int i = 0; i < uniqueCauses.length; i++) {
      final a = uniqueCauses[i];
      causeCounts[a] = (causeCounts[a] ?? 0) + 1;
      for (int j = i + 1; j < uniqueCauses.length; j++) {
        final b = uniqueCauses[j];
        final key = "$a|||$b";
        pairCounts[key] = (pairCounts[key] ?? 0) + 1;
      }
    }
  }

  final correlations = <TriggerCorrelation>[];
  for (final entry in pairCounts.entries) {
    if (entry.value < minCoOccurrences) continue;
    final parts = entry.key.split("|||");
    final causeA = parts[0];
    final causeB = parts[1];
    final countA = causeCounts[causeA] ?? 1;
    final countB = causeCounts[causeB] ?? 1;
    final minCount = math.min(countA, countB);
    final percent = minCount > 0 ? (entry.value / minCount) * 100 : 0.0;

    correlations.add(
      TriggerCorrelation(
        causeA: causeA,
        causeB: causeB,
        coOccurrences: entry.value,
        correlationPercent: percent.clamp(0.0, 100.0),
      ),
    );
  }

  correlations.sort((a, b) {
    final cmp = b.coOccurrences.compareTo(a.coOccurrences);
    if (cmp != 0) return cmp;
    return b.correlationPercent.compareTo(a.correlationPercent);
  });

  return correlations;
}

/// Calculate trigger risk multipliers (how much pain intensity changes when a trigger is present).
List<TriggerRiskMultiplier> calculateTriggerRiskMultipliers(
  List<MigraineEntry> entries, {
  int minOccurrences = 1,
}) {
  final migraineEntries = entries.where((e) => e.hadMigraine).toList();
  if (migraineEntries.isEmpty) return const [];

  final causeMap = <String, List<int>>{};
  for (final entry in migraineEntries) {
    for (final cause in entry.causes) {
      causeMap.putIfAbsent(cause, () => []).add(entry.intensity);
    }
  }

  final overallSum = migraineEntries.fold<int>(0, (sum, e) => sum + e.intensity);
  final overallCount = migraineEntries.length;

  final multipliers = <TriggerRiskMultiplier>[];
  for (final entry in causeMap.entries) {
    final cause = entry.key;
    final withIntensities = entry.value;
    if (withIntensities.length < minOccurrences) continue;

    final avgWith =
        withIntensities.reduce((a, b) => a + b) / withIntensities.length;
    
    // Average intensity of migraine entries without this cause
    final withoutEntries =
        migraineEntries.where((e) => !e.causes.contains(cause)).toList();
    final avgWithout = withoutEntries.isEmpty
        ? (overallCount > 0 ? overallSum / overallCount : avgWith)
        : withoutEntries.fold<int>(0, (sum, e) => sum + e.intensity) /
            withoutEntries.length;

    final delta = avgWith - avgWithout;

    multipliers.add(
      TriggerRiskMultiplier(
        cause: cause,
        occurrences: withIntensities.length,
        avgIntensityWith: avgWith,
        avgIntensityWithout: avgWithout,
        intensityDelta: delta,
      ),
    );
  }

  multipliers.sort((a, b) {
    final cmp = b.intensityDelta.compareTo(a.intensityDelta);
    if (cmp != 0) return cmp;
    return b.occurrences.compareTo(a.occurrences);
  });

  return multipliers;
}

/// Calculate inter-attack interval statistics and periodicity regularity.
CycleIntervalMetrics calculateCycleIntervalMetrics(List<MigraineEntry> allEntries) {
  final migraineDays = allEntries
      .where((e) => e.hadMigraine)
      .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
      .toSet()
      .toList()
    ..sort();

  if (migraineDays.length < 2) {
    return const CycleIntervalMetrics(
      intervalCount: 0,
      meanIntervalDays: 0,
      medianIntervalDays: 0,
      minIntervalDays: 0,
      maxIntervalDays: 0,
      intervalStandardDeviation: 0,
      regularityScore: 0,
      intervalsUnder4Days: 0,
      intervals4to7Days: 0,
      intervals8to14Days: 0,
      intervals15PlusDays: 0,
    );
  }

  final intervals = <int>[];
  for (int i = 1; i < migraineDays.length; i++) {
    final diff = migraineDays[i].difference(migraineDays[i - 1]).inDays;
    if (diff > 0) {
      intervals.add(diff);
    }
  }

  if (intervals.isEmpty) {
    return const CycleIntervalMetrics(
      intervalCount: 0,
      meanIntervalDays: 0,
      medianIntervalDays: 0,
      minIntervalDays: 0,
      maxIntervalDays: 0,
      intervalStandardDeviation: 0,
      regularityScore: 0,
      intervalsUnder4Days: 0,
      intervals4to7Days: 0,
      intervals8to14Days: 0,
      intervals15PlusDays: 0,
    );
  }

  final sum = intervals.reduce((a, b) => a + b);
  final mean = sum / intervals.length;

  final sortedIntervals = List<int>.from(intervals)..sort();
  final median = sortedIntervals.length.isOdd
      ? sortedIntervals[sortedIntervals.length ~/ 2].toDouble()
      : (sortedIntervals[sortedIntervals.length ~/ 2 - 1] +
              sortedIntervals[sortedIntervals.length ~/ 2]) /
          2.0;

  final minVal = sortedIntervals.first;
  final maxVal = sortedIntervals.last;

  final varianceSum = intervals.fold<double>(
    0.0,
    (acc, val) => acc + math.pow(val - mean, 2),
  );
  final stdDev = math.sqrt(varianceSum / intervals.length);

  // Coefficient of Variation regularity score (0 to 100%)
  final cv = mean > 0 ? (stdDev / mean) : 1.0;
  final regularity = ((1.0 - cv.clamp(0.0, 1.0)) * 100).roundToDouble();

  int under4 = 0;
  int d4to7 = 0;
  int d8to14 = 0;
  int d15plus = 0;

  for (final iv in intervals) {
    if (iv < 4) {
      under4++;
    } else if (iv <= 7) {
      d4to7++;
    } else if (iv <= 14) {
      d8to14++;
    } else {
      d15plus++;
    }
  }

  return CycleIntervalMetrics(
    intervalCount: intervals.length,
    meanIntervalDays: mean,
    medianIntervalDays: median,
    minIntervalDays: minVal,
    maxIntervalDays: maxVal,
    intervalStandardDeviation: stdDev,
    regularityScore: regularity,
    intervalsUnder4Days: under4,
    intervals4to7Days: d4to7,
    intervals8to14Days: d8to14,
    intervals15PlusDays: d15plus,
  );
}

/// Calculate weekday attack distribution (Monday to Sunday).
WeekdayDistribution calculateWeekdayDistribution(List<MigraineEntry> entries) {
  const weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const shortNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final counts = List<int>.filled(7, 0);
  final intensitySums = List<int>.filled(7, 0);

  final migraineEntries = entries.where((e) => e.hadMigraine).toList();
  for (final entry in migraineEntries) {
    final idx = (entry.date.weekday - 1).clamp(0, 6);
    counts[idx] += 1;
    intensitySums[idx] += entry.intensity;
  }

  final total = migraineEntries.length;
  final dayMetrics = <WeekdayDayMetric>[];

  int peakCount = 0;
  String peakDay = "None";

  for (int i = 0; i < 7; i++) {
    final count = counts[i];
    final percent = total > 0 ? (count / total) * 100 : 0.0;
    final avg = count > 0 ? intensitySums[i] / count : 0.0;
    if (count > peakCount) {
      peakCount = count;
      peakDay = weekdayNames[i];
    }
    dayMetrics.add(
      WeekdayDayMetric(
        weekdayName: weekdayNames[i],
        shortName: shortNames[i],
        count: count,
        percent: percent,
        avgIntensity: avg,
      ),
    );
  }

  final isWeekend = peakDay == 'Saturday' || peakDay == 'Sunday';

  return WeekdayDistribution(
    days: dayMetrics,
    peakDayName: peakDay,
    peakDayCount: peakCount,
    isWeekendPeak: isWeekend,
  );
}

/// Calculate pain severity distribution and volatility.
SeverityDistribution calculateSeverityDistribution(List<MigraineEntry> entries) {
  final migraineEntries = entries.where((e) => e.hadMigraine).toList();
  if (migraineEntries.isEmpty) {
    return const SeverityDistribution(
      mildCount: 0,
      mildPercent: 0,
      moderateCount: 0,
      moderatePercent: 0,
      severeCount: 0,
      severePercent: 0,
      totalCount: 0,
      standardDeviation: 0,
    );
  }

  int mild = 0;
  int moderate = 0;
  int severe = 0;
  final intensities = <int>[];

  for (final entry in migraineEntries) {
    intensities.add(entry.intensity);
    if (entry.intensity <= 3) {
      mild++;
    } else if (entry.intensity <= 6) {
      moderate++;
    } else {
      severe++;
    }
  }

  final total = migraineEntries.length;
  final mean = intensities.reduce((a, b) => a + b) / total;
  final varianceSum = intensities.fold<double>(
    0.0,
    (acc, val) => acc + math.pow(val - mean, 2),
  );
  final stdDev = math.sqrt(varianceSum / total);

  return SeverityDistribution(
    mildCount: mild,
    mildPercent: (mild / total) * 100,
    moderateCount: moderate,
    moderatePercent: (moderate / total) * 100,
    severeCount: severe,
    severePercent: (severe / total) * 100,
    totalCount: total,
    standardDeviation: stdDev,
  );
}

/// Calculate medication overuse headache (MOH) risk metrics.
MedicationRiskMetrics calculateMedicationRisk(
  List<MigraineEntry> allEntries,
  DateTime selectedMonth, {
  DateTime? now,
}) {
  final refDate = now ?? DateTime.now();
  final daysInMonth =
      DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;

  final monthPainkillerDays = allEntries
      .where((e) =>
          e.painkillers &&
          e.date.year == selectedMonth.year &&
          e.date.month == selectedMonth.month)
      .map((e) => e.date.day)
      .toSet()
      .length;

  final thirtyDaysAgo = refDate.subtract(const Duration(days: 30));
  final recentPainkillerDays = allEntries
      .where((e) =>
          e.painkillers &&
          e.date.isAfter(thirtyDaysAgo) &&
          e.date.isBefore(refDate.add(const Duration(days: 1))))
      .map((e) => "${e.date.year}-${e.date.month}-${e.date.day}")
      .toSet()
      .length;

  // Compute maximum consecutive medication days
  final sortedMedDates = allEntries
      .where((e) => e.painkillers)
      .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
      .toSet()
      .toList()
    ..sort();

  int maxConsecutive = 0;
  int currentStreak = 0;
  for (int i = 0; i < sortedMedDates.length; i++) {
    if (i == 0) {
      currentStreak = 1;
    } else {
      final diff = sortedMedDates[i].difference(sortedMedDates[i - 1]).inDays;
      if (diff == 1) {
        currentStreak++;
      } else {
        currentStreak = 1;
      }
    }
    if (currentStreak > maxConsecutive) {
      maxConsecutive = currentStreak;
    }
  }

  MedicationOveruseLevel riskLevel;
  String message;

  if (monthPainkillerDays >= 10 || recentPainkillerDays >= 10) {
    riskLevel = MedicationOveruseLevel.high;
    message =
        "Analgesic frequency ($monthPainkillerDays days/mo) exceeds the 10-day MOH clinical threshold. Risk of rebound headaches.";
  } else if (monthPainkillerDays >= 6 || recentPainkillerDays >= 6) {
    riskLevel = MedicationOveruseLevel.caution;
    message =
        "Moderate analgesic frequency ($monthPainkillerDays days/mo). Keep usage under 10 days/month to avoid rebound cycles.";
  } else {
    riskLevel = MedicationOveruseLevel.low;
    message =
        "Low analgesic frequency ($monthPainkillerDays days/mo). Well within safe clinical parameters.";
  }

  return MedicationRiskMetrics(
    medicationDaysThisMonth: monthPainkillerDays,
    medicationDaysLast30Days: recentPainkillerDays,
    totalDaysInMonth: daysInMonth,
    riskLevel: riskLevel,
    riskMessage: message,
    consecutiveDaysMax: maxConsecutive,
  );
}
