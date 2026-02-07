import 'package:flutter/material.dart';

import '../data/migraine_db.dart';
import '../data/migraine_entry.dart';

class LogMigrainePage extends StatefulWidget {
  const LogMigrainePage({super.key});

  @override
  State<LogMigrainePage> createState() => _LogMigrainePageState();
}

class _LogMigrainePageState extends State<LogMigrainePage> {
  bool hadMigraine = true;
  double intensity = 5;
  bool tookPainkillers = false;
  final TextEditingController medicationController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  final List<String> causes = const [
    "Stress",
    "Lack of Sleep",
    "Screen Time",
    "Skipped Meal",
    "Weather",
    "Other",
  ];

  final Set<String> selectedCauses = {};

  @override
  void dispose() {
    medicationController.dispose();
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

  void _saveEntry() {
    if (!hadMigraine) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No migraine to save.")),
      );
      return;
    }

    final entry = MigraineEntry(
      date: DateTime.now(),
      hadMigraine: true,
      intensity: intensity.toInt(),
      painkillers: tookPainkillers,
      medication: medicationController.text.trim(),
      notes: notesController.text.trim(),
      causes: selectedCauses.toList(),
    );

    MigraineDb.instance.insertEntry(entry).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Entry saved.")),
      );
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Log Migraine"),
        actions: const [
          IconButton(
            onPressed: null,
            icon: Icon(Icons.menu),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const Text("Medication"),
            const SizedBox(height: 6),
            TextField(
              controller: medicationController,
              decoration: const InputDecoration(
                hintText: "e.g. Ibuprofen",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text("Probable Cause"),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: causes.map((cause) {
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
                child: const Text("Save Entry"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
