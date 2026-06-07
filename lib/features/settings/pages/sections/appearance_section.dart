import 'package:flutter/material.dart';

import '../widgets/settings_card.dart';

class AppearanceSection extends StatelessWidget {
  const AppearanceSection({
    required this.isDarkTheme,
    required this.onThemeChanged,
  });

  final bool isDarkTheme;
  final ValueChanged<bool> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      child: SwitchListTile(
        value: isDarkTheme,
        onChanged: onThemeChanged,
        title: const Text("Dark theme"),
        subtitle: Text(isDarkTheme ? "Enabled (default)" : "Light mode"),
        secondary: const Icon(Icons.dark_mode_outlined),
      ),
    );
  }
}
