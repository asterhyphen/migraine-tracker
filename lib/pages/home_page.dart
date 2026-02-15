import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'history_page.dart';
import 'log_migraine_page.dart';
import '../data/migraine_db.dart';
import '../data/migraine_entry.dart';
import '../utils/date_utils.dart';
import '../widgets/wavy_surface.dart';

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
  bool _birthdayDialogShown = false;
  MigraineEntry? _lastEntry;
  MigraineEntry? _todayEntry;
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
      MaterialPageRoute(
        builder: (_) => LogMigrainePage(entry: _todayEntry),
      ),
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
    final todayEntry = await MigraineDb.instance.getEntryForDate(now);
    final all = await MigraineDb.instance.getMigraineEntriesOnly();
    MigraineEntry? last;
    if (all.isNotEmpty) {
      last = all.first;
    }
    setState(() {
      _monthCount = monthEntries.length;
      _lastEntry = last;
      _todayEntry = todayEntry;
      _streakDays = _daysSince(last?.date);
      _yearCount = all.where((e) => e.date.year == now.year).length;
      _loading = false;
    });
    _maybeShowBirthdayDialog();
  }

  bool _isBirthdayToday() {
    final now = DateTime.now();
    return now.month == widget.dob.month && now.day == widget.dob.day;
  }

  Future<void> _maybeShowBirthdayDialog() async {
    if (_birthdayDialogShown || !_isBirthdayToday() || !mounted) return;
    _birthdayDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Happy Birthday!"),
            content: Text(
              widget.name == null || widget.name!.isEmpty
                  ? "Wishing you a great year ahead!"
                  : "Happy Birthday, ${widget.name}! Wishing you a great year ahead!",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Tadaa!"),
              ),
            ],
          );
        },
      );
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
    final isBirthday = _isBirthdayToday();

    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroCard(
              title: isBirthday
                  ? (widget.name == null || widget.name!.isEmpty
                        ? "Happy Birthday!"
                        : "Happy Birthday, ${widget.name}!")
                  : (widget.name == null || widget.name!.isEmpty
                        ? "Welcome!"
                        : "Welcome, ${widget.name}!"),
              subtitle: isBirthday
                  ? "Today is your day. Take it easy and stay hydrated."
                  : "Age ${calculateAge()} • Track migraines with clarity.",
              primaryLabel: _todayEntry == null
                  ? "Log Today's Migraine"
                  : "Edit Today's Migraine",
              primaryAction: _openLogMigraine,
              secondaryLabel: "View History",
              secondaryAction: _openHistory,
              isBirthday: isBirthday,
            ),
            if (isBirthday) ...[
              const SizedBox(height: 14),
              const _BirthdayBanner(),
            ],
            const SizedBox(height: 24),
            const _SectionTitle(
              title: "At a Glance",
              subtitle: "Current period highlights",
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 148,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _StatCard(
                    title: "Last Migraine",
                    value: lastText,
                    icon: Icons.schedule_rounded,
                  ),
                  _StatCard(
                    title: "This Month",
                    value: "$_monthCount",
                    suffix: "events",
                    icon: Icons.calendar_month_rounded,
                  ),
                  _StatCard(
                    title: "Current Streak",
                    value: "$_streakDays",
                    suffix: "days",
                    icon: Icons.bolt_rounded,
                  ),
                  _StatCard(
                    title: "This Year",
                    value: "$_yearCount",
                    suffix: "events",
                    icon: Icons.insights_rounded,
                  ),
                ]
                    .map(
                      (card) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: card,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle(
              title: "Last Entry",
              subtitle: "Most recent recorded migraine",
            ),
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
    return formatDdMmYyyy(date);
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
    required this.isBirthday,
  });

  final String title;
  final String subtitle;
  final String primaryLabel;
  final VoidCallback primaryAction;
  final String secondaryLabel;
  final VoidCallback secondaryAction;
  final bool isBirthday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return WavySurface(
      borderRadius: BorderRadius.circular(20),
      borderColor: scheme.primary.withValues(alpha: 0.20),
      gradient: LinearGradient(
        colors: [
          isBirthday
              ? scheme.secondary.withValues(alpha: 0.22)
              : scheme.surface,
          isBirthday
              ? scheme.tertiary.withValues(alpha: 0.24)
              : scheme.tertiary.withValues(alpha: 0.14),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomRight,
      ),
      waveColorA: isBirthday
          ? scheme.primary.withValues(alpha: 0.18)
          : scheme.primary.withValues(alpha: 0.10),
      waveColorB: isBirthday
          ? scheme.secondary.withValues(alpha: 0.16)
          : scheme.secondary.withValues(alpha: 0.08),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isBirthday ? "Birthday Mode" : "Daily Tracker",
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isBirthday) ...[
                  const SizedBox(width: 8),
                  const _TadaaBadge(),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.76),
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
      ),
    );
  }
}

class _BirthdayBanner extends StatelessWidget {
  const _BirthdayBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.secondary.withValues(alpha: 0.35)),
        color: scheme.secondary.withValues(alpha: 0.14),
      ),
      child: Row(
        children: [
          Icon(Icons.celebration_rounded, color: scheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Happy Birthday! Take it easy today and keep your migraine log up to date.",
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TadaaBadge extends StatefulWidget {
  const _TadaaBadge();

  @override
  State<_TadaaBadge> createState() => _TadaaBadgeState();
}

class _TadaaBadgeState extends State<_TadaaBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final angle = math.sin(t * math.pi * 2) * 0.12;
        final scale = 1 + (math.sin(t * math.pi) * 0.08);
        return Transform.rotate(
          angle: angle,
          child: Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: scheme.secondary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                "Tadaa",
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            color: scheme.onSurface.withValues(alpha: 0.62),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.suffix,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 172, maxWidth: 172),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.13)),
        gradient: LinearGradient(
          colors: [
            scheme.surface.withValues(alpha: 0.98),
            scheme.surface.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: 0.14),
            ),
            child: Icon(icon, size: 16, color: scheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.72),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 6),
                Text(
                  suffix!,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.68),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.13)),
        color: scheme.surface.withValues(alpha: 0.72),
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
