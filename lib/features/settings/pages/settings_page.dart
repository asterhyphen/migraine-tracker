import 'dart:async';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:migraine_tracker/core/services/reminder_service.dart';
import 'package:migraine_tracker/core/utils/date_utils.dart';
import 'package:migraine_tracker/core/widgets/app_snackbar.dart';
import 'package:migraine_tracker/features/settings/models/app_settings.dart';
import 'package:migraine_tracker/features/tracker/models/cause_option.dart';
import 'package:migraine_tracker/features/tracker/models/migraine_entry.dart';
import 'package:migraine_tracker/features/tracker/providers/causes_provider.dart';
import 'package:migraine_tracker/features/tracker/providers/entries_provider.dart';
import 'privacy_page.dart';
import 'terms_page.dart';
import 'widgets/section_header.dart';
import 'sections/profile_section.dart';
import 'sections/appearance_section.dart';
import 'sections/causes_section.dart';
import 'sections/reminders_section.dart';
import 'sections/nfc_section.dart';
import 'sections/data_section.dart';
import 'sections/about_section.dart';
import 'sections/app_about_section.dart';
import 'dialogs/cause_manager_sheet.dart';
import 'dialogs/medication_reminder_dialog.dart';
import 'dialogs/nfc_action_dialog.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({
    super.key,
    required this.initialName,
    required this.initialDob,
    required this.initialProfileImagePath,
    required this.onSave,
    required this.onProfileImageChanged,
    required this.isDarkTheme,
    required this.onThemeChanged,
    required this.dailyReminderEnabled,
    required this.staleReminderEnabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.staleReminderDays,
    required this.forceDailyReminder,
    required this.dailyReminderMessage,
    required this.staleReminderMessage,
    required this.medicationReminders,
    required this.onReminderSettingsChanged,
  });

  final String initialName;
  final DateTime initialDob;
  final String? initialProfileImagePath;
  final Future<void> Function(String name, DateTime dob) onSave;
  final Future<void> Function(String? imagePath) onProfileImageChanged;
  final bool isDarkTheme;
  final Future<void> Function(bool isDark) onThemeChanged;
  final bool dailyReminderEnabled;
  final bool staleReminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final int staleReminderDays;
  final bool forceDailyReminder;
  final String dailyReminderMessage;
  final String staleReminderMessage;
  final List<MedicationReminder> medicationReminders;
  final Future<void> Function({
    required bool dailyEnabled,
    required bool staleEnabled,
    required int hour,
    required int minute,
    required int staleDays,
    required bool forceDailyReminder,
    required String dailyMessage,
    required String staleMessage,
    required List<MedicationReminder> medicationReminders,
  })
  onReminderSettingsChanged;

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final TextEditingController _nameController;
  late DateTime _dob;
  late bool _isDarkTheme;
  late bool _dailyReminderEnabled;
  late bool _staleReminderEnabled;
  late int _reminderHour;
  late int _reminderMinute;
  late int _staleReminderDays;
  late bool _forceDailyReminder;
  late String _dailyReminderMessage;
  late String _staleReminderMessage;
  late List<MedicationReminder> _medicationReminders;
  String? _profileImagePath;
  String _appVersion = '-';
  bool _busy = false;
  List<String> _causeOptions = List<String>.from(defaultCauseOptions);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _dob = widget.initialDob;
    _isDarkTheme = widget.isDarkTheme;
    _dailyReminderEnabled = widget.dailyReminderEnabled;
    _staleReminderEnabled = widget.staleReminderEnabled;
    _reminderHour = widget.reminderHour;
    _reminderMinute = widget.reminderMinute;
    _staleReminderDays = widget.staleReminderDays;
    _forceDailyReminder = widget.forceDailyReminder;
    _dailyReminderMessage = widget.dailyReminderMessage;
    _staleReminderMessage = widget.staleReminderMessage;
    _medicationReminders = List<MedicationReminder>.from(
      widget.medicationReminders,
    );
    _profileImagePath = widget.initialProfileImagePath;
    _loadAppVersion();
    _loadCauseOptions();
  }

  Future<void> _loadCauseOptions() async {
    final loaded =
        ref.read(causeOptionsProvider).value ??
        await ref.read(causeOptionsProvider.notifier).reload();
    if (!mounted) return;
    setState(() {
      _causeOptions = loaded;
    });
  }

  Future<void> _saveCauseOptions() async {
    await ref.read(causeOptionsProvider.notifier).save(_causeOptions);
  }

  Future<void> _openCauseManager() async {
    final updated = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CauseManagerSheet(initialCauses: _causeOptions),
    );
    if (updated == null) return;
    setState(() {
      _causeOptions = updated;
    });
    await _saveCauseOptions();
    if (!mounted) return;
    AppSnackBar.showSuccess(
      context,
      title: 'Triggers updated',
      message: 'Your cause options are ready to use in future logs.',
    );
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = '${info.version}+${info.buildNumber}';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return formatDdMmYyyy(date);
  }

  String _formatReminderTime(BuildContext context) {
    return MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay(hour: _reminderHour, minute: _reminderMinute));
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      _dob = picked;
    });
    await _saveProfileInline();
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _nameController.text);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit name"),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: "Name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
    if (result == null || result.isEmpty) return;
    setState(() {
      _nameController.text = result;
    });
    await _saveProfileInline();
  }

  Future<void> _saveProfileInline() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      if (!mounted) return;
      AppSnackBar.showInfo(
        context,
        title: 'Name required',
        message: 'Please add a name before saving your profile.',
      );
      return;
    }
    await widget.onSave(name, _dob);
    if (!mounted) return;
    AppSnackBar.showSuccess(
      context,
      title: 'Profile updated',
      message: 'Your personal details were saved.',
    );
  }

  Future<void> _toggleTheme(bool value) async {
    setState(() {
      _isDarkTheme = value;
    });
    await widget.onThemeChanged(value);
  }

  Future<void> _saveReminderSettings() async {
    await widget.onReminderSettingsChanged(
      dailyEnabled: _dailyReminderEnabled,
      staleEnabled: _staleReminderEnabled,
      hour: _reminderHour,
      minute: _reminderMinute,
      staleDays: _staleReminderDays,
      forceDailyReminder: _forceDailyReminder,
      dailyMessage: _dailyReminderMessage,
      staleMessage: _staleReminderMessage,
      medicationReminders: _medicationReminders,
    );
  }

  Future<bool> _ensureNotificationPermission() async {
    final granted = await ReminderService.instance.requestPermission();
    if (granted) return true;
    if (!mounted) return false;
    AppSnackBar.showInfo(
      context,
      title: 'Notifications disabled',
      message: 'Allow notifications in system settings to use reminders.',
    );
    return false;
  }

  Future<void> _toggleDailyReminder(bool value) async {
    if (value && !await _ensureNotificationPermission()) return;
    setState(() {
      _dailyReminderEnabled = value;
    });
    await _saveReminderSettings();
  }

  Future<void> _toggleStaleReminder(bool value) async {
    if (value && !await _ensureNotificationPermission()) return;
    setState(() {
      _staleReminderEnabled = value;
    });
    await _saveReminderSettings();
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
    );
    if (picked == null) return;
    setState(() {
      _reminderHour = picked.hour;
      _reminderMinute = picked.minute;
    });
    await _saveReminderSettings();
  }

  Future<void> _pickStaleReminderDays() async {
    var selected = _staleReminderDays;
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gentle reminder delay',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 2, label: Text('2 days')),
                        ButtonSegment(value: 3, label: Text('3 days')),
                        ButtonSegment(value: 5, label: Text('5 days')),
                        ButtonSegment(value: 7, label: Text('7 days')),
                      ],
                      selected: {selected},
                      onSelectionChanged: (values) {
                        setSheetState(() {
                          selected = values.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(selected),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (picked == null) return;
    setState(() {
      _staleReminderDays = picked;
    });
    await _saveReminderSettings();
  }

  Future<void> _editReminderMessage({
    required String title,
    required String currentMessage,
    required ValueChanged<String> onSaved,
  }) async {
    final controller = TextEditingController(text: currentMessage);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Notification text',
              hintText: 'Type a friendly reminder message',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) return;
    onSaved(result);
    await _saveReminderSettings();
  }

  Future<void> _addMedicationReminder() async {
    if (!await _ensureNotificationPermission()) return;
    if (!mounted) return;
    final reminder = await showDialog<MedicationReminder>(
      context: context,
      builder: (context) => const MedicationReminderDialog(),
    );
    if (reminder == null) return;
    setState(() {
      _medicationReminders = [..._medicationReminders, reminder];
    });
    await _saveReminderSettings();
  }

  Future<void> _editMedicationReminder(MedicationReminder reminder) async {
    final updated = await showDialog<MedicationReminder>(
      context: context,
      builder: (context) => MedicationReminderDialog(reminder: reminder),
    );
    if (updated == null) return;
    setState(() {
      _medicationReminders = _medicationReminders
          .map((item) => item.id == updated.id ? updated : item)
          .toList();
    });
    await _saveReminderSettings();
  }

  Future<void> _toggleMedicationReminder(
    MedicationReminder reminder,
    bool enabled,
  ) async {
    if (enabled && !await _ensureNotificationPermission()) return;
    setState(() {
      _medicationReminders = _medicationReminders
          .map(
            (item) =>
                item.id == reminder.id ? item.copyWith(enabled: enabled) : item,
          )
          .toList();
    });
    await _saveReminderSettings();
  }

  Future<void> _deleteMedicationReminder(MedicationReminder reminder) async {
    setState(() {
      _medicationReminders = _medicationReminders
          .where((item) => item.id != reminder.id)
          .toList();
    });
    await _saveReminderSettings();
  }

  String _formatMedicationReminderTime(
    BuildContext context,
    MedicationReminder reminder,
  ) {
    return MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay(hour: reminder.hour, minute: reminder.minute));
  }

  Future<void> _pickProfileImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.single.path == null) return;
    final selectedPath = result.files.single.path!;
    setState(() {
      _profileImagePath = selectedPath;
    });
    await widget.onProfileImageChanged(selectedPath);
    if (!mounted) return;
    AppSnackBar.showSuccess(
      context,
      title: 'Photo updated',
      message: 'Your profile picture has been changed.',
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);

    if (!await canLaunchUrl(url)) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          title: 'Link failed',
          message: 'No browser found to open $urlString',
        );
      }
      return;
    }

    final success = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!success && mounted) {
      AppSnackBar.showError(
        context,
        title: 'Link failed',
        message: 'Could not open $urlString in browser',
      );
    }
  }

  Future<void> _openNfcDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const NfcActionDialog();
      },
    );
  }

  Future<void> _importData() async {
    if (_busy) return;
    setState(() {
      _busy = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result == null || result.files.single.path == null) {
        return;
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final rows = const CsvToListConverter(eol: '\n').convert(content);
      if (rows.isEmpty) return;

      final startIndex = _looksLikeHeader(rows.first) ? 1 : 0;
      final entries = <MigraineEntry>[];
      for (int i = startIndex; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 6) continue;
        final entry = _entryFromRow(row);
        if (entry != null) entries.add(entry);
      }

      await ref.read(migraineEntriesProvider.notifier).insertEntries(entries);
      if (!mounted) return;
      AppSnackBar.showSuccess(
        context,
        title: 'Import complete',
        message: 'Imported ${entries.length} entries.',
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        title: 'Import failed',
        message: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _exportData() async {
    if (_busy) return;
    setState(() {
      _busy = true;
    });

    try {
      var entries = ref.read(migraineEntriesProvider).value;
      if (entries == null) {
        await ref.read(migraineEntriesProvider.notifier).reload();
        entries =
            ref.read(migraineEntriesProvider).value ?? const <MigraineEntry>[];
      }
      final rows = <List<dynamic>>[
        ['date', 'had_migraine', 'intensity', 'painkillers', 'notes', 'causes'],
      ];

      for (final entry in entries) {
        rows.add([
          formatDdMmYyyy(entry.date),
          entry.hadMigraine ? 1 : 0,
          entry.intensity,
          entry.painkillers ? 1 : 0,
          entry.notes,
          entry.causes.join('|'),
        ]);
      }

      final csv = const ListToCsvConverter().convert(rows);
      final dir = await _resolveDownloadDir();
      if (dir == null) {
        if (!mounted) return;
        AppSnackBar.showInfo(
          context,
          title: 'Folder unavailable',
          message: 'The download folder could not be found on this device.',
        );
        return;
      }

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '')
          .replaceAll('-', '')
          .replaceAll('.', '');
      final path = "${dir.path}/migraine_export_$timestamp.csv";
      await dir.create(recursive: true);
      final file = File(path);
      await file.writeAsString(csv);
      if (!mounted) return;
      AppSnackBar.showSuccess(
        context,
        title: 'Export complete',
        message: 'Saved your backup to $path',
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        title: 'Export failed',
        message: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  bool _looksLikeHeader(List<dynamic> row) {
    if (row.isEmpty) return false;
    final first = row.first.toString().toLowerCase();
    return first.contains('date');
  }

  MigraineEntry? _entryFromRow(List<dynamic> row) {
    try {
      final parsedDate = parseFlexibleDate(row[0].toString());
      if (parsedDate == null) return null;
      final hadMigraine = row[1].toString() == '1';
      final intensity = int.tryParse(row[2].toString()) ?? 0;
      final painkillers = row[3].toString() == '1';
      final notes = row[4].toString();
      final causes = row[5]
          .toString()
          .split('|')
          .where((c) => c.isNotEmpty)
          .toList();
      return MigraineEntry(
        date: parsedDate,
        hadMigraine: hadMigraine,
        intensity: intensity,
        painkillers: painkillers,
        notes: notes,
        causes: causes,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Directory?> _resolveDownloadDir() async {
    if (Platform.isAndroid) {
      // Prefer the public Download folder path explicitly.
      final preferred = Directory('/storage/emulated/0/Download');
      try {
        await preferred.create(recursive: true);
        if (await preferred.exists()) return preferred;
      } catch (_) {}

      final status = await Permission.storage.request();
      if (status.isGranted) {
        final candidates = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        if (candidates != null && candidates.isNotEmpty) {
          return candidates.first;
        }
      }

      final fallback = await getExternalStorageDirectory();
      return fallback;
    }

    if (Platform.isIOS) {
      return getApplicationDocumentsDirectory();
    }

    return getDownloadsDirectory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          ProfileSection(
            name: _nameController.text,
            dob: _dob,
            profileImagePath: _profileImagePath,
            formatDate: _formatDate,
            onNameEdit: _editName,
            onDobPick: _pickDob,
            onImagePick: _pickProfileImage,
          ),
          const SizedBox(height: 20),

          // Appearance Section
          SectionHeader(title: "Appearance"),
          const SizedBox(height: 12),
          AppearanceSection(
            isDarkTheme: _isDarkTheme,
            onThemeChanged: _toggleTheme,
          ),
          const SizedBox(height: 20),

          // Causes Section
          SectionHeader(title: "Causes"),
          const SizedBox(height: 12),
          CausesSection(
            causeCount: _causeOptions.length,
            topCauses: _causeOptions.take(3).toList(),
            onManageCauses: _openCauseManager,
          ),
          const SizedBox(height: 20),

          // Reminders Section
          SectionHeader(title: "Reminders"),
          const SizedBox(height: 12),
          RemindersSection(
            dailyReminderEnabled: _dailyReminderEnabled,
            staleReminderEnabled: _staleReminderEnabled,
            reminderHour: _reminderHour,
            reminderMinute: _reminderMinute,
            staleReminderDays: _staleReminderDays,
            forceDailyReminder: _forceDailyReminder,
            dailyReminderMessage: _dailyReminderMessage,
            staleReminderMessage: _staleReminderMessage,
            medicationReminders: _medicationReminders,
            formatReminderTime: _formatReminderTime,
            onToggleDailyReminder: _toggleDailyReminder,
            onToggleStaleReminder: _toggleStaleReminder,
            onEditDailyMessage: () => _editReminderMessage(
              title: 'Edit daily reminder text',
              currentMessage: _dailyReminderMessage,
              onSaved: (text) {
                setState(() {
                  _dailyReminderMessage = text;
                });
              },
            ),
            onEditStaleMessage: () => _editReminderMessage(
              title: 'Edit check-in reminder text',
              currentMessage: _staleReminderMessage,
              onSaved: (text) {
                setState(() {
                  _staleReminderMessage = text;
                });
              },
            ),
            onToggleForceDailyReminder: (value) {
              setState(() {
                _forceDailyReminder = value;
              });
              _saveReminderSettings();
            },
            onPickReminderTime: _pickReminderTime,
            onPickStaleReminderDays: _pickStaleReminderDays,
            onAddMedicationReminder: _addMedicationReminder,
            onEditMedicationReminder: _editMedicationReminder,
            onToggleMedicationReminder: _toggleMedicationReminder,
            onDeleteMedicationReminder: _deleteMedicationReminder,
            formatMedicationReminderTime: _formatMedicationReminderTime,
          ),
          const SizedBox(height: 20),

          // NFC Section
          SectionHeader(title: "NFC"),
          const SizedBox(height: 12),
          NfcSection(onProgramNfc: _openNfcDialog),
          const SizedBox(height: 20),

          // Data Section
          SectionHeader(title: "Data"),
          const SizedBox(height: 12),
          DataSection(
            isBusy: _busy,
            onImportData: _importData,
            onExportData: _exportData,
          ),
          const SizedBox(height: 20),

          // Legal Section
          SectionHeader(title: "Legal"),
          const SizedBox(height: 12),
          LegalSection(
            onPrivacyPolicyTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
            ),
            onTermsConditionsTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TermsConditionsPage()),
            ),
          ),
          const SizedBox(height: 20),

          // About Section
          SectionHeader(title: "About"),
          const SizedBox(height: 12),
          AppAboutSection(
            appVersion: _appVersion,
            onDevWebsiteTap: () => _launchUrl('https://asterhyphen.xyz'),
            onGithubTap: () => _launchUrl('https://github.com/AsterHyphen'),
          ),
        ],
      ),
    );
  }
}
