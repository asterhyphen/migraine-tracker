import 'package:flutter/material.dart';

import '../widgets/settings_card.dart';
import '../widgets/settings_row.dart';

class CausesSection extends StatelessWidget {
  const CausesSection({
    required this.causeCount,
    required this.topCauses,
    required this.onManageCauses,
  });

  final int causeCount;
  final List<String> topCauses;
  final VoidCallback onManageCauses;

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      child: SettingsRow(
        icon: Icons.tune_rounded,
        title: "Manage causes",
        value: "$causeCount causes • ${topCauses.join(", ")}",
        onTap: onManageCauses,
      ),
    );
  }
}
