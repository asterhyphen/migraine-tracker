import 'package:flutter/material.dart';

import '../widgets/settings_card.dart';

class AppAboutSection extends StatelessWidget {
  const AppAboutSection({
    required this.appVersion,
    required this.onDevWebsiteTap,
    required this.onGithubTap,
  });

  final String appVersion;
  final VoidCallback onDevWebsiteTap;
  final VoidCallback onGithubTap;

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App version'),
            subtitle: Text(appVersion),
            onTap: null,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.developer_mode_outlined),
            title: const Text('Dev website'),
            subtitle: const Text('https://asterhyphen.xyz'),
            onTap: onDevWebsiteTap,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('GitHub'),
            subtitle: const Text('https://github.com/AsterHyphen'),
            onTap: onGithubTap,
          ),
        ],
      ),
    );
  }
}
