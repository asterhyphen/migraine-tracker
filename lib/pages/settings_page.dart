import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/migraine_db.dart';
import '../data/migraine_entry.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.initialName,
    required this.initialDob,
    required this.onSave,
  });

  final String initialName;
  final DateTime initialDob;
  final Future<void> Function(String name, DateTime dob) onSave;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _nameController;
  late DateTime _dob;
  bool _saving = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _dob = widget.initialDob;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return "$dd-$mm-${date.year}";
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
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
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
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Name cannot be empty.")));
      return;
    }
    setState(() {
      _saving = true;
    });
    await widget.onSave(name, _dob);
    if (!mounted) return;
    setState(() {
      _saving = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Profile updated.")));
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
        if (row.length < 7) continue;
        final entry = _entryFromRow(row);
        if (entry != null) entries.add(entry);
      }

      await MigraineDb.instance.insertEntries(entries);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Imported ${entries.length} entries.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Import failed: $e")),
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
        [
          'date',
          'had_migraine',
          'intensity',
          'painkillers',
          'notes',
          'causes'
        ],
      ];

      for (final entry in entries) {
        rows.add([
          entry.date.toIso8601String(),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Download folder unavailable.")),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Exported to $path")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Export failed: $e")),
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
      final date = DateTime.parse(row[0].toString());
      final hadMigraine = row[1].toString() == '1';
      final intensity = int.tryParse(row[2].toString()) ?? 0;
      final painkillers = row[3].toString() == '1';
      final notes = row[5].toString();
      final causes =
          row[6].toString().split('|').where((c) => c.isNotEmpty).toList();
      return MigraineEntry(
        date: date,
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
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.primary.withValues(alpha: 0.2),
                child: Text(
                  _nameController.text.isEmpty
                      ? "?"
                      : _nameController.text[0].toUpperCase(),
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: Text(
                _nameController.text.isEmpty ? "Your Profile" : _nameController.text,
              ),
              subtitle: Text("DOB ${_formatDate(_dob)}"),
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
          const SizedBox(height: 24),
          _SectionHeader(title: "Save Changes"),
          const SizedBox(height: 12),
          _SettingsCard(
            child: ListTile(
              leading: Icon(Icons.save_outlined, color: scheme.primary),
              title: const Text("Save profile"),
              subtitle: const Text("Apply name and date of birth updates"),
              trailing: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? "Saving..." : "Save"),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Exports are stored in your Downloads folder.",
            style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
        ],
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
