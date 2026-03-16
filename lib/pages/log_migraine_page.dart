import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/cause_prefs.dart';
import '../data/migraine_db.dart';
import '../data/migraine_entry.dart';
import '../utils/date_utils.dart';
import '../widgets/app_snackbar.dart';

class LogMigrainePage extends StatefulWidget {
  const LogMigrainePage({
    super.key,
    this.entry,
    this.initialDate,
  });

  final MigraineEntry? entry;
  final DateTime? initialDate;

  @override
  State<LogMigrainePage> createState() => _LogMigrainePageState();
}

class _LogMigrainePageState extends State<LogMigrainePage> {
  bool hadMigraine = true;
  double intensity = 5;
  int _lastHapticIntensity = 5;
  bool tookPainkillers = false;
  final TextEditingController notesController = TextEditingController();
  DateTime? _entryDate;
  bool _skipBackConfirm = false;
  late bool _initialHadMigraine;
  late double _initialIntensity;
  late bool _initialTookPainkillers;
  late String _initialNotes;
  late Set<String> _initialCauses;
  late DateTime _initialEntryDate;

  List<String> _causes = List<String>.from(CausePrefs.defaultCauses);

  final Set<String> selectedCauses = {};

  @override
  void initState() {
    super.initState();
    _loadCauseOptions();
    final entry = widget.entry;
    _entryDate = widget.initialDate ?? DateTime.now();
    if (entry != null) {
      hadMigraine = entry.hadMigraine;
      intensity = entry.intensity.toDouble();
      tookPainkillers = entry.painkillers;
      notesController.text = entry.notes;
      selectedCauses.addAll(entry.causes);
      _entryDate = entry.date;
    }
    _lastHapticIntensity = intensity.toInt();
    _initialHadMigraine = hadMigraine;
    _initialIntensity = intensity;
    _initialTookPainkillers = tookPainkillers;
    _initialNotes = notesController.text;
    _initialCauses = Set<String>.from(selectedCauses);
    _initialEntryDate = DateTime(
      (_entryDate ?? DateTime.now()).year,
      (_entryDate ?? DateTime.now()).month,
      (_entryDate ?? DateTime.now()).day,
    );
  }

  Future<void> _loadCauseOptions() async {
    final loaded = await CausePrefs.loadCauses();
    if (!mounted) return;
    setState(() {
      _causes = loaded;
    });
  }

  Future<void> _pickEntryDate() async {
    if (widget.entry != null) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _entryDate ?? now,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      _entryDate = picked;
    });
  }

  String _formatDate(DateTime date) {
    return formatDdMmYyyy(date);
  }

  bool _hasUnsavedChanges() {
    final currentEntryDate = DateTime(
      (_entryDate ?? DateTime.now()).year,
      (_entryDate ?? DateTime.now()).month,
      (_entryDate ?? DateTime.now()).day,
    );
    if (hadMigraine != _initialHadMigraine) return true;
    if (intensity.toInt() != _initialIntensity.toInt()) return true;
    if (tookPainkillers != _initialTookPainkillers) return true;
    if (notesController.text.trim() != _initialNotes.trim()) return true;
    if (!selectedCauses.containsAll(_initialCauses) ||
        !_initialCauses.containsAll(selectedCauses)) {
      return true;
    }
    if (widget.entry == null && currentEntryDate != _initialEntryDate) return true;
    return false;
  }

  Future<bool> _confirmDiscardChanges() async {
    if (_skipBackConfirm) return true;
    if (!_hasUnsavedChanges()) return true;
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Are you sure?"),
          content: const Text("Your edits will not be saved."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Stay"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Leave"),
            ),
          ],
        );
      },
    );
    return shouldLeave ?? false;
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  void _toggleCause(String cause) {
    setState(() {
      if (selectedCauses.contains(cause)) {
        selectedCauses.remove(cause);
      } else {
        selectedCauses.add(cause);
      }
    });
  }

  Future<void> _saveEntry() async {
    if (!hadMigraine) {
      AppSnackBar.showInfo(
        context,
        title: 'Nothing to save',
        message: 'Log a migraine first, then save your entry.',
      );
      return;
    }

    final targetDate = _entryDate ?? DateTime.now();
    final existingForDate = widget.entry == null
        ? await MigraineDb.instance.getEntryForDate(targetDate)
        : null;
    final entry = MigraineEntry(
      id: widget.entry?.id ?? existingForDate?.id,
      date: targetDate,
      hadMigraine: true,
      intensity: intensity.toInt(),
      painkillers: tookPainkillers,
      notes: notesController.text.trim(),
      causes: selectedCauses.toList(),
    );

    try {
      await MigraineDb.instance.updateEntry(entry);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      AppSnackBar.showSuccess(
        context,
        title: (widget.entry != null || existingForDate != null)
            ? 'Entry updated'
            : 'Entry added',
        message: (widget.entry != null || existingForDate != null)
            ? 'Your migraine log has been refreshed.'
            : 'Your migraine log has been saved for the day.',
      );
      _skipBackConfirm = true;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        title: 'Save failed',
        message: e.toString(),
      );
    }
  }

  Future<void> _deleteEntry() async {
    final entry = widget.entry;
    if (entry?.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete entry?"),
          content: const Text("This cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await MigraineDb.instance.deleteEntry(entry!.id!);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    AppSnackBar.showSuccess(
      context,
      title: 'Entry deleted',
      message: 'The migraine log was removed.',
    );
    _skipBackConfirm = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await _confirmDiscardChanges();
        if (!context.mounted || !shouldLeave) return;
        _skipBackConfirm = true;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.entry == null ? "Log Migraine" : "Edit Migraine"),
          actions: [
            if (widget.entry != null)
              IconButton(
                onPressed: _deleteEntry,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text("Entry date"),
                subtitle: Text(_formatDate(_entryDate ?? DateTime.now())),
                trailing: widget.entry == null
                    ? TextButton(
                        onPressed: _pickEntryDate,
                        child: const Text("Change"),
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Migraine Today?"),
                value: hadMigraine,
                onChanged: (val) {
                  setState(() {
                    hadMigraine = val ?? false;
                  });
                },
              ),
              const SizedBox(height: 8),
              const Text("Intensity"),
              Row(
                children: [
                  const Text("1"),
                  Expanded(
                    child: Slider(
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: intensity.toInt().toString(),
                      value: intensity,
                      onChanged: (val) {
                        final rounded = val.toInt();
                        if (rounded != _lastHapticIntensity) {
                          HapticFeedback.selectionClick();
                          _lastHapticIntensity = rounded;
                        }
                        setState(() {
                          intensity = val;
                        });
                      },
                    ),
                  ),
                  const Text("10"),
                ],
              ),
              const SizedBox(height: 12),
              const Text("Painkillers Taken?"),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text("Yes")),
                  ButtonSegment(value: false, label: Text("No")),
                ],
                selected: {tookPainkillers},
                onSelectionChanged: (value) {
                  setState(() {
                    tookPainkillers = value.first;
                  });
                },
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 6),
              const SizedBox(height: 16),
              const Text("Probable Cause"),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _displayCauses().map((cause) {
                  final selected = selectedCauses.contains(cause);
                  return ChoiceChip(
                    label: Text(cause),
                    selected: selected,
                    onSelected: (_) => _toggleCause(cause),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text("Notes"),
              const SizedBox(height: 6),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Additional details...",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _saveEntry,
                  child: Text(widget.entry == null ? "Save Entry" : "Update Entry"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _displayCauses() {
    final ordered = <String>[..._causes];
    for (final selected in selectedCauses) {
      if (!ordered.contains(selected)) {
        ordered.add(selected);
      }
    }
    return ordered;
  }
}
