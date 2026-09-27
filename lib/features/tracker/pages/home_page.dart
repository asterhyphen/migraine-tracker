import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:migraine_tracker/features/settings/providers/settings_provider.dart';
import 'package:migraine_tracker/features/tracker/models/migraine_entry.dart';
import 'package:migraine_tracker/features/tracker/providers/entries_provider.dart';
import '_utils/home_utils.dart' as home_utils;
import '_widgets/home_widgets.dart';
import '_widgets/prediction_card.dart';
import 'history_page.dart';
import 'log_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, required this.dob, this.name});

  final DateTime dob;
  final String? name;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _birthdayDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeShowBirthdayDialog();
    });
  }

  Future<void> _openLogMigraine() async {
    final entries = ref.read(migraineEntriesProvider).value ?? const [];
    final todayEntry = home_utils.entryForDate(entries, DateTime.now());
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LogMigrainePage(entry: todayEntry)),
    );
    await _loadStats();
  }

  Future<void> _openHistory() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const HistoryPage()));
  }

  Future<void> _loadStats() async {
    await ref.read(migraineEntriesProvider.notifier).reload();
    _maybeShowBirthdayDialog();
  }

  bool _isBirthdayToday() {
    return home_utils.isBirthdayToday(widget.dob);
  }

  Future<void> _maybeShowBirthdayDialog() async {
    if (_birthdayDialogShown || !_isBirthdayToday() || !mounted) return;
    final settingsRepository = ref.read(appSettingsRepositoryProvider);
    final nowYear = DateTime.now().year;
    final announcedYear = await settingsRepository.loadBirthdayAnnouncedYear();
    if (announcedYear == nowYear) return;

    _birthdayDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final scheme = Theme.of(context).colorScheme;
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        "Happy Birthday!",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.name == null || widget.name!.isEmpty
                            ? "Wishing you a great year ahead!"
                            : "Happy Birthday, ${widget.name}! Wishing you a great year ahead!",
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(
                            Icons.celebration_rounded,
                            color: scheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.auto_awesome, color: scheme.primary),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          );
        },
      );
      await settingsRepository.saveBirthdayAnnouncedYear(nowYear);
    });
  }

  @override
  Widget build(BuildContext context) {
    final entriesState = ref.watch(migraineEntriesProvider);
    final entries = entriesState.value ?? const <MigraineEntry>[];

    if (entriesState.isLoading && entriesState.value == null) {
      return const HomeLoadingView();
    }

    final now = DateTime.now();
    final monthCount = entries
        .where(
          (entry) =>
              entry.date.year == now.year && entry.date.month == now.month,
        )
        .length;
    final yearCount = entries
        .where((entry) => entry.date.year == now.year)
        .length;
    final lastEntry = entries.isEmpty ? null : entries.first;
    final todayEntry = home_utils.entryForDate(entries, now);
    final lastDays = home_utils.daysSince(lastEntry?.date);
    final lastText = lastEntry == null
        ? "No entries"
        : (lastDays == 0
              ? "Today"
              : lastDays == 1
              ? "Yesterday"
              : "$lastDays days ago");
    final lastDetails = lastEntry == null
        ? "Log your first migraine to see details."
        : "Intensity ${lastEntry.intensity} • ${home_utils.formatDate(lastEntry.date)}";
    final isBirthday = _isBirthdayToday();

    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HeroCard(
                title: isBirthday
                    ? (widget.name == null || widget.name!.isEmpty
                          ? "Happy Birthday!"
                          : "Happy Birthday, ${widget.name}!")
                    : (widget.name == null || widget.name!.isEmpty
                          ? "Welcome!"
                          : "Welcome, ${widget.name}!"),
                subtitle: isBirthday
                    ? "Today is your day. Take it easy and stay hydrated."
                    : "Age ${home_utils.calculateAge(widget.dob)} • Track migraines with clarity.",
                onTap: _openLogMigraine,
                primaryLabel: todayEntry == null
                    ? "Log Today's Entry"
                    : "Edit Today's Entry",
                primaryAction: _openLogMigraine,
                secondaryLabel: "View History",
                secondaryAction: _openHistory,
                isBirthday: isBirthday,
              ),
              if (isBirthday) ...[
                const SizedBox(height: 14),
                const BirthdayBanner(),
              ],
              const SizedBox(height: 16),
              const PredictionCard(),
              const SizedBox(height: 24),
              const SectionTitle(
                title: "At a Glance",
                subtitle: "Current period highlights",
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 148,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children:
                      [
                            StatCard(
                              title: "Last Migraine",
                              value: lastText,
                              icon: Icons.schedule_rounded,
                            ),
                            StatCard(
                              title: "This Month",
                              value: "$monthCount",
                              suffix: "events",
                              icon: Icons.calendar_month_rounded,
                            ),
                            StatCard(
                              title: "This Year",
                              value: "$yearCount",
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
              const SectionTitle(
                title: "Last Entry",
                subtitle: "Most recent recorded migraine",
              ),
              const SizedBox(height: 12),
              lastEntry == null
                  ? EmptyStateCard(
                      icon: Icons.note_add_outlined,
                      title: "No migraine logs yet",
                      subtitle:
                          "Start with your first entry to unlock trends and insights.",
                      actionLabel: "Log now",
                      onAction: _openLogMigraine,
                    )
                  : DetailCard(
                      title: "Latest log",
                      subtitle: lastDetails,
                      trailing: Text(
                        lastEntry.causes.isEmpty
                            ? "No causes tagged"
                            : lastEntry.causes.join(" • "),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
