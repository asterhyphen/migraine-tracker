import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:migraine_tracker/core/theme/app_theme.dart';
import 'package:migraine_tracker/features/tracker/models/migraine_entry.dart';
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
                    const _SectionTitle(
                      title: "Trends",
                      subtitle: "Patterns across month, causes, and intensity",
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
                            title: "Causes",
                            child: _CauseList(data: causes),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _ChartCard(
                            title: "Painkiller Usage",
                            child: _Gauge(value: painkillerPercent),
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
    for (final entry in source) {
      for (final cause in entry.causes) {
        counts[cause] = (counts[cause] ?? 0) + 1;
      }
    }
    final total = counts.values.fold<int>(0, (sum, v) => sum + v);
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => _CauseDatum(e.key, e.value, total)).toList();
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
  _SummaryItem(this.title, this.value, this.subtitle);

  final String title;
  final String value;
  final String subtitle;
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
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: '$title: $value - $subtitle',
      child: Container(
        width: 170,
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
              title,
              style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
  _CauseDatum(this.label, this.count, this.total);

  final String label;
  final int count;
  final int total;

  double get percent => total == 0 ? 0 : count / total;
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
    final greenRect = Rect.fromLTWH(0, size.height - greenHeight, size.width, greenHeight);
    canvas.drawRect(greenRect, Paint()..color = Color.fromARGB(40, 76, 175, 80)); // Green with transparency

    // Yellow zone (moderate intensity)
    final yellowHeight = ((moderateThreshold - lowThreshold) / maxIntensity) * size.height;
    final yellowRect = Rect.fromLTWH(0, size.height - greenHeight - yellowHeight, size.width, yellowHeight);
    canvas.drawRect(yellowRect, Paint()..color = Color.fromARGB(40, 255, 193, 7)); // Yellow with transparency

    // Red zone (high intensity)
    final redHeight = ((maxIntensity - moderateThreshold) / maxIntensity) * size.height;
    final redRect = Rect.fromLTWH(0, 0, size.width, redHeight);
    canvas.drawRect(redRect, Paint()..color = Color.fromARGB(40, 244, 67, 54)); // Red with transparency

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
