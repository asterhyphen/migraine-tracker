import 'package:flutter/material.dart';
import 'history_page.dart';
import 'log_migraine_page.dart';
import '../data/migraine_db.dart';
import '../data/migraine_entry.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.dob,
    this.name,
  });

  final DateTime dob;
  final String? name;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loading = true;
  MigraineEntry? _lastEntry;
  int _monthCount = 0;
  int _streakDays = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  int calculateAge() {
    DateTime today = DateTime.now();
    int age = today.year - widget.dob.year;

    if (today.month < widget.dob.month ||
        (today.month == widget.dob.month && today.day < widget.dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _openLogMigraine() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LogMigrainePage()),
    );
    await _loadStats();
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HistoryPage()),
    );
  }

  Future<void> _loadStats() async {
    final monthEntries =
        await MigraineDb.instance.getEntriesForMonth(DateTime.now());
    final all = await MigraineDb.instance.getMigraineEntriesOnly();
    MigraineEntry? last;
    if (all.isNotEmpty) {
      last = all.first;
    }
    setState(() {
      _monthCount = monthEntries.length;
      _lastEntry = last;
      _streakDays = _daysSince(last?.date);
      _loading = false;
    });
  }

  int _daysSince(DateTime? date) {
    if (date == null) return 0;
    final now = DateTime.now();
    final delta = now.difference(DateTime(date.year, date.month, date.day));
    return delta.inDays;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final lastText = _lastEntry == null
        ? "No entries"
        : "${_daysSince(_lastEntry!.date)} days ago";

    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.white12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      widget.name == null || widget.name!.isEmpty
                          ? "Welcome!"
                          : "Welcome, ${widget.name}!",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Age: ${calculateAge()}",
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _openLogMigraine,
                        child: const Text("Log Today's Migraine"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _SummaryTile(
              title: "Last Migraine",
              value: lastText,
            ),
            const SizedBox(height: 10),
            _SummaryTile(
              title: "This Month",
              value: "$_monthCount migraines",
            ),
            const SizedBox(height: 10),
            _SummaryTile(
              title: "Current Streak",
              value: "$_streakDays days",
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _openHistory,
              child: const Text("View History"),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "$title:",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}
