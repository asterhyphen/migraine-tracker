import 'package:flutter/material.dart';

import '../widgets/settings_card.dart';

class AnalyticsSection extends StatelessWidget {
  const AnalyticsSection({
    super.key,
    required this.advancedStatsEnabled,
    required this.onAdvancedStatsChanged,
  });

  final bool advancedStatsEnabled;
  final ValueChanged<bool> onAdvancedStatsChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SettingsCard(
      child: Column(
        children: [
          SwitchListTile(
            value: advancedStatsEnabled,
            onChanged: onAdvancedStatsChanged,
            title: const Text(
              "Advanced Pro Analytics",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              advancedStatsEnabled
                  ? "Active: Multi-trigger correlation matrix, attack periodicity intervals, day-of-week distributions, and medication risk indicators."
                  : "Standard view: Monthly frequency, averages, painkiller rates, and calendar view.",
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: advancedStatsEnabled
                    ? scheme.primary.withValues(alpha: 0.15)
                    : scheme.onSurface.withValues(alpha: 0.08),
              ),
              child: Icon(
                Icons.auto_graph_rounded,
                color: advancedStatsEnabled
                    ? scheme.primary
                    : scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
