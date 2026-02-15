import 'package:flutter/material.dart';

import '../data/migraine_db.dart';
import '../data/migraine_entry.dart';
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
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return "${date.year}-$mm-$dd";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Migraine History"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _logMissedDay,
        icon: const Icon(Icons.edit_calendar_outlined),
        label: const Text("Log missed day"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _entries.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final entry = _entries[index];
                final causes = entry.causes.isEmpty
                    ? "No cause tagged"
                    : entry.causes.join(", ");
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _formatDate(entry.date),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    "Intensity ${entry.intensity} • $causes",
                  ),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LogMigrainePage(entry: entry),
                      ),
                    );
                    await _loadEntries();
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(entry),
                  ),
                );
              },
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Entry deleted.")),
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
