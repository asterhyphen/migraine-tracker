import 'package:flutter/material.dart';

import 'package:migraine_tracker/core/theme/app_theme.dart';

class SettingsCard extends StatelessWidget {
  const SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.faintTrack),
        color: scheme.surface,
      ),
      child: child,
    );
  }
}
