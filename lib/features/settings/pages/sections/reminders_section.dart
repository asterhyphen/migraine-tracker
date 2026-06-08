import 'package:flutter/material.dart';

import 'package:migraine_tracker/features/settings/models/app_settings.dart';
import '../widgets/settings_card.dart';
import '../widgets/settings_row.dart';
import '../widgets/medication_reminder_tile.dart';

class RemindersSection extends StatelessWidget {
  const RemindersSection({
    required this.dailyReminderEnabled,
    required this.staleReminderEnabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.staleReminderDays,
    required this.forceDailyReminder,
    required this.dailyReminderMessage,
    required this.staleReminderMessage,
    required this.medicationReminders,
    required this.formatReminderTime,
    required this.onToggleDailyReminder,
    required this.onToggleStaleReminder,
    required this.onEditDailyMessage,
    required this.onEditStaleMessage,
    required this.onToggleForceDailyReminder,
    required this.onPickReminderTime,
    required this.onPickStaleReminderDays,
    required this.onAddMedicationReminder,
    required this.onEditMedicationReminder,
    required this.onToggleMedicationReminder,
    required this.onDeleteMedicationReminder,
    required this.formatMedicationReminderTime,
  });

  final bool dailyReminderEnabled;
  final bool staleReminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final int staleReminderDays;
  final bool forceDailyReminder;
  final String dailyReminderMessage;
  final String staleReminderMessage;
  final List<MedicationReminder> medicationReminders;
  final String Function(BuildContext) formatReminderTime;
  final ValueChanged<bool> onToggleDailyReminder;
  final ValueChanged<bool> onToggleStaleReminder;
  final VoidCallback onEditDailyMessage;
  final VoidCallback onEditStaleMessage;
  final ValueChanged<bool> onToggleForceDailyReminder;
  final VoidCallback onPickReminderTime;
  final VoidCallback onPickStaleReminderDays;
  final VoidCallback onAddMedicationReminder;
  final Function(MedicationReminder) onEditMedicationReminder;
  final Function(MedicationReminder, bool) onToggleMedicationReminder;
  final Function(MedicationReminder) onDeleteMedicationReminder;
  final String Function(BuildContext, MedicationReminder)
  formatMedicationReminderTime;

  String _shortReminderPreview(String value) {
    const max = 52;
    if (value.length <= max) {
      return value;
    }
    return '${value.substring(0, max).trim()}...';
  }

  @override
  Widget build(BuildContext context) {
    final reminderRows = <Widget>[];

    void addReminderRow(Widget row) {
      if (reminderRows.isNotEmpty) {
        reminderRows.add(const Divider(height: 1));
      }
      reminderRows.add(row);
    }

    addReminderRow(
      SwitchListTile(
        value: dailyReminderEnabled,
        onChanged: onToggleDailyReminder,
        title: const Text("Daily log reminder"),
        subtitle: Text(
          dailyReminderEnabled ? "At ${formatReminderTime(context)}" : "Off",
        ),
        secondary: const Icon(Icons.notifications_active_outlined),
      ),
    );

    if (dailyReminderEnabled) {
      addReminderRow(
        SettingsRow(
          icon: Icons.text_snippet_outlined,
          title: "Daily reminder text",
          value: _shortReminderPreview(dailyReminderMessage),
          onTap: onEditDailyMessage,
        ),
      );
      addReminderRow(
        SwitchListTile(
          value: forceDailyReminder,
          onChanged: onToggleForceDailyReminder,
          title: const Text("Force daily reminder"),
          subtitle: const Text(
            "Send the daily reminder even if log has been recorded for the day",
          ),
          secondary: const Icon(Icons.push_pin_outlined),
        ),
      );
    }

    addReminderRow(
      SwitchListTile(
        value: staleReminderEnabled,
        onChanged: onToggleStaleReminder,
        title: const Text("Gentle check-in"),
        subtitle: Text(
          staleReminderEnabled
              ? "If there is no log for $staleReminderDays days"
              : "Off",
        ),
        secondary: const Icon(Icons.notification_important_outlined),
      ),
    );

    if (staleReminderEnabled) {
      addReminderRow(
        SettingsRow(
          icon: Icons.text_snippet_outlined,
          title: "Check-in reminder text",
          value: _shortReminderPreview(staleReminderMessage),
          onTap: onEditStaleMessage,
        ),
      );
      addReminderRow(
        SettingsRow(
          icon: Icons.event_repeat_outlined,
          title: "Check-in delay",
          value: "$staleReminderDays days after the last log",
          onTap: onPickStaleReminderDays,
        ),
      );
    }

    if (dailyReminderEnabled || staleReminderEnabled) {
      addReminderRow(
        SettingsRow(
          icon: Icons.schedule_outlined,
          title: "Reminder time",
          value: formatReminderTime(context),
          onTap: onPickReminderTime,
        ),
      );
    }

    addReminderRow(
      SettingsRow(
        icon: Icons.medication_outlined,
        title: "Medication reminders",
        value: medicationReminders.isEmpty
            ? "Add medication times"
            : "${medicationReminders.length} saved",
        onTap: onAddMedicationReminder,
      ),
    );

    for (final reminder in medicationReminders) {
      addReminderRow(
        MedicationReminderTile(
          reminder: reminder,
          timeLabel: formatMedicationReminderTime(context, reminder),
          onChanged: (value) => onToggleMedicationReminder(reminder, value),
          onEdit: () => onEditMedicationReminder(reminder),
          onDelete: () => onDeleteMedicationReminder(reminder),
        ),
      );
    }

    return SettingsCard(child: Column(children: reminderRows));
  }
}
