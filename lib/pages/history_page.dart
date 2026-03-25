import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/migraine_db.dart';
import '../data/migraine_entry.dart';
import '../utils/date_utils.dart';
import '../widgets/app_snackbar.dart';
import 'log_migraine_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _loading = true;
  List<MigraineEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final entries = await MigraineDb.instance.getMigraineEntriesOnly();
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  String _formatDate(DateTime date) {
    return formatDayAndDate(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Migraine History")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _logMissedDay,
        icon: const Icon(Icons.edit_calendar_outlined),
        label: const Text("Log missed day"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEntries,
              child: _entries.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      children: [
                        _HistoryEmptyState(onLogMissedDay: _logMissedDay),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      itemCount: _entries.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _HistorySummaryCard(entries: _entries),
                          );
                        }

                        final entry = _entries[index - 1];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _HistoryEntryCard(
                            entry: entry,
                            formatDate: _formatDate,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => LogMigrainePage(entry: entry),
                                ),
                              );
                              await _loadEntries();
                            },
                            onDelete: () => _confirmDelete(entry),
                          ),
                        );
                      },
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
          content: const Text("This cannot be undone."),
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
    await MigraineDb.instance.deleteEntry(entry.id!);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    AppSnackBar.showSuccess(
      context,
      title: 'Entry deleted',
      message: 'The migraine log was removed from history.',
    );
    await _loadEntries();
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

    final existing = await MigraineDb.instance.getEntryForDate(picked);
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
    required this.formatDate,
    required this.onTap,
    required this.onDelete,
  });

  final MigraineEntry entry;
  final String Function(DateTime) formatDate;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final causes = entry.causes.isEmpty
        ? "No cause tagged"
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
                      formatDate(entry.date),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
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
