import 'package:flutter/material.dart';

import 'package:migraine_tracker/features/settings/models/app_settings.dart';
import '../widgets/settings_row.dart';

class MedicationReminderDialog extends StatefulWidget {
  const MedicationReminderDialog({this.reminder});

  final MedicationReminder? reminder;

  @override
  State<MedicationReminderDialog> createState() =>
      _MedicationReminderDialogState();
}

class _MedicationReminderDialogState extends State<MedicationReminderDialog> {
  late final TextEditingController _nameController;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    _nameController = TextEditingController(text: reminder?.name ?? '');
    _time = TimeOfDay(hour: reminder?.hour ?? 9, minute: reminder?.minute ?? 0);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked == null) return;
    setState(() {
      _time = picked;
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final current = widget.reminder;
    Navigator.of(context).pop(
      MedicationReminder(
        id: current?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        hour: _time.hour,
        minute: _time.minute,
        enabled: current?.enabled ?? true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeLabel = MaterialLocalizations.of(context).formatTimeOfDay(_time);
    return AlertDialog(
      title: Text(
        widget.reminder == null
            ? "Add medication reminder"
            : "Edit medication reminder",
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: "Medication name",
              hintText: "For example, Sumatriptan",
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          SettingsRow(
            icon: Icons.schedule_outlined,
            title: "Reminder time",
            value: timeLabel,
            onTap: _pickTime,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        TextButton(onPressed: _save, child: const Text("Save")),
      ],
    );
  }
}
