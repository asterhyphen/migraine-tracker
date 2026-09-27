import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:migraine_tracker/features/settings/providers/settings_provider.dart';
import 'package:migraine_tracker/features/tracker/models/migraine_entry.dart';
import 'package:migraine_tracker/features/tracker/pages/_utils/stats_utils.dart'
    as stats_utils;
import 'package:migraine_tracker/features/tracker/pages/_widgets/stats_widgets.dart'
    as stats_widgets;
import 'package:migraine_tracker/features/tracker/pages/view_page.dart';
import 'package:migraine_tracker/features/tracker/providers/entries_provider.dart';
import 'package:migraine_tracker/core/utils/date_utils.dart';

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
      return const stats_widgets.StatsLoadingView();
    }

    final monthOptions = stats_utils.buildMonthOptions(entries);
    final selectedMonth = monthOptions.any(
      (month) => stats_utils.isSameMonth(month, _selectedMonth),
    )
        ? _selectedMonth
        : monthOptions.first;
    final compareMonth = stats_utils.validatedCompareMonth(
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
    final monthStats = stats_utils.buildWeeklyFrequency(filtered, selectedMonth);
    final avgStats = stats_utils.buildWeeklyAverages(filtered, selectedMonth);
    final causes = stats_utils.buildCauseStats(filtered);
    final painkillerPercent = stats_utils.painkillerUsage(filtered);
    final intensitySeries = filtered.reversed
        .map((e) => e.intensity)
        .toList()
        .take(14)
        .toList();
    final summary = stats_utils.buildSummary(
      filtered,
      onHighestPainDayTap: () {
        if (filtered.isNotEmpty) {
          final highestPainEntry = filtered.reduce((a, b) {
            if (a.intensity == b.intensity) {
              return a.date.isAfter(b.date) ? a : b;
            }
            return a.intensity > b.intensity ? a : b;
          });
          Navigator.of(context).push(viewMigraineRoute(entry: highestPainEntry));
        }
      },
    );
    final overallAvg = entries.isEmpty
        ? 0.0
        : entries.map((e) => e.intensity).reduce((a, b) => a + b) /
            entries.length;
    final selectedAvg = filtered.isEmpty
        ? 0.0
        : filtered.map((e) => e.intensity).reduce((a, b) => a + b) /
            filtered.length;
    final comparison = compareMonth == null
        ? <stats_utils.ComparisonItem>[]
        : stats_utils.buildComparisonItems(
            selectedSource: filtered,
            compareSource: compared,
            selectedMonth: selectedMonth,
            compareMonth: compareMonth,
          );
    final progressComparison = stats_utils.buildMonthlyProgressComparison(
      allEntries: entries,
      selectedMonth: selectedMonth,
    );
    final appSettings = ref.watch(appSettingsProvider).value;
    final isAdvancedStats = appSettings?.advancedStatsEnabled ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistics"),
        actions: [
          IconButton(
            tooltip: isAdvancedStats
                ? "Disable Pro Analytics"
                : "Enable Pro Analytics",
            icon: Icon(
              isAdvancedStats
                  ? Icons.auto_graph_rounded
                  : Icons.insights_outlined,
              color: isAdvancedStats
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: () {
              ref
                  .read(appSettingsProvider.notifier)
                  .setAdvancedStatsEnabled(!isAdvancedStats);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: entries.isEmpty
              ? const stats_widgets.StatsEmptyState()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    stats_widgets.MonthFilterCard(
                      selectedMonth: selectedMonth,
                      compareMonth: compareMonth,
                      options: monthOptions,
                      onSelectedChanged: (month) {
                        setState(() {
                          _selectedMonth = month;
                          _compareMonth = stats_utils.validatedCompareMonth(
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
                    stats_widgets.DashboardHeader(
                      totalEntries: filtered.length,
                      monthLabel: stats_utils.monthLabelFull(selectedMonth),
                      compareLabel: compareMonth == null
                          ? null
                          : stats_utils.monthLabelFull(compareMonth),
                    ),
                    const SizedBox(height: 12),
                    stats_widgets.MonthlyProgressCard(
                      comparison: progressComparison,
                    ),
                    const SizedBox(height: 16),
                    // Pro Analytics Toggle Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.12),
                        ),
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.72),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isAdvancedStats
                                ? Icons.auto_graph_rounded
                                : Icons.bar_chart_rounded,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isAdvancedStats
                                  ? "Pro Analytics View"
                                  : "Standard Summary View",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Switch.adaptive(
                            value: isAdvancedStats,
                            onChanged: (val) {
                              ref
                                  .read(appSettingsProvider.notifier)
                                  .setAdvancedStatsEnabled(val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (filtered.isEmpty) ...[
                      stats_widgets.SelectedMonthEmptyState(
                        monthLabel: stats_utils.monthLabelFull(selectedMonth),
                      ),
                      const SizedBox(height: 20),
                    ],
                    const stats_widgets.SectionTitle(
                      title: "Summary",
                      subtitle: "High-level indicators for selected month",
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: summary.map((item) {
                        return stats_widgets.InsightCard(
                          title: item.title,
                          value: item.value,
                          subtitle: item.subtitle,
                          onTap: item.onTap,
                        );
                      }).toList(),
                    ),
                    if (compareMonth != null) ...[
                      const SizedBox(height: 20),
                      const stats_widgets.SectionTitle(
                        title: "Month Comparison",
                        subtitle:
                            "Quick differences between the selected and comparison months",
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: comparison.map((item) {
                          return stats_widgets.ComparisonCard(item: item);
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    stats_widgets.SectionTitle(
                      title: "Monthly Calendar",
                      subtitle:
                          "Daily migraine log for ${stats_utils.monthLabelFull(selectedMonth)}",
                    ),
                    const SizedBox(height: 12),
                    stats_widgets.AppleCalendarCard(
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
                    const stats_widgets.SectionTitle(
                      title: "Causes & Triggers Graph",
                      subtitle:
                          "Distribution and frequency of logged causes for this month",
                    ),
                    const SizedBox(height: 12),
                    stats_widgets.CausesGraphCard(
                      data: causes,
                      totalEntries: filtered.length,
                    ),
                    const SizedBox(height: 20),
                    const stats_widgets.SectionTitle(
                      title: "Trends & Intensity",
                      subtitle:
                          "Patterns across frequency, medication, and pain levels",
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: stats_widgets.ChartCard(
                            title: "Weekly Frequency",
                            child: stats_widgets.BarChart(data: monthStats),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: stats_widgets.ChartCard(
                            title: "Weekly Avg. Intensity",
                            child: stats_widgets.BarChart(data: avgStats),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    stats_widgets.ChartCard(
                      title: "Painkiller Usage",
                      child: stats_widgets.Gauge(value: painkillerPercent),
                    ),
                    const SizedBox(height: 16),
                    stats_widgets.ChartCard(
                      title: "Intensity Graph",
                      child: Column(
                        children: [
                          Expanded(
                            child: stats_widgets.LineChart(
                              values: intensitySeries,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Overall avg ${overallAvg.toStringAsFixed(1)} • ${stats_utils.monthLabel(selectedMonth)} avg ${selectedAvg.toStringAsFixed(1)}",
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
                    if (isAdvancedStats)
                      stats_widgets.AdvancedStatsSection(
                        entries: filtered,
                        allEntries: entries,
                        selectedMonth: selectedMonth,
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
