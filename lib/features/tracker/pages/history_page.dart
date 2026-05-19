import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'package:migraine_tracker/features/tracker/models/migraine_entry.dart';
import 'package:migraine_tracker/features/tracker/providers/entries_provider.dart';
import 'package:migraine_tracker/core/utils/date_utils.dart';
import 'package:migraine_tracker/core/widgets/app_snackbar.dart';
import 'log_page.dart';
import 'view_page.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    await ref.read(migraineEntriesProvider.notifier).reload();
  }

  Map<String, List<MigraineEntry>> _groupByMonth(List<MigraineEntry> entries) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final map = <String, List<MigraineEntry>>{};
    for (final entry in entries) {
      final key = '${monthNames[entry.date.month - 1]} ${entry.date.year}';
      map.putIfAbsent(key, () => []).add(entry);
    }
    // Sort keys by year desc, month desc
    final sortedKeys = map.keys.toList()
      ..sort((a, b) {
        final aParts = a.split(' ');
        final bParts = b.split(' ');
        final aYear = int.parse(aParts[1]);
        final bYear = int.parse(bParts[1]);
        if (aYear != bYear) return bYear.compareTo(aYear);
        final aMonth = monthNames.indexOf(aParts[0]);
        final bMonth = monthNames.indexOf(bParts[0]);
        return bMonth.compareTo(aMonth);
      });
    final sortedMap = <String, List<MigraineEntry>>{};
    for (final key in sortedKeys) {
      sortedMap[key] = map[key]!;
    }
    return sortedMap;
  }

  String _formatDate(DateTime date) {
    return formatDdMmYyyy(date);
  }

  String _formatDay(DateTime date) {
    return formatDay(date);
  }

  List<MigraineEntry> _filterEntries(List<MigraineEntry> entries) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return entries;

    return entries.where((entry) {
      final haystack = [
        formatDdMmYyyy(entry.date),
        formatDay(entry.date),
        entry.intensity.toString(),
        entry.painkillers ? 'painkillers' : 'no painkillers',
        entry.notes,
        ...entry.causes,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  List<Widget> _buildListChildren(
    Map<String, List<MigraineEntry>> groupedEntries,
  ) {
    final allEntries = groupedEntries.values.expand((e) => e).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: _HistorySummaryCard(entries: allEntries),
      ),
    ];
    for (final group in groupedEntries.entries) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: _MonthHeader(title: group.key),
        ),
      );
      for (final entry in group.value) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _HistoryEntryCard(
              entry: entry,
              formatDay: _formatDay,
              formatDate: _formatDate,
              onTap: () async {
                await Navigator.of(
                  context,
                ).push(viewMigraineRoute(entry: entry));
                await _loadEntries();
              },
              onDelete: () => _confirmDelete(entry),
            ),
          ),
        );
      }
    }
    return children;
  }

  @override
  Widget build(BuildContext context) {
    final entriesState = ref.watch(migraineEntriesProvider);
    final entries = entriesState.value ?? const <MigraineEntry>[];
    final filteredEntries = _filterEntries(entries);
    final groupedEntries = _groupByMonth(filteredEntries);
    final hasSearch = _searchQuery.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text("Migraine History")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _logMissedDay,
        icon: const Icon(Icons.edit_calendar_outlined),
        label: const Text("Log missed day"),
      ),
      body: entriesState.isLoading && entriesState.value == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEntries,
              child: entries.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      children: [
                        _HistoryEmptyState(onLogMissedDay: _logMissedDay),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      children: [
                        _HistorySearchField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          onClear: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        if (groupedEntries.isEmpty && hasSearch)
                          _HistoryNoResultsState(query: _searchQuery)
                        else
                          ..._buildListChildren(groupedEntries),
                      ],
                    ),
            ),
    );
  }

  Future<void> _confirmDelete(MigraineEntry entry) async {
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
    if (entry.id == null) return;
    await ref.read(migraineEntriesProvider.notifier).deleteEntry(entry.id!);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    AppSnackBar.showSuccess(
      context,
      title: 'Entry deleted',
      message: 'The migraine log was removed from history.',
    );
  }

  Future<void> _logMissedDay() async {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: yesterday,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null) return;

    final existing = await ref
        .read(migraineEntriesProvider.notifier)
        .entryForDate(picked);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LogMigrainePage(
          entry: existing,
          initialDate: existing == null ? picked : null,
        ),
      ),
    );
    await _loadEntries();
  }
}

class _HistorySearchField extends StatelessWidget {
  const _HistorySearchField({
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

class _HistoryNoResultsState extends StatelessWidget {
  const _HistoryNoResultsState({required this.query});

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

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState({required this.onLogMissedDay});

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

class _HistorySummaryCard extends StatelessWidget {
  const _HistorySummaryCard({required this.entries});

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

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({
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

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.title});

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
