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
  CauseDatum(this.label, this.count, this.total);

  final String label;
  final int count;
  final int total;

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
  for (final entry in source) {
    for (final cause in entry.causes) {
      counts[cause] = (counts[cause] ?? 0) + 1;
    }
  }
  final total = counts.values.fold<int>(0, (sum, v) => sum + v);
  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sorted.map((e) => CauseDatum(e.key, e.value, total)).toList();
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
