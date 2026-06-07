import 'package:flutter/material.dart';

import '../widgets/settings_card.dart';
import '../widgets/settings_row.dart';

class DataSection extends StatelessWidget {
  const DataSection({
    required this.isBusy,
    required this.onImportData,
    required this.onExportData,
  });

  final bool isBusy;
  final VoidCallback onImportData;
  final VoidCallback onExportData;

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      child: Column(
        children: [
          SettingsRow(
            icon: Icons.upload_file_outlined,
            title: "Import data",
            value: "Restore from CSV backup",
            enabled: !isBusy,
            onTap: onImportData,
          ),
          const Divider(height: 1),
          SettingsRow(
            icon: Icons.download_outlined,
            title: "Export data",
            value: isBusy ? "Working..." : "Save CSV to Downloads",
            enabled: !isBusy,
            onTap: onExportData,
          ),
        ],
      ),
    );
  }
}
