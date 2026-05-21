import 'package:flutter/material.dart';
import 'package:migraine_tracker/features/tracker/models/migraine_entry.dart';

/// Data class for entry comparison statistics.
class EntryComparisonStats {
  const EntryComparisonStats({
    required this.averageIntensity,
    required this.monthAverageIntensity,
    required this.intensityDelta,
    required this.monthIntensityDelta,
    required this.minIntensity,
    required this.maxIntensity,
    required this.percentile,
    required this.totalCompared,
  });

  final double averageIntensity;
  final double? monthAverageIntensity;
  final double intensityDelta;
  final double? monthIntensityDelta;
  final int minIntensity;
  final int maxIntensity;
  final int percentile;
  final int totalCompared;
}

/// Get the color for an intensity level based on the color scheme.
Color getIntensityColor(int intensity, ColorScheme scheme) {
  if (intensity <= 3) {
    return Color.fromARGB(255, 76, 175, 80); // Green
  } else if (intensity <= 6) {
    return Color.fromARGB(255, 255, 193, 7); // Yellow
  } else {
    return Color.fromARGB(255, 244, 67, 54); // Red
  }
}

/// Build comparison statistics for an entry.
EntryComparisonStats? buildComparisonStats(
  MigraineEntry entry,
  List<MigraineEntry> allEntries,
) {
  final migraineEntries = allEntries.where((candidate) {
    if (!candidate.hadMigraine) return false;
    if (entry.id != null && candidate.id == entry.id) return true;
    return isSameDay(candidate.date, entry.date);
  }).toList();

  final comparisonPool = allEntries.where((candidate) {
    if (!candidate.hadMigraine) return false;
    if (entry.id != null) return candidate.id != entry.id;
    return !isSameDay(candidate.date, entry.date);
  }).toList();

  final currentEntry = migraineEntries.isNotEmpty
      ? migraineEntries.first
      : entry;

  if (comparisonPool.isEmpty) return null;

  final averageIntensity =
      comparisonPool.map((e) => e.intensity).reduce((a, b) => a + b) /
      comparisonPool.length;
  final monthEntries = comparisonPool
      .where((candidate) => isSameMonth(candidate.date, currentEntry.date))
      .toList();
  final monthAverage = monthEntries.isEmpty
      ? null
      : monthEntries.map((e) => e.intensity).reduce((a, b) => a + b) /
            monthEntries.length;
  final minIntensity = comparisonPool
      .map((e) => e.intensity)
      .reduce((a, b) => a < b ? a : b);
  final maxIntensity = comparisonPool
      .map((e) => e.intensity)
      .reduce((a, b) => a > b ? a : b);
  final lowerCount = comparisonPool
      .where((e) => e.intensity < currentEntry.intensity)
      .length;
  final percentile = ((lowerCount / comparisonPool.length) * 100).round();

  return EntryComparisonStats(
    averageIntensity: averageIntensity,
    monthAverageIntensity: monthAverage,
    intensityDelta: currentEntry.intensity - averageIntensity,
    monthIntensityDelta: monthAverage == null
        ? null
        : currentEntry.intensity - monthAverage,
    minIntensity: minIntensity,
    maxIntensity: maxIntensity,
    percentile: percentile,
    totalCompared: comparisonPool.length,
  );
}

/// Check if two dates are on the same day.
bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Check if two dates are in the same month and year.
bool isSameMonth(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month;
}
