import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'package:migraine_tracker/features/tracker/models/migraine_entry.dart';
import 'package:migraine_tracker/features/tracker/providers/entries_provider.dart';
import 'package:migraine_tracker/core/utils/date_utils.dart';
import 'package:migraine_tracker/core/widgets/app_snackbar.dart';
import 'package:migraine_tracker/core/theme/app_theme.dart';
import 'log_page.dart';

class ViewMigrainePage extends ConsumerWidget {
  const ViewMigrainePage({super.key, required this.entry});

  final MigraineEntry entry;

  String _formatDate(DateTime date) {
    return formatDdMmYyyy(date);
  }

  String _formatDay(DateTime date) {
    return formatDay(date);
  }

  Future<void> _deleteEntry(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete entry?"),
          content: const Text("Are you sure? This action is irreversible."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await ref.read(migraineEntriesProvider.notifier).deleteEntry(entry.id!);
    if (!context.mounted) return;
    HapticFeedback.mediumImpact();
    AppSnackBar.showSuccess(
      context,
      title: 'Entry deleted',
      message: 'The migraine log was removed.',
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final entriesState = ref.watch(migraineEntriesProvider);
    final comparisonStats = entriesState.maybeWhen(
      data: _buildComparisonStats,
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("View Migraine"),
        actions: [
          IconButton(
            onPressed: () async {
              // ignore: use_build_context_synchronously
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => LogMigrainePage(entry: entry),
                ),
              );
              // ignore: use_build_context_synchronously
              if (!context.mounted) return;
              if (result == true) {
                await ref.read(migraineEntriesProvider.notifier).reload();
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.edit_outlined),
            tooltip: "Edit",
          ),
          IconButton(
            onPressed: () => _deleteEntry(context, ref),
            icon: const Icon(Icons.delete_outline),
            tooltip: "Delete",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Section
            Container(
              width: double.infinity,
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
                    "Date",
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${_formatDate(entry.date)} (${_formatDay(entry.date)})",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Intensity Section
            Container(
              width: double.infinity,
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
                    "Intensity",
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        "${entry.intensity}/10",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: entry.intensity / 10,
                            minHeight: 8,
                            backgroundColor: scheme.faintTrack,
                            valueColor: AlwaysStoppedAnimation(
                              _getIntensityColor(entry.intensity, scheme),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (comparisonStats != null) ...[
              _ComparisonStatsCard(stats: comparisonStats),
              const SizedBox(height: 16),
            ],

            // Painkillers Section
            Container(
              width: double.infinity,
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
                    "Painkillers",
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Chip(
                    label: Text(entry.painkillers ? "Yes" : "No"),
                    backgroundColor: entry.painkillers
                        ? scheme.primary.withValues(alpha: 0.2)
                        : scheme.errorContainer,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Causes Section
            if (entry.causes.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
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
                          "Probable Causes",
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: entry.causes
                              .map(
                                (cause) => Chip(
                                  label: Text(cause),
                                  backgroundColor: scheme.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Notes Section
            if (entry.notes.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
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
                          "Notes",
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(entry.notes),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Edit Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  // ignore: use_build_context_synchronously
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => LogMigrainePage(entry: entry),
                    ),
                  );
                  // ignore: use_build_context_synchronously
                  if (!context.mounted) return;
                  if (result == true) {
                    await ref.read(migraineEntriesProvider.notifier).reload();
                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.edit),
                label: const Text("Edit Entry"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getIntensityColor(int intensity, ColorScheme scheme) {
    if (intensity <= 3) {
      return Color.fromARGB(255, 76, 175, 80); // Green
    } else if (intensity <= 6) {
      return Color.fromARGB(255, 255, 193, 7); // Yellow
    } else {
      return Color.fromARGB(255, 244, 67, 54); // Red
    }
  }

  _EntryComparisonStats? _buildComparisonStats(List<MigraineEntry> entries) {
    final migraineEntries = entries.where((candidate) {
      if (!candidate.hadMigraine) return false;
      if (entry.id != null && candidate.id == entry.id) return true;
      return _isSameDay(candidate.date, entry.date);
    }).toList();

    final comparisonPool = entries.where((candidate) {
      if (!candidate.hadMigraine) return false;
      if (entry.id != null) return candidate.id != entry.id;
      return !_isSameDay(candidate.date, entry.date);
    }).toList();

    final currentEntry = migraineEntries.isNotEmpty
        ? migraineEntries.first
        : entry;

    if (comparisonPool.isEmpty) return null;

    final averageIntensity =
        comparisonPool.map((e) => e.intensity).reduce((a, b) => a + b) /
        comparisonPool.length;
    final monthEntries = comparisonPool
        .where((candidate) => _isSameMonth(candidate.date, currentEntry.date))
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

    return _EntryComparisonStats(
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }
}

class _EntryComparisonStats {
  const _EntryComparisonStats({
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

class _ComparisonStatsCard extends StatelessWidget {
  const _ComparisonStatsCard({required this.stats});

  final _EntryComparisonStats stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
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
            "Compared with your logs",
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 340;
              final cards = [
                _StatTile(
                  label: "Overall avg",
                  value: stats.averageIntensity.toStringAsFixed(1),
                  detail: _deltaLabel(stats.intensityDelta),
                ),
                _StatTile(
                  label: "This month avg",
                  value: stats.monthAverageIntensity?.toStringAsFixed(1) ?? "-",
                  detail: stats.monthIntensityDelta == null
                      ? "No other logs"
                      : _deltaLabel(stats.monthIntensityDelta!),
                ),
                _StatTile(
                  label: "Range",
                  value: "${stats.minIntensity}-${stats.maxIntensity}",
                  detail: "Above ${stats.percentile}% of logs",
                ),
              ];

              if (isNarrow) {
                return Column(
                  children: [
                    for (final card in cards) ...[
                      card,
                      if (card != cards.last) const SizedBox(height: 8),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (final card in cards) ...[
                    Expanded(child: card),
                    if (card != cards.last) const SizedBox(width: 8),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            "Based on ${stats.totalCompared} other ${stats.totalCompared == 1 ? 'migraine entry' : 'migraine entries'}.",
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }

  static String _deltaLabel(double value) {
    final absValue = value.abs().toStringAsFixed(1);
    if (value.abs() < 0.05) return "Same as avg";
    return value > 0 ? "$absValue above avg" : "$absValue below avg";
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: scheme.primary.withValues(alpha: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: scheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: scheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}
