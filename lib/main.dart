import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/migraine_db.dart';
import 'pages/home_page.dart';
import 'pages/log_migraine_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/settings_page.dart';
import 'pages/stats_page.dart';

void main() {
  runApp(const MigraineApp());
}

class MigraineApp extends StatelessWidget {
  const MigraineApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0F1115);
    const darkScheme = ColorScheme.dark(
      primary: Color(0xFF4FD1C5),
      secondary: Color(0xFFF6AE2D),
      surface: Color(0xFF171A21),
      error: Color(0xFFF97066),
      onPrimary: Color(0xFF0B0D10),
      onSecondary: Color(0xFF0B0D10),
      onSurface: Color(0xFFF5F7FA),
      onError: Color(0xFF0B0D10),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: darkScheme,
        scaffoldBackgroundColor: background,
        appBarTheme: AppBarTheme(
          backgroundColor: darkScheme.surface,
          foregroundColor: darkScheme.onSurface,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: darkScheme.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: darkScheme.surface,
          contentTextStyle: TextStyle(color: darkScheme.onSurface),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: darkScheme.surface,
          selectedItemColor: darkScheme.primary,
          unselectedItemColor: darkScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  bool _loadingProfile = true;
  String? _name;
  DateTime? _dob;
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _appLinkSubscription;
  bool _pendingOpenLog = false;
  bool _linkInitialized = false;

  @override
  void initState() {
    super.initState();
    _setupDeepLinks();
    _loadProfile();
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
    final isLogLink = uri.scheme == 'migraine-tracker' &&
        (uri.host == 'log' || uri.path == '/log');

    if (!isLogLink) return;

    if (_loadingProfile || _name == null || _dob == null) {
      _pendingOpenLog = true;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openLogFromExternalAction();
    });
  }

  Future<void> _openLogFromExternalAction() async {
    final todayEntry = await MigraineDb.instance.getEntryForDate(DateTime.now());
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LogMigrainePage(entry: todayEntry),
      ),
    );
  }

  void _processPendingAction() {
    if (!_pendingOpenLog) return;
    if (_loadingProfile || _name == null || _dob == null) return;
    _pendingOpenLog = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openLogFromExternalAction();
    });
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name');
    final dobMillis = prefs.getInt('user_dob');
    setState(() {
      _name = name;
      _dob = dobMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(dobMillis);
      _loadingProfile = false;
    });
    _processPendingAction();
  }

  Future<void> _saveProfile(String name, DateTime dob) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setInt('user_dob', dob.millisecondsSinceEpoch);
    setState(() {
      _name = name;
      _dob = dob;
    });
    _processPendingAction();
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingProfile) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_name == null || _dob == null) {
      return OnboardingPage(onSave: _saveProfile);
    }

    final pages = [
      HomePage(dob: _dob!, name: _name),
      const StatsPage(),
      SettingsPage(
        initialName: _name!,
        initialDob: _dob!,
        onSave: _saveProfile,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Stats",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}
