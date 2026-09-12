import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:migraine_tracker/core/theme/app_theme.dart';
import 'package:migraine_tracker/features/tracker/models/migraine_entry.dart';
import 'package:migraine_tracker/features/tracker/pages/_utils/stats_utils.dart'
    as stats_utils;
import 'package:migraine_tracker/features/tracker/pages/view_page.dart';
import 'package:migraine_tracker/features/tracker/providers/entries_provider.dart';
import 'package:migraine_tracker/core/utils/date_utils.dart';
import 'package:migraine_tracker/core/widgets/wavy_surface.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _compareMonth;

  Future<void> _loadStats() async {
    await ref.read(migraineEntriesProvider.notifier).reload();
  }

  @override
  Widget build(BuildContext context) {
    final entriesState = ref.watch(migraineEntriesProvider);
    final entries = entriesState.value ?? const <MigraineEntry>[];

    if (entriesState.isLoading && entriesState.value == null) {
      return const _StatsLoadingView();
    }

    final monthOptions = _buildMonthOptions(entries);
    final selectedMonth =
        monthOptions.any((month) => _isSameMonth(month, _selectedMonth))
        ? _selectedMonth
        : monthOptions.first;
    final compareMonth = _validatedCompareMonth(
      options: monthOptions,
      selectedMonth: selectedMonth,
      currentCompare: _compareMonth,
    );

    final filtered = entries.where((e) {
      return e.date.year == selectedMonth.year &&
          e.date.month == selectedMonth.month;
    }).toList();
    final compared = compareMonth == null
        ? <MigraineEntry>[]
        : entries.where((e) {
            return e.date.year == compareMonth.year &&
                e.date.month == compareMonth.month;
          }).toList();
    final monthStats = _buildWeeklyFrequency(filtered, selectedMonth);
    final avgStats = _buildWeeklyAverages(filtered, selectedMonth);
    final causes = _buildCauseStats(filtered);
    final painkillerPercent = _painkillerUsage(filtered);
    final intensitySeries = filtered.reversed
        .map((e) => e.intensity)
        .toList()
        .take(14)
        .toList();
    final summary = _buildSummary(filtered);
    final overallAvg = entries.isEmpty
        ? 0.0
        : entries.map((e) => e.intensity).reduce((a, b) => a + b) /
              entries.length;
    final selectedAvg = filtered.isEmpty
        ? 0.0
        : filtered.map((e) => e.intensity).reduce((a, b) => a + b) /
              filtered.length;
    final comparison = compareMonth == null
        ? <_ComparisonItem>[]
        : _buildComparisonItems(
            selectedSource: filtered,
            compareSource: compared,
            selectedMonth: selectedMonth,
            compareMonth: compareMonth,
          );
    final progressComparison = stats_utils.buildMonthlyProgressComparison(
      allEntries: entries,
      selectedMonth: selectedMonth,
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Statistics")),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: entries.isEmpty
              ? const _StatsEmptyState()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MonthFilterCard(
                      selectedMonth: selectedMonth,
                      compareMonth: compareMonth,
                      options: monthOptions,
                      onSelectedChanged: (month) {
                        setState(() {
                          _selectedMonth = month;
                          _compareMonth = _validatedCompareMonth(
                            options: monthOptions,
                            selectedMonth: month,
                            currentCompare: _compareMonth,
                          );
                        });
                      },
                      onCompareChanged: (month) {
                        setState(() {
                          _compareMonth = month;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _DashboardHeader(
                      totalEntries: filtered.length,
                      monthLabel: _monthLabelFull(selectedMonth),
                      compareLabel: compareMonth == null
                          ? null
                          : _monthLabelFull(compareMonth),
                    ),
                    const SizedBox(height: 12),
                    _MonthlyProgressCard(comparison: progressComparison),
                    const SizedBox(height: 24),
                    if (filtered.isEmpty) ...[
                      _SelectedMonthEmptyState(
                        monthLabel: _monthLabelFull(selectedMonth),
                      ),
                      const SizedBox(height: 20),
                    ],
                    const _SectionTitle(
                      title: "Summary",
                      subtitle: "High-level indicators for selected month",
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: summary.map((item) {
                        return _InsightCard(
                          title: item.title,
                          value: item.value,
                          subtitle: item.subtitle,
                          onTap: item.onTap,
                        );
                      }).toList(),
                    ),
                    if (compareMonth != null) ...[
                      const SizedBox(height: 20),
                      const _SectionTitle(
                        title: "Month Comparison",
                        subtitle:
                            "Quick differences between the selected and comparison months",
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: comparison.map((item) {
                          return _ComparisonCard(item: item);
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _SectionTitle(
                      title: "Monthly Calendar",
                      subtitle:
                          "Daily migraine log for ${_monthLabelFull(selectedMonth)}",
                    ),
                    const SizedBox(height: 12),
                    _AppleCalendarCard(
                      month: selectedMonth,
                      entries: filtered,
                      onDayTap: (date, entry) {
                        if (entry != null) {
                          Navigator.of(
                            context,
                          ).push(viewMigraineRoute(entry: entry));
                        } else {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "No migraine logged on ${formatDdMmYyyy(date)}",
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle(
                      title: "Causes & Triggers Graph",
                      subtitle:
                          "Distribution and frequency of logged causes for this month",
                    ),
                    const SizedBox(height: 12),
                    _CausesGraphCard(
                      data: causes,
                      totalEntries: filtered.length,
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle(
                      title: "Trends & Intensity",
                      subtitle:
                          "Patterns across frequency, medication, and pain levels",
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ChartCard(
                            title: "Weekly Frequency",
                            child: _BarChart(data: monthStats),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ChartCard(
                            title: "Weekly Avg. Intensity",
                            child: _BarChart(data: avgStats),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ChartCard(
                      title: "Painkiller Usage",
                      child: _Gauge(value: painkillerPercent),
                    ),
                    const SizedBox(height: 16),
                    _ChartCard(
                      title: "Intensity Graph",
                      child: Column(
                        children: [
                          Expanded(child: _LineChart(values: intensitySeries)),
                          const SizedBox(height: 8),
                          Text(
                            "Overall avg ${overallAvg.toStringAsFixed(1)} • ${_monthLabel(selectedMonth)} avg ${selectedAvg.toStringAsFixed(1)}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  List<_BarDatum> _buildWeeklyFrequency(
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
    return List<_BarDatum>.generate(
      5,
      (i) => _BarDatum("W${i + 1}", counts[i].toDouble()),
    );
  }

  List<_BarDatum> _buildWeeklyAverages(
    List<MigraineEntry> source,
    DateTime month,
  ) {
    final buckets = List<List<int>>.generate(5, (_) => []);
    for (final entry in source) {
      if (entry.date.year != month.year || entry.date.month != month.month) {
        continue;
      }
      final bucket = ((entry.date.day - 1) / 7).floor().clamp(0, 4);
      buckets[bucket].add(entry.intensity);
    }
    return List<_BarDatum>.generate(5, (i) {
      final values = buckets[i];
      if (values.isEmpty) return _BarDatum("W${i + 1}", 0);
      final avg = values.reduce((a, b) => a + b) / values.length;
      return _BarDatum("W${i + 1}", avg);
    });
  }

  List<DateTime> _buildMonthOptions(List<MigraineEntry> entries) {
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

  DateTime? _validatedCompareMonth({
    required List<DateTime> options,
    required DateTime selectedMonth,
    required DateTime? currentCompare,
  }) {
    if (currentCompare == null) {
      return null;
    }
    if (_isSameMonth(currentCompare, selectedMonth)) {
      return null;
    }
    final hasCompare = options.any(
      (month) => _isSameMonth(month, currentCompare),
    );
    return hasCompare ? currentCompare : null;
  }

  List<_CauseDatum> _buildCauseStats(List<MigraineEntry> source) {
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
      final avg =
          list.isEmpty ? 0.0 : list.reduce((a, b) => a + b) / list.length;
      return _CauseDatum(e.key, e.value, total, avgIntensity: avg);
    }).toList();
  }

  double _painkillerUsage(List<MigraineEntry> source) {
    if (source.isEmpty) return 0;
    final used = source.where((e) => e.painkillers).length;
    return used / source.length;
  }

  String _monthLabel(DateTime month) {
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

  String _monthLabelFull(DateTime month) {
    return "${_monthLabel(month)} ${month.year}";
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  List<_SummaryItem> _buildSummary(List<MigraineEntry> source) {
    if (source.isEmpty) {
      return [
        _SummaryItem("Total Entries", "0", "No logs in selected month"),
        _SummaryItem("Avg. Intensity", "-", "No data yet"),
        _SummaryItem("Highest Pain Day", "-", "No data yet"),
        _SummaryItem("Top Cause", "-", "No data yet"),
        _SummaryItem("Painkiller Rate", "0%", "For selected month"),
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

    final painkillerRate = (_painkillerUsage(source) * 100).round();
    final highestPainEntry = source.reduce((a, b) {
      if (a.intensity == b.intensity) {
        return a.date.isAfter(b.date) ? a : b;
      }
      return a.intensity > b.intensity ? a : b;
    });

    return [
      _SummaryItem(
        "Total Entries",
        "$total",
        "Max $maxIntensity • Min $minIntensity",
      ),
      _SummaryItem(
        "Avg. Intensity",
        avgIntensity.toStringAsFixed(1),
        "For selected month",
      ),
      _SummaryItem(
        "Highest Pain Day",
        formatDdMmYyyy(highestPainEntry.date),
        "Intensity ${highestPainEntry.intensity}/10",
        onTap: () {
          Navigator.of(
            context,
          ).push(viewMigraineRoute(entry: highestPainEntry));
        },
      ),
      _SummaryItem("Top Cause", topCause, "Most frequent trigger"),
      _SummaryItem("Painkiller Rate", "$painkillerRate%", "For selected month"),
    ];
  }

  List<_ComparisonItem> _buildComparisonItems({
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
    final selectedPainkiller = (_painkillerUsage(selectedSource) * 100).round();
    final comparePainkiller = (_painkillerUsage(compareSource) * 100).round();

    return [
      _ComparisonItem(
        title: "Total Entries",
        selectedValue: "${selectedSource.length}",
        compareValue: "${compareSource.length}",
        deltaLabel: _signedDelta(selectedSource.length - compareSource.length),
        subtitle:
            "${_monthLabel(selectedMonth)} vs ${_monthLabel(compareMonth)}",
      ),
      _ComparisonItem(
        title: "Avg. Intensity",
        selectedValue: selectedSource.isEmpty
            ? "-"
            : selectedAvg.toStringAsFixed(1),
        compareValue: compareSource.isEmpty
            ? "-"
            : compareAvg.toStringAsFixed(1),
        deltaLabel: _signedDoubleDelta(selectedAvg - compareAvg),
        subtitle: "Selected month compared with comparison month",
      ),
      _ComparisonItem(
        title: "Painkiller Rate",
        selectedValue: "$selectedPainkiller%",
        compareValue: "$comparePainkiller%",
        deltaLabel: _signedDelta(
          selectedPainkiller - comparePainkiller,
          unit: "%",
        ),
        subtitle: "Medication use across both months",
      ),
    ];
  }

  String _signedDelta(int value, {String unit = ''}) {
    if (value == 0) return "No change";
    final sign = value > 0 ? "+" : "";
    return "$sign$value$unit";
  }

  String _signedDoubleDelta(double value) {
    if (value.abs() < 0.05) return "No change";
    final sign = value > 0 ? "+" : "";
    return "$sign${value.toStringAsFixed(1)}";
  }
}

class _StatsLoadingView extends StatelessWidget {
  const _StatsLoadingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Statistics")),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: const [
          _StatsSkeletonBox(height: 80, radius: 18),
          SizedBox(height: 24),
          _StatsSkeletonBox(height: 18, width: 120),
          SizedBox(height: 12),
          _StatsSkeletonBox(height: 200, radius: 14),
          SizedBox(height: 16),
          _StatsSkeletonBox(height: 170, radius: 14),
        ],
      ),
    );
  }
}

class _StatsEmptyState extends StatelessWidget {
  const _StatsEmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.12)),
        color: scheme.surface.withValues(alpha: 0.72),
      ),
      child: Column(
        children: [
          Icon(Icons.insights_outlined, size: 36, color: scheme.primary),
          const SizedBox(height: 10),
          Text(
            "No stats yet",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            "Log your first migraine entry to unlock trends, triggers, and intensity charts.",
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.72)),
          ),
          const SizedBox(height: 10),
          Text(
            "Tip: Pull down to refresh after adding new logs.",
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: 0.58),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSkeletonBox extends StatelessWidget {
  const _StatsSkeletonBox({
    required this.height,
    this.width = double.infinity,
    this.radius = 10,
  });

  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            colors: [
              scheme.surface.withValues(alpha: 0.85),
              scheme.surface.withValues(alpha: 0.56),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthFilterCard extends StatelessWidget {
  const _MonthFilterCard({
    required this.selectedMonth,
    required this.compareMonth,
    required this.options,
    required this.onSelectedChanged,
    required this.onCompareChanged,
  });

  final DateTime selectedMonth;
  final DateTime? compareMonth;
  final List<DateTime> options;
  final ValueChanged<DateTime> onSelectedChanged;
  final ValueChanged<DateTime?> onCompareChanged;

  String _monthLabel(DateTime month) {
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
    return "${labels[month.month - 1]} ${month.year}";
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.13)),
        color: scheme.surface.withValues(alpha: 0.74),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<DateTime>(
            initialValue: selectedMonth,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: "Filter by month",
              border: OutlineInputBorder(),
            ),
            items: options
                .map(
                  (month) => DropdownMenuItem<DateTime>(
                    value: month,
                    child: Text(_monthLabel(month)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onSelectedChanged(value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<DateTime?>(
            initialValue: compareMonth,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: "Compare with",
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<DateTime?>(
                value: null,
                child: Text("No comparison"),
              ),
              ...options
                  .where(
                    (month) =>
                        month.year != selectedMonth.year ||
                        month.month != selectedMonth.month,
                  )
                  .map(
                    (month) => DropdownMenuItem<DateTime?>(
                      value: month,
                      child: Text(_monthLabel(month)),
                    ),
                  ),
            ],
            onChanged: onCompareChanged,
          ),
        ],
      ),
    );
  }
}

class _SelectedMonthEmptyState extends StatelessWidget {
  const _SelectedMonthEmptyState({required this.monthLabel});

  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.13)),
        color: scheme.surface.withValues(alpha: 0.74),
      ),
      child: Row(
        children: [
          Icon(Icons.event_busy_outlined, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "No entries for $monthLabel. Showing empty monthly stats.",
              style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.72)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.totalEntries,
    required this.monthLabel,
    this.compareLabel,
  });

  final int totalEntries;
  final String monthLabel;
  final String? compareLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return WavySurface(
      borderRadius: BorderRadius.circular(18),
      borderColor: scheme.primary.withValues(alpha: 0.20),
      gradient: LinearGradient(
        colors: [scheme.surface, scheme.tertiary.withValues(alpha: 0.14)],
        begin: Alignment.topCenter,
        end: Alignment.bottomRight,
      ),
      waveColorA: scheme.primary.withValues(alpha: 0.10),
      waveColorB: scheme.secondary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.15),
              ),
              child: Icon(Icons.analytics_rounded, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Stats Overview",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    compareLabel == null
                        ? "$totalEntries logged migraines • $monthLabel"
                        : "$totalEntries logged migraines • $monthLabel vs $compareLabel",
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.68),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            color: scheme.onSurface.withValues(alpha: 0.62),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MonthlyProgressCard extends StatelessWidget {
  const _MonthlyProgressCard({required this.comparison});

  final stats_utils.MonthlyProgressComparison comparison;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (accent, icon) = switch (comparison.status) {
      stats_utils.MonthlyProgressStatus.better => (
        const Color(0xFF16865F),
        Icons.trending_down_rounded,
      ),
      stats_utils.MonthlyProgressStatus.worse => (
        scheme.error,
        Icons.trending_up_rounded,
      ),
      stats_utils.MonthlyProgressStatus.steady => (
        scheme.tertiary,
        Icons.trending_flat_rounded,
      ),
      stats_utils.MonthlyProgressStatus.mixed => (
        scheme.secondary,
        Icons.swap_vert_rounded,
      ),
      stats_utils.MonthlyProgressStatus.insufficient => (
        scheme.onSurface.withValues(alpha: 0.62),
        Icons.hourglass_top_rounded,
      ),
    };
    final currentAverage = comparison.currentAverage;
    final previousAverage = comparison.previousAverage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
        color: accent.withValues(alpha: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  comparison.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(comparison.message),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ComparisonMetric(
                label: "Migraines",
                value:
                    "${comparison.currentCount} vs ${comparison.previousCount}",
                accent: accent,
              ),
              _ComparisonMetric(
                label: "Avg. intensity",
                value: currentAverage == null || previousAverage == null
                    ? "Not available"
                    : "${currentAverage.toStringAsFixed(1)} vs ${previousAverage.toStringAsFixed(1)}",
                accent: accent,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comparison.periodLabel,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonMetric extends StatelessWidget {
  const _ComparisonMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.82),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Text(
        "$label: $value",
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.13)),
        color: scheme.surface.withValues(alpha: 0.74),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(height: 140, child: child),
        ],
      ),
    );
  }
}

class _SummaryItem {
  _SummaryItem(this.title, this.value, this.subtitle, {this.onTap});

  final String title;
  final String value;
  final String subtitle;
  final VoidCallback? onTap;
}

class _ComparisonItem {
  _ComparisonItem({
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

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.value,
    required this.subtitle,
    this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: '$title: $value - $subtitle',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 170,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: scheme.onSurface.withValues(alpha: 0.13),
              ),
              color: scheme.surface.withValues(alpha: 0.74),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.item});

  final _ComparisonItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isNeutral = item.deltaLabel == "No change";
    final isPositive = item.deltaLabel.startsWith("+");
    final deltaColor = isNeutral
        ? scheme.onSurface.withValues(alpha: 0.6)
        : isPositive
        ? scheme.primary
        : scheme.error;

    return Tooltip(
      message:
          '${item.title}: ${item.selectedValue} vs ${item.compareValue} (${item.deltaLabel})',
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.onSurface.withValues(alpha: 0.13)),
          color: scheme.surface.withValues(alpha: 0.74),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 8),
            Text(
              "${item.selectedValue} vs ${item.compareValue}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              item.deltaLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: deltaColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.subtitle,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarDatum {
  _BarDatum(this.label, this.value);

  final String label;
  final double value;
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.data});

  final List<_BarDatum> data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxValue = data.isEmpty
        ? 1.0
        : data.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((datum) {
        final height = maxValue == 0 ? 0.0 : (datum.value / maxValue) * 100;
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Tooltip(
                message: '${datum.label}: ${datum.value.toStringAsFixed(1)}',
                child: Container(
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: scheme.barGradient,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(datum.label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CauseDatum {
  _CauseDatum(this.label, this.count, this.total, {this.avgIntensity = 0.0});

  final String label;
  final int count;
  final int total;
  final double avgIntensity;

  double get percent => total == 0 ? 0 : count / total;
}

class _CalendarStatPill extends StatelessWidget {
  const _CalendarStatPill({required this.dotColor, required this.label});

  final Color dotColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dotColor,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AppleCalendarCard extends StatelessWidget {
  const _AppleCalendarCard({
    required this.month,
    required this.entries,
    this.onDayTap,
  });

  final DateTime month;
  final List<MigraineEntry> entries;
  final void Function(DateTime date, MigraineEntry? entry)? onDayTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final calendarDays = stats_utils.buildCalendarMonthDays(
      month: month,
      entries: entries,
    );

    final migraineDaysCount =
        calendarDays.where((d) => d.isCurrentMonth && d.hasMigraine).length;
    final totalDaysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final painFreeDaysCount = totalDaysInMonth - migraineDaysCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.13)),
        color: scheme.surface.withValues(alpha: 0.74),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primary.withValues(alpha: 0.14),
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      size: 18,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "${stats_utils.monthLabel(month)} ${month.year}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF453A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFF453A).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFF453A),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      "Migraine",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF453A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            thickness: 0.5,
            color: scheme.onSurface.withValues(alpha: 0.10),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: calendarDays.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 4,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              final dayInfo = calendarDays[index];
              final isCurrent = dayInfo.isCurrentMonth;
              final isToday = dayInfo.isToday;
              final hasMigraine = dayInfo.hasMigraine;
              final entry = dayInfo.entry;

              final textColor = isCurrent
                  ? scheme.onSurface
                  : scheme.onSurface.withValues(alpha: 0.22);

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (onDayTap != null) {
                      onDayTap!(dayInfo.date, entry);
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: hasMigraine && isCurrent
                          ? const Color(0xFFFF453A).withValues(alpha: 0.10)
                          : isToday
                          ? scheme.primary.withValues(alpha: 0.08)
                          : Colors.transparent,
                      border: isToday
                          ? Border.all(
                              color: scheme.primary.withValues(alpha: 0.6),
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${dayInfo.date.day}",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isToday || (hasMigraine && isCurrent)
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (hasMigraine && isCurrent)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFF453A),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF453A,
                                  ).withValues(alpha: 0.45),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          )
                        else
                          const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _CalendarStatPill(
                  dotColor: const Color(0xFFFF453A),
                  label:
                      "$migraineDaysCount ${migraineDaysCount == 1 ? 'Migraine Day' : 'Migraine Days'}",
                ),
                Container(
                  width: 1,
                  height: 16,
                  color: scheme.onSurface.withValues(alpha: 0.12),
                ),
                _CalendarStatPill(
                  dotColor: const Color(0xFF34C759),
                  label: "$painFreeDaysCount Pain-Free",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CausesGraphCard extends StatelessWidget {
  const _CausesGraphCard({
    required this.data,
    required this.totalEntries,
  });

  final List<_CauseDatum> data;
  final int totalEntries;

  static const List<List<Color>> _causeGradients = [
    [Color(0xFFFF5C5C), Color(0xFFFF7E7E)], // Coral Red
    [Color(0xFFFF9F43), Color(0xFFFFBE76)], // Amber Orange
    [Color(0xFF7E57C2), Color(0xFF9575CD)], // Purple Indigo
    [Color(0xFF00D2D3), Color(0xFF54ECEE)], // Teal Cyan
    [Color(0xFF10AC84), Color(0xFF1DD1A1)], // Emerald Green
    [Color(0xFFFF6B81), Color(0xFFFF9AA2)], // Rose Pink
    [Color(0xFF54A0FF), Color(0xFF74B9FF)], // Sky Blue
    [Color(0xFFFED330), Color(0xFFFFEAA7)], // Golden Yellow
  ];

  static IconData _getCauseIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('stress') ||
        lower.contains('anxiety') ||
        lower.contains('tension')) {
      return Icons.psychology_rounded;
    }
    if (lower.contains('sleep') ||
        lower.contains('insomnia') ||
        lower.contains('tired')) {
      return Icons.bedtime_rounded;
    }
    if (lower.contains('coffee') ||
        lower.contains('caffeine') ||
        lower.contains('tea')) {
      return Icons.coffee_rounded;
    }
    if (lower.contains('screen') ||
        lower.contains('computer') ||
        lower.contains('phone')) {
      return Icons.devices_rounded;
    }
    if (lower.contains('food') ||
        lower.contains('sugar') ||
        lower.contains('meal') ||
        lower.contains('diet')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('water') ||
        lower.contains('dehydration') ||
        lower.contains('drink')) {
      return Icons.water_drop_rounded;
    }
    if (lower.contains('weather') ||
        lower.contains('pressure') ||
        lower.contains('heat') ||
        lower.contains('sun')) {
      return Icons.wb_sunny_rounded;
    }
    if (lower.contains('noise') || lower.contains('sound')) {
      return Icons.volume_up_rounded;
    }
    if (lower.contains('light') ||
        lower.contains('glare') ||
        lower.contains('bright')) {
      return Icons.lightbulb_rounded;
    }
    if (lower.contains('hormone') ||
        lower.contains('period') ||
        lower.contains('menstrual')) {
      return Icons.favorite_rounded;
    }
    return Icons.bubble_chart_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totalOccurrences = data.fold<int>(0, (sum, item) => sum + item.count);

    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.onSurface.withValues(alpha: 0.13)),
          color: scheme.surface.withValues(alpha: 0.74),
        ),
        child: Column(
          children: [
            Icon(
              Icons.bubble_chart_outlined,
              size: 36,
              color: scheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 8),
            const Text(
              "No triggers logged",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              "Tag causes when logging migraines to see your personalized triggers graph.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.65),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.13)),
        color: scheme.surface.withValues(alpha: 0.74),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.secondary.withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      Icons.bubble_chart_rounded,
                      size: 18,
                      color: scheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Causes & Triggers",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.22),
                  ),
                ),
                child: Text(
                  "${data.length} ${data.length == 1 ? 'trigger' : 'triggers'} ($totalOccurrences total)",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: List.generate(data.length, (index) {
                  final item = data[index];
                  final gradient =
                      _causeGradients[index % _causeGradients.length];
                  return Expanded(
                    flex: (item.percent * 1000).toInt().clamp(1, 1000),
                    child: Container(
                      margin: EdgeInsets.only(
                        right: index < data.length - 1 ? 2 : 0,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 18),
          ...List.generate(data.length, (index) {
            final item = data[index];
            final gradient =
                _causeGradients[index % _causeGradients.length];
            final icon = _getCauseIcon(item.label);
            final percentStr = (item.percent * 100).toStringAsFixed(0);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        title: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: gradient),
                              ),
                              child: Icon(icon, size: 18, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(item.label)),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Logged in ${item.count} ${item.count == 1 ? 'migraine' : 'migraines'} this month.",
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Accounts for $percentStr% of all recorded triggers.",
                              style: TextStyle(
                                color: scheme.onSurface.withValues(alpha: 0.72),
                              ),
                            ),
                            if (item.avgIntensity > 0) ...[
                              const SizedBox(height: 8),
                              Text(
                                "Average pain intensity with this trigger: ${item.avgIntensity.toStringAsFixed(1)} / 10",
                                style: TextStyle(
                                  color: scheme.onSurface.withValues(alpha: 0.72),
                                ),
                              ),
                            ],
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: scheme.onSurface.withValues(alpha: 0.03),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: gradient[0].withValues(alpha: 0.15),
                              ),
                              child: Icon(icon, size: 14, color: gradient[0]),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${item.count}x",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: scheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: gradient[0].withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "$percentStr%",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: gradient[0],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Stack(
                            children: [
                              Container(
                                height: 7,
                                color: scheme.faintTrack,
                              ),
                              FractionallySizedBox(
                                widthFactor: item.percent.clamp(0.02, 1.0),
                                child: Container(
                                  height: 7,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: gradient,
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CauseList extends StatelessWidget {
  const _CauseList({required this.data});

  final List<_CauseDatum> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text("No causes logged"));
    }
    return Column(
      children: data.take(3).map((item) {
        return GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(item.label),
                content: Text(
                  '${item.count} occurrences (${(item.percent * 100).toStringAsFixed(1)}%)',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: LinearProgressIndicator(
                    value: item.percent,
                    minHeight: 6,
                    backgroundColor: Theme.of(context).colorScheme.faintTrack,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Gauge extends StatelessWidget {
  const _Gauge({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    return Tooltip(
      message: 'Painkiller usage: $percent%',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "$percent%",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: Theme.of(context).colorScheme.faintTrack,
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  const _LineChart({required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const Center(child: Text("No entries yet"));
    }
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Intensity over last 14 days: ${values.join(', ')}',
      child: CustomPaint(
        painter: _LinePainter(
          values: values,
          lineColor: scheme.chartLine,
          pointColor: scheme.chartPoint,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.values,
    required this.lineColor,
    required this.pointColor,
  });

  final List<int> values;
  final Color lineColor;
  final Color pointColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxVal = values.reduce((a, b) => a > b ? a : b).toDouble();

    // Draw intensity zones
    const lowThreshold = 3.0; // 0-3: Low intensity
    const moderateThreshold = 6.0; // 4-6: Moderate intensity
    const maxIntensity = 10.0; // 7-10: High intensity

    // Green zone (low intensity)
    final greenHeight = (lowThreshold / maxIntensity) * size.height;
    final greenRect = Rect.fromLTWH(
      0,
      size.height - greenHeight,
      size.width,
      greenHeight,
    );
    canvas.drawRect(
      greenRect,
      Paint()..color = Color.fromARGB(40, 76, 175, 80),
    ); // Green with transparency

    // Yellow zone (moderate intensity)
    final yellowHeight =
        ((moderateThreshold - lowThreshold) / maxIntensity) * size.height;
    final yellowRect = Rect.fromLTWH(
      0,
      size.height - greenHeight - yellowHeight,
      size.width,
      yellowHeight,
    );
    canvas.drawRect(
      yellowRect,
      Paint()..color = Color.fromARGB(40, 255, 193, 7),
    ); // Yellow with transparency

    // Red zone (high intensity)
    final redHeight =
        ((maxIntensity - moderateThreshold) / maxIntensity) * size.height;
    final redRect = Rect.fromLTWH(0, 0, size.width, redHeight);
    canvas.drawRect(
      redRect,
      Paint()..color = Color.fromARGB(40, 244, 67, 54),
    ); // Red with transparency

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final step = size.width / (values.length - 1);
    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = step * i;
      final y =
          size.height -
          (values[i] / (maxVal == 0 ? 1.0 : maxVal)) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    final pointPaint = Paint()..color = pointColor;
    for (int i = 0; i < values.length; i++) {
      final x = step * i;
      final y =
          size.height -
          (values[i] / (maxVal == 0 ? 1.0 : maxVal)) * size.height;
      canvas.drawCircle(Offset(x, y), 2.6, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
