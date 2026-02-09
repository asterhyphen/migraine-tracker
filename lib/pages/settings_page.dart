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
          'medication',
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
          entry.medication,
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
      final medication = row[4].toString();
      final notes = row[5].toString();
      final causes =
          row[6].toString().split('|').where((c) => c.isNotEmpty).toList();
      return MigraineEntry(
        date: date,
        hadMigraine: hadMigraine,
        intensity: intensity,
        painkillers: painkillers,
        medication: medication,
        notes: notes,
        causes: causes,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Directory?> _resolveDownloadDir() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) return null;

      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) return downloadDir;
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Profile",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Date of birth: ${_formatDate(_dob)}",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                TextButton(onPressed: _pickDob, child: const Text("Edit")),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "Data",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _importData,
                    child: const Text("Import"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _exportData,
                    child: Text(_busy ? "Working..." : "Export"),
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? "Saving..." : "Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
