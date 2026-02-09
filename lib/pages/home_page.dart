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
  int _yearCount = 0;

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
    final now = DateTime.now();
    final monthEntries = await MigraineDb.instance.getEntriesForMonth(now);
    final all = await MigraineDb.instance.getMigraineEntriesOnly();
    MigraineEntry? last;
    if (all.isNotEmpty) {
      last = all.first;
    }
    setState(() {
      _monthCount = monthEntries.length;
      _lastEntry = last;
      _streakDays = _daysSince(last?.date);
      _yearCount = all.where((e) => e.date.year == now.year).length;
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
    final lastDetails = _lastEntry == null
        ? "Log your first migraine to see details."
        : "Intensity ${_lastEntry!.intensity} • ${_formatDate(_lastEntry!.date)}";

    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroCard(
              title: widget.name == null || widget.name!.isEmpty
                  ? "Welcome!"
                  : "Welcome, ${widget.name}!",
              subtitle: "Age ${calculateAge()} • Track migraines with clarity.",
              primaryLabel: "Log Today's Migraine",
              primaryAction: _openLogMigraine,
              secondaryLabel: "View History",
              secondaryAction: _openHistory,
            ),
            const SizedBox(height: 20),
            _SectionTitle(title: "At a Glance"),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: "Last Migraine",
                    value: lastText,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: "This Month",
                    value: "$_monthCount",
                    suffix: "events",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: "Current Streak",
                    value: "$_streakDays",
                    suffix: "days",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: "This Year",
                    value: "$_yearCount",
                    suffix: "events",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionTitle(title: "Last Entry"),
            const SizedBox(height: 12),
            _DetailCard(
              title: _lastEntry == null ? "No entries yet" : "Latest log",
              subtitle: lastDetails,
              trailing: _lastEntry == null
                  ? null
                  : Text(
                      _lastEntry!.causes.isEmpty
                          ? "No causes tagged"
                          : _lastEntry!.causes.join(" • "),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return "$dd-$mm-${date.year}";
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.primaryAction,
    required this.secondaryLabel,
    required this.secondaryAction,
  });

  final String title;
  final String subtitle;
  final String primaryLabel;
  final VoidCallback primaryAction;
  final String secondaryLabel;
  final VoidCallback secondaryAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        gradient: LinearGradient(
          colors: [
            scheme.surface,
            scheme.surface.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: primaryAction,
                  child: Text(primaryLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: secondaryAction,
                  child: Text(secondaryLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    this.suffix,
  });

  final String title;
  final String value;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 6),
                Text(
                  suffix!,
                  style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(subtitle),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            Expanded(child: trailing!),
          ],
        ],
      ),
    );
  }
}
