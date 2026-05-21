import 'package:flutter/material.dart';
import 'package:migraine_tracker/features/tracker/models/migraine_entry.dart';
import 'package:migraine_tracker/core/utils/date_utils.dart';

class HistorySearchField extends StatelessWidget {
  const HistorySearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Clear search',
              ),
        hintText: 'Search history',
        filled: true,
        fillColor: scheme.surface.withValues(alpha: 0.72),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: scheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: scheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
      ),
    );
  }
}

class HistoryNoResultsState extends StatelessWidget {
  const HistoryNoResultsState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.12)),
        color: scheme.surface.withValues(alpha: 0.72),
      ),
      child: Row(
        children: [
          Icon(Icons.search_off_rounded, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No entries found for "$query".',
              style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.72)),
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryEmptyState extends StatelessWidget {
  const HistoryEmptyState({required this.onLogMissedDay});

  final VoidCallback onLogMissedDay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.12)),
        color: scheme.surface.withValues(alpha: 0.72),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_toggle_off_rounded, color: scheme.primary),
              const SizedBox(width: 8),
              const Text(
                "No history yet",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "When you log entries, they will appear here for quick edit and review.",
            style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.72)),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onLogMissedDay,
            child: const Text("Log missed day"),
          ),
        ],
      ),
    );
  }
}

class HistorySummaryCard extends StatelessWidget {
  const HistorySummaryCard({required this.entries});

  final List<MigraineEntry> entries;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final latest = entries.first;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.12)),
        gradient: LinearGradient(
          colors: [
            scheme.surface.withValues(alpha: 0.86),
            scheme.surface.withValues(alpha: 0.70),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: 0.18),
            ),
            child: Icon(Icons.history_rounded, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${entries.length} total entries",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  "Latest: ${formatDayAndDate(latest.date)}",
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.68),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryEntryCard extends StatelessWidget {
  const HistoryEntryCard({
    required this.entry,
    required this.formatDay,
    required this.formatDate,
    required this.onTap,
    required this.onDelete,
  });

  final MigraineEntry entry;
  final String Function(DateTime) formatDay;
  final String Function(DateTime) formatDate;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final causes = entry.causes.isEmpty
        ? "Unknown"
        : entry.causes.take(3).join(" • ");

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.onSurface.withValues(alpha: 0.12)),
            color: scheme.surface.withValues(alpha: 0.72),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: scheme.primary.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(
                    entry.intensity.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatDay(entry.date),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatDate(entry.date),
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.72),
                        fontSize: 12,
                      ),
                    ),
                    if (causes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        causes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                tooltip: "Delete entry",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MonthHeader extends StatelessWidget {
  const MonthHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
