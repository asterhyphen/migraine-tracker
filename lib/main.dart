import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

class MigraineApp extends StatefulWidget {
  const MigraineApp({super.key});

  @override
  State<MigraineApp> createState() => _MigraineAppState();
}

class _MigraineAppState extends State<MigraineApp> {
  static const _themePrefKey = 'theme_dark_mode';
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themePrefKey) ?? true;
    if (!mounted) return;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePrefKey, isDark);
    if (!mounted) return;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  ThemeData _buildDarkTheme() {
    const background = Color(0xFF090D14);
    const darkScheme = ColorScheme.dark(
      primary: Color(0xFF65E0C2),
      secondary: Color(0xFFFFC26F),
      tertiary: Color(0xFF7E9DFF),
      surface: Color(0xFF111927),
      error: Color(0xFFFF6D7A),
      onPrimary: Color(0xFF04110D),
      onSecondary: Color(0xFF1C1200),
      onSurface: Color(0xFFE8ECF5),
      onError: Color(0xFF2D0208),
    );

    final baseText = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.dark().textTheme,
    ).apply(
      bodyColor: darkScheme.onSurface,
      displayColor: darkScheme.onSurface,
    );
    final textTheme = GoogleFonts.spaceGroteskTextTheme(baseText).copyWith(
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: darkScheme.onSurface,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: darkScheme.onSurface,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: darkScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: darkScheme.surface,
        foregroundColor: darkScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: darkScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: darkScheme.primary.withValues(alpha: 0.10)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: darkScheme.onSurface.withValues(alpha: 0.10),
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkScheme.surface.withValues(alpha: 0.95),
        hintStyle: TextStyle(
          color: darkScheme.onSurface.withValues(alpha: 0.5),
          fontWeight: FontWeight.w500,
        ),
        labelStyle: TextStyle(
          color: darkScheme.onSurface.withValues(alpha: 0.75),
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkScheme.onSurface.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkScheme.onSurface.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkScheme.primary.withValues(alpha: 0.70)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkScheme.surface.withValues(alpha: 0.90),
        selectedColor: darkScheme.primary.withValues(alpha: 0.20),
        disabledColor: darkScheme.surface.withValues(alpha: 0.50),
        side: BorderSide(color: darkScheme.onSurface.withValues(alpha: 0.15)),
        labelStyle: TextStyle(color: darkScheme.onSurface),
        secondaryLabelStyle: TextStyle(color: darkScheme.onSurface),
        brightness: Brightness.dark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkScheme.primary,
          foregroundColor: darkScheme.onPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkScheme.onSurface,
          side: BorderSide(color: darkScheme.onSurface.withValues(alpha: 0.20)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  ThemeData _buildLightTheme() {
    const background = Color(0xFFF4F7FB);
    const lightScheme = ColorScheme.light(
      primary: Color(0xFF0FA58A),
      secondary: Color(0xFFE08A00),
      tertiary: Color(0xFF4A6CF7),
      surface: Color(0xFFFFFFFF),
      error: Color(0xFFB3261E),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1A2433),
      onError: Color(0xFFFFFFFF),
    );

    final baseText = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.light().textTheme,
    ).apply(
      bodyColor: lightScheme.onSurface,
      displayColor: lightScheme.onSurface,
    );
    final textTheme = GoogleFonts.spaceGroteskTextTheme(baseText).copyWith(
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: lightScheme.onSurface,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: lightScheme.onSurface,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: lightScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: lightScheme.surface,
        foregroundColor: lightScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: lightScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: lightScheme.primary.withValues(alpha: 0.14)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: lightScheme.onSurface.withValues(alpha: 0.12),
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightScheme.surface,
        hintStyle: TextStyle(
          color: lightScheme.onSurface.withValues(alpha: 0.45),
          fontWeight: FontWeight.w500,
        ),
        labelStyle: TextStyle(
          color: lightScheme.onSurface.withValues(alpha: 0.72),
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightScheme.onSurface.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightScheme.onSurface.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightScheme.primary.withValues(alpha: 0.80)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightScheme.surface,
        selectedColor: lightScheme.primary.withValues(alpha: 0.16),
        disabledColor: lightScheme.onSurface.withValues(alpha: 0.05),
        side: BorderSide(color: lightScheme.onSurface.withValues(alpha: 0.15)),
        labelStyle: TextStyle(color: lightScheme.onSurface),
        secondaryLabelStyle: TextStyle(color: lightScheme.onSurface),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: lightScheme.primary,
          foregroundColor: lightScheme.onPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightScheme.onSurface,
          side: BorderSide(color: lightScheme.onSurface.withValues(alpha: 0.24)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightScheme.surface,
        contentTextStyle: TextStyle(color: lightScheme.onSurface),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightScheme.surface,
        selectedItemColor: lightScheme.primary,
        unselectedItemColor: lightScheme.onSurface.withValues(alpha: 0.6),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: AppShell(
        isDarkTheme: _themeMode == ThemeMode.dark,
        onThemeChanged: _setDarkMode,
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.isDarkTheme,
    required this.onThemeChanged,
  });

  final bool isDarkTheme;
  final Future<void> Function(bool isDark) onThemeChanged;

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
        isDarkTheme: widget.isDarkTheme,
        onThemeChanged: widget.onThemeChanged,
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
