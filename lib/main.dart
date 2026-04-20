import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/models/app_settings.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/tracker/pages/home_page.dart';
import 'features/tracker/pages/log_page.dart';
import 'features/tracker/pages/stats_page.dart';
import 'features/tracker/providers/entries_provider.dart';
import 'features/settings/pages/onboarding_page.dart';
import 'features/settings/pages/settings_page.dart';

void main() {
  runApp(const ProviderScope(child: MigraineApp()));
}

class MigraineApp extends ConsumerWidget {
  const MigraineApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final appSettings = settings.value ?? AppSettings.initial();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: appSettings.themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const AppShell(),
    );
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _appLinkSubscription;
  bool _pendingOpenLog = false;
  bool _linkInitialized = false;
  bool _openingLogFromExternalAction = false;
  DateTime? _lastHandledLogAt;
  String? _lastHandledLogKey;

  @override
  void initState() {
    super.initState();
    _setupDeepLinks();
  }

  @override
  void dispose() {
    _appLinkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _setupDeepLinks() async {
    _appLinks = AppLinks();

    if (!_linkInitialized) {
      _linkInitialized = true;
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingLink(initialUri);
      }
    }

    _appLinkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleIncomingLink(uri);
    });
  }

  void _handleIncomingLink(Uri uri) {
    final normalizedPath = uri.path.replaceAll(RegExp(r'^/+|/+$'), '');
    final isLogLink =
        uri.scheme == 'migraine-tracker' &&
        (uri.host == 'log' ||
            normalizedPath == 'log' ||
            (uri.host.isEmpty && uri.path == 'log'));

    if (!isLogLink) return;

    final now = DateTime.now();
    final logKey = "${uri.scheme}://${uri.host}${uri.path}";
    final isDuplicate =
        _lastHandledLogKey == logKey &&
        _lastHandledLogAt != null &&
        now.difference(_lastHandledLogAt!).inMilliseconds < 1500;
    if (isDuplicate) return;
    _lastHandledLogKey = logKey;
    _lastHandledLogAt = now;

    final settings = ref.read(appSettingsProvider).value;
    if (settings == null || !settings.hasProfile) {
      _pendingOpenLog = true;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openLogFromExternalAction();
    });
  }

  Future<void> _openLogFromExternalAction() async {
    if (_openingLogFromExternalAction) return;
    _openingLogFromExternalAction = true;
    try {
      final todayEntry = await ref
          .read(migraineEntriesProvider.notifier)
          .entryForDate(DateTime.now());
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LogMigrainePage(entry: todayEntry)),
      );
    } finally {
      _openingLogFromExternalAction = false;
    }
  }

  void _processPendingAction() {
    if (!_pendingOpenLog) return;
    final settings = ref.read(appSettingsProvider).value;
    if (settings == null || !settings.hasProfile) return;
    _pendingOpenLog = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openLogFromExternalAction();
    });
  }

  Future<void> _saveProfile(String name, DateTime dob) async {
    await ref.read(appSettingsProvider.notifier).saveProfile(name, dob);
    _processPendingAction();
  }

  Future<void> _saveProfileImage(String? imagePath) async {
    await ref.read(appSettingsProvider.notifier).saveProfileImage(imagePath);
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  bool _isBirthdayToday() {
    final dob = ref.read(appSettingsProvider).value?.dob;
    if (dob == null) return false;
    final now = DateTime.now();
    return now.month == dob.month && now.day == dob.day;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appSettingsProvider, (_, next) => _processPendingAction());

    final settings = ref.watch(appSettingsProvider);
    final appSettings = settings.value;

    if (settings.isLoading && appSettings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (settings.hasError && appSettings == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Could not load app settings: ${settings.error}'),
          ),
        ),
      );
    }

    if (appSettings == null || !appSettings.hasProfile) {
      return OnboardingPage(onSave: _saveProfile);
    }

    final pages = [
      HomePage(dob: appSettings.dob!, name: appSettings.name),
      const StatsPage(),
      SettingsPage(
        initialName: appSettings.name!,
        initialDob: appSettings.dob!,
        initialProfileImagePath: appSettings.profileImagePath,
        onSave: _saveProfile,
        onProfileImageChanged: _saveProfileImage,
        isDarkTheme: appSettings.isDarkTheme,
        onThemeChanged: ref.read(appSettingsProvider.notifier).setDarkMode,
      ),
    ];

    final scaffold = Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Stats"),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );

    if (_isBirthdayToday()) {
      return Theme(data: AppTheme.birthday(context), child: scaffold);
    }
    return scaffold;
  }
}
