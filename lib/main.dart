import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/home_page.dart';
import 'pages/log_migraine_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/settings_page.dart';
import 'pages/stats_page.dart';
import 'state/app_settings_provider.dart';
import 'state/migraine_entries_provider.dart';

void main() {
  runApp(const ProviderScope(child: MigraineApp()));
}

class MigraineApp extends ConsumerWidget {
  const MigraineApp({super.key});

  static const _pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
    },
  );

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

    final baseText =
        GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme).apply(
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
          borderSide: BorderSide(
            color: darkScheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: darkScheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: darkScheme.primary.withValues(alpha: 0.70),
          ),
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
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
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
      pageTransitionsTheme: _pageTransitionsTheme,
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

    final baseText =
        GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme).apply(
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
          borderSide: BorderSide(
            color: lightScheme.onSurface.withValues(alpha: 0.15),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: lightScheme.onSurface.withValues(alpha: 0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: lightScheme.primary.withValues(alpha: 0.80),
          ),
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
          side: BorderSide(
            color: lightScheme.onSurface.withValues(alpha: 0.24),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
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
      pageTransitionsTheme: _pageTransitionsTheme,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final appSettings = settings.value ?? AppSettingsState.initial();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: appSettings.themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
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

  ThemeData _birthdayTheme(BuildContext context) {
    final base = Theme.of(context);
    final scheme = base.colorScheme;
    final birthdayScheme = scheme.copyWith(
      primary: const Color(0xFFFF8A3D),
      secondary: const Color(0xFFFFC857),
      tertiary: const Color(0xFFFF6FCF),
    );
    return base.copyWith(
      colorScheme: birthdayScheme,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: birthdayScheme.surface,
        foregroundColor: birthdayScheme.onSurface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: birthdayScheme.primary,
          foregroundColor: birthdayScheme.onPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
        selectedItemColor: birthdayScheme.primary,
      ),
    );
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
      return Theme(data: _birthdayTheme(context), child: scaffold);
    }
    return scaffold;
  }
}
