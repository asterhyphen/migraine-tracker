import 'package:flutter/material.dart';

import '../widgets/settings_card.dart';
import '../widgets/settings_row.dart';

class NfcSection extends StatelessWidget {
  const NfcSection({required this.onProgramNfc});

  final VoidCallback onProgramNfc;

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      child: Column(
        children: [
          SettingsRow(
            icon: Icons.nfc_rounded,
            title: "Program NFC tag",
            value:
                "Program tag once, use anytime.",
            onTap: onProgramNfc,
          ),
        ],
      ),
    );
  }
}
