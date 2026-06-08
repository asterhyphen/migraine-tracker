import 'package:flutter/material.dart';

import '../widgets/settings_card.dart';
import '../widgets/settings_row.dart';

class LegalSection extends StatelessWidget {
  const LegalSection({
    required this.onPrivacyPolicyTap,
    required this.onTermsConditionsTap,
  });

  final VoidCallback onPrivacyPolicyTap;
  final VoidCallback onTermsConditionsTap;

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      child: Column(
        children: [
          SettingsRow(
            icon: Icons.privacy_tip_outlined,
            title: "Privacy Policy",
            value: "Read the privacy policy",
            onTap: onPrivacyPolicyTap,
          ),
          const Divider(height: 1),
          SettingsRow(
            icon: Icons.description_outlined,
            title: "Terms and Conditions",
            value: "Read the terms and conditions",
            onTap: onTermsConditionsTap,
          ),
        ],
      ),
    );
  }
}
