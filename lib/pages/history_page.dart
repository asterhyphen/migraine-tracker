import 'package:flutter/material.dart';

import '../data/migraine_db.dart';
import '../data/migraine_entry.dart';

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
        actions: const [
          IconButton(
            onPressed: null,
            icon: Icon(Icons.menu),
          ),
        ],
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
                );
              },
            ),
    );
  }
}
