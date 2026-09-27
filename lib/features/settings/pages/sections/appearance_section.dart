import 'package:flutter/material.dart';

import '../widgets/settings_card.dart';

class AppearanceSection extends StatelessWidget {
  const AppearanceSection({
    super.key,
    required this.isDarkTheme,
    required this.onThemeChanged,
    required this.advancedStatsEnabled,
    required this.onAdvancedStatsChanged,
  });

  final bool isDarkTheme;
  final ValueChanged<bool> onThemeChanged;
  final bool advancedStatsEnabled;
  final ValueChanged<bool> onAdvancedStatsChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      child: Column(
        children: [
          SwitchListTile(
            value: isDarkTheme,
            onChanged: onThemeChanged,
            title: const Text("Dark theme"),
            subtitle: Text(isDarkTheme ? "Enabled (default)" : "Light mode"),
            secondary: const Icon(Icons.dark_mode_outlined),
          ),
          const Divider(height: 1),
          SwitchListTile(
            value: advancedStatsEnabled,
            onChanged: onAdvancedStatsChanged,
            title: const Text("Advanced analytics"),
            subtitle: Text(
              advancedStatsEnabled
                  ? "Correlation matrix, periodicity intervals & pro metrics"
                  : "Standard summary graphs",
            ),
            secondary: const Icon(Icons.insights_outlined),
          ),
        ],
      ),
    );
  }
}
