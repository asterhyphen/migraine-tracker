import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'package:migraine_tracker/features/tracker/models/migraine_entry.dart';
import 'package:migraine_tracker/features/tracker/providers/entries_provider.dart';
import 'package:migraine_tracker/core/utils/date_utils.dart';
import 'package:migraine_tracker/core/widgets/app_snackbar.dart';
import 'log_page.dart';
import 'view_page.dart';
import '_utils/history_utils.dart';
import '_widgets/history_widgets.dart';

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

  List<Widget> _buildListChildren(
    Map<String, List<MigraineEntry>> groupedEntries,
  ) {
    final allEntries = groupedEntries.values.expand((e) => e).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: HistorySummaryCard(entries: allEntries),
      ),
    ];
    for (final group in groupedEntries.entries) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: MonthHeader(title: group.key),
        ),
      );
      for (final entry in group.value) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: HistoryEntryCard(
              entry: entry,
              formatDay: (date) => formatDay(date),
              formatDate: (date) => formatDdMmYyyy(date),
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
    final filteredEntries = filterEntries(entries, _searchQuery);
    final groupedEntries = groupByMonth(filteredEntries);
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
                        HistoryEmptyState(onLogMissedDay: _logMissedDay),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      children: [
                        HistorySearchField(
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
                          HistoryNoResultsState(query: _searchQuery)
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
