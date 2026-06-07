import 'package:flutter/material.dart';

import 'package:migraine_tracker/features/settings/models/app_settings.dart';

class MedicationReminderTile extends StatelessWidget {
  const MedicationReminderTile({
    required this.reminder,
    required this.timeLabel,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final MedicationReminder reminder;
  final String timeLabel;
  final ValueChanged<bool> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Switch(value: reminder.enabled, onChanged: onChanged),
      title: Text(reminder.name),
      subtitle: Text(
        "${reminder.enabled ? 'Daily' : 'Off'} at $timeLabel",
        style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.65)),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: "Edit medication reminder",
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: "Delete medication reminder",
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}
