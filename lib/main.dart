import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/home_page.dart';
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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

  @override
  void initState() {
    super.initState();
    _loadProfile();
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
  }

  Future<void> _saveProfile(String name, DateTime dob) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setInt('user_dob', dob.millisecondsSinceEpoch);
    setState(() {
      _name = name;
      _dob = dob;
    });
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
