import 'dart:async';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/cause_prefs.dart';
import '../data/migraine_db.dart';
import '../data/migraine_entry.dart';
import '../utils/date_utils.dart';
import '../widgets/app_snackbar.dart';
import 'privacy_policy_page.dart';
import 'terms_conditions_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.initialName,
    required this.initialDob,
    required this.initialProfileImagePath,
    required this.onSave,
    required this.onProfileImageChanged,
    required this.isDarkTheme,
    required this.onThemeChanged,
  });

  final String initialName;
  final DateTime initialDob;
  final String? initialProfileImagePath;
  final Future<void> Function(String name, DateTime dob) onSave;
  final Future<void> Function(String? imagePath) onProfileImageChanged;
  final bool isDarkTheme;
  final Future<void> Function(bool isDark) onThemeChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _nameController;
  late DateTime _dob;
  late bool _isDarkTheme;
  String? _profileImagePath;
  String _appVersion = '-';
  bool _busy = false;
  List<String> _causeOptions = List<String>.from(CausePrefs.defaultCauses);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _dob = widget.initialDob;
    _isDarkTheme = widget.isDarkTheme;
    _profileImagePath = widget.initialProfileImagePath;
    _loadAppVersion();
    _loadCauseOptions();
  }

  Future<void> _loadCauseOptions() async {
    final loaded = await CausePrefs.loadCauses();
    if (!mounted) return;
    setState(() {
      _causeOptions = loaded;
    });
  }

  Future<void> _saveCauseOptions() async {
    await CausePrefs.saveCauses(_causeOptions);
  }

  Future<void> _openCauseManager() async {
    final updated = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CauseManagerSheet(initialCauses: _causeOptions),
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

  Future<void> _launchDevUrl() async {
    final url = Uri.parse('https://asterhyphen.xyz');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          title: 'Link failed',
          message: 'Could not open $url',
        );
      }
    }
  }

  Future<void> _openNfcDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const _NfcActionDialog();
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

      await MigraineDb.instance.insertEntries(entries);
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
      final entries = await MigraineDb.instance.getMigraineEntriesOnly();
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(40),
                    onTap: _pickProfileImage,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: scheme.primary.withValues(
                            alpha: 0.2,
                          ),
                          backgroundImage:
                              _profileImagePath != null &&
                                  _profileImagePath!.isNotEmpty
                              ? FileImage(File(_profileImagePath!))
                              : null,
                          child:
                              _profileImagePath == null ||
                                  _profileImagePath!.isEmpty
                              ? Text(
                                  _nameController.text.isEmpty
                                      ? "?"
                                      : _nameController.text[0].toUpperCase(),
                                  style: TextStyle(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 24,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: scheme.surface,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.edit,
                              size: 13,
                              color: scheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameController.text.isEmpty
                              ? "Your Profile"
                              : _nameController.text,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "DOB ${_formatDate(_dob)}",
                          style: TextStyle(
                            fontSize: 14,
                            color: scheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: "Profile"),
          const SizedBox(height: 12),
          _SettingsCard(
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.person_outline,
                  title: "Name",
                  value: _nameController.text.isEmpty
                      ? "Not set"
                      : _nameController.text,
                  onTap: _editName,
                ),
                const Divider(height: 1),
                _SettingsRow(
                  icon: Icons.cake_outlined,
                  title: "Date of birth",
                  value: _formatDate(_dob),
                  onTap: _pickDob,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: "Appearance"),
          const SizedBox(height: 12),
          _SettingsCard(
            child: SwitchListTile(
              value: _isDarkTheme,
              onChanged: _toggleTheme,
              title: const Text("Dark theme"),
              subtitle: Text(_isDarkTheme ? "Enabled (default)" : "Light mode"),
              secondary: const Icon(Icons.dark_mode_outlined),
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: "Causes"),
          const SizedBox(height: 12),
          _SettingsCard(
            child: _SettingsRow(
              icon: Icons.tune_rounded,
              title: "Manage causes",
              value:
                  "${_causeOptions.length} causes • ${_causeOptions.take(3).join(", ")}",
              onTap: _openCauseManager,
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: "NFC"),
          const SizedBox(height: 12),
          _SettingsCard(
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.nfc_rounded,
                  title: "Program NFC tag",
                  value:
                      "One-time setup. Then tap tag from Home/Lock screen to open logging directly.",
                  onTap: _openNfcDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: "Data"),
          const SizedBox(height: 12),
          _SettingsCard(
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.upload_file_outlined,
                  title: "Import data",
                  value: "Restore from CSV backup",
                  enabled: !_busy,
                  onTap: _importData,
                ),
                const Divider(height: 1),
                _SettingsRow(
                  icon: Icons.download_outlined,
                  title: "Export data",
                  value: _busy ? "Working..." : "Save CSV to Downloads",
                  enabled: !_busy,
                  onTap: _exportData,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: "Legal"),
          const SizedBox(height: 12),
          _SettingsCard(
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.privacy_tip_outlined,
                  title: "Privacy Policy",
                  value: "",
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyPage(),
                    ),
                  ),
                ),
                const Divider(height: 1),
                _SettingsRow(
                  icon: Icons.description_outlined,
                  title: "Terms and Conditions",
                  value: "",
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TermsConditionsPage(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: "About"),
          const SizedBox(height: 12),
          _SettingsCard(
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.info_outline,
                  title: "App version",
                  value: _appVersion,
                  onTap: () {},
                ),
                const Divider(height: 1),
                _SettingsRow(
                  icon: Icons.developer_mode_outlined,
                  title: "Dev Info",
                  value: "AsterHyphen • asterhyphen.xyz",
                  onTap: _launchDevUrl,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.link_outlined),
                  title: const Text('Open developer site'),
                  subtitle: const Text('Tap to visit the AsterHyphen homepage'),
                  onTap: _launchDevUrl,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Visit the link to read full developer information and open source updates.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _CauseManagerSheet extends StatefulWidget {
  const _CauseManagerSheet({required this.initialCauses});

  final List<String> initialCauses;

  @override
  State<_CauseManagerSheet> createState() => _CauseManagerSheetState();
}

class _CauseManagerSheetState extends State<_CauseManagerSheet> {
  late List<String> _causes;
  final TextEditingController _newCauseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _causes = List<String>.from(widget.initialCauses);
  }

  @override
  void dispose() {
    _newCauseController.dispose();
    super.dispose();
  }

  void _addCause() {
    final value = _newCauseController.text.trim();
    if (value.isEmpty) return;
    final exists = _causes.any((c) => c.toLowerCase() == value.toLowerCase());
    if (exists) return;
    setState(() {
      _causes.add(value);
      _newCauseController.clear();
    });
  }

  void _deleteCause(int index) {
    if (_causes.length <= 1) return;
    setState(() {
      _causes.removeAt(index);
    });
  }

  void _moveCause(int index, int delta) {
    final next = index + delta;
    if (next < 0 || next >= _causes.length) return;
    setState(() {
      final item = _causes.removeAt(index);
      _causes.insert(next, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Manage Causes",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(_causes),
                  child: const Text("Done"),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newCauseController,
                    decoration: const InputDecoration(
                      labelText: "Add new cause",
                    ),
                    onSubmitted: (_) => _addCause(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: _addCause,
                  child: const Text("Add"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _causes.length,
                itemBuilder: (context, index) {
                  final cause = _causes[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: scheme.onSurface.withValues(alpha: 0.12),
                      ),
                      color: scheme.surface.withValues(alpha: 0.8),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Text(
                        "${index + 1}",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                      title: Text(
                        cause,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: SizedBox(
                        width: 120,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: index == 0
                                  ? null
                                  : () => _moveCause(index, -1),
                              icon: const Icon(Icons.keyboard_arrow_up),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: index == _causes.length - 1
                                  ? null
                                  : () => _moveCause(index, 1),
                              icon: const Icon(Icons.keyboard_arrow_down),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _deleteCause(index),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        letterSpacing: 1.1,
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: child,
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      enabled: enabled,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(
        value,
        style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.65)),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: scheme.onSurface.withValues(alpha: 0.45),
      ),
      onTap: enabled ? onTap : null,
    );
  }
}

enum _NfcStatus { detecting, notDetected, success, error, unavailable }

class _NfcActionDialog extends StatefulWidget {
  const _NfcActionDialog();

  @override
  State<_NfcActionDialog> createState() => _NfcActionDialogState();
}

class _NfcActionDialogState extends State<_NfcActionDialog>
    with SingleTickerProviderStateMixin {
  static const _nfcUri = 'migraine-tracker://log';
  late final AnimationController _pulseController;
  _NfcStatus _status = _NfcStatus.detecting;
  String _message = 'Detecting NFC chip...';
  Timer? _timeout;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _startNfc();
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _pulseController.dispose();
    NfcManager.instance.stopSession();
    super.dispose();
  }

  Future<void> _startNfc() async {
    final available = await NfcManager.instance.isAvailable();
    if (!mounted) return;
    if (!available) {
      setState(() {
        _status = _NfcStatus.unavailable;
        _message = 'NFC not available on this device.';
      });
      return;
    }

    _completed = false;
    setState(() {
      _status = _NfcStatus.detecting;
      _message =
          'Hold an NFC tag near your phone to program it with the app shortcut.';
    });

    _timeout?.cancel();
    _timeout = Timer(const Duration(seconds: 8), () async {
      if (_completed || !mounted) return;
      await NfcManager.instance.stopSession();
      if (!mounted) return;
      setState(() {
        _status = _NfcStatus.notDetected;
        _message = 'Not detected';
      });
    });

    NfcManager.instance.startSession(
      onDiscovered: (tag) async {
        if (_completed) return;
        _completed = true;
        _timeout?.cancel();
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null || !ndef.isWritable) {
            throw Exception('Tag not writable');
          }
          final msg = NdefMessage([NdefRecord.createUri(Uri.parse(_nfcUri))]);
          await ndef.write(msg);
          await NfcManager.instance.stopSession();
          if (!mounted) return;
          setState(() {
            _status = _NfcStatus.success;
            _message =
                'NFC tag programmed. You can now tap it from Home/Lock screen to open logging.';
          });
        } catch (e) {
          await NfcManager.instance.stopSession(errorMessage: e.toString());
          if (!mounted) return;
          setState(() {
            _status = _NfcStatus.error;
            _message = 'Error: $e';
          });
        }
      },
    );
  }

  Future<void> _scanAgain() async {
    await _startNfc();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isError =
        _status == _NfcStatus.notDetected || _status == _NfcStatus.error;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Program NFC Tag',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _NfcPulse(
              controller: _pulseController,
              color: isError ? Colors.redAccent : scheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isError ? Colors.redAccent : scheme.onSurface,
                fontWeight: isError ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            if (_status == _NfcStatus.notDetected ||
                _status == _NfcStatus.error)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _scanAgain,
                      child: const Text('Scan again'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            if (_status == _NfcStatus.success ||
                _status == _NfcStatus.unavailable)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NfcPulse extends StatelessWidget {
  const _NfcPulse({required this.controller, required this.color});

  final AnimationController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final t = controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              _ring(0.75 + t * 0.9, (1 - t) * 0.32),
              _ring(0.45 + t * 0.7, (1 - t) * 0.22),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.2),
                ),
                child: Icon(Icons.nfc, color: color),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _ring(double scale, double alpha) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: alpha.clamp(0.0, 1.0)),
            width: 2,
          ),
        ),
      ),
    );
  }
}
