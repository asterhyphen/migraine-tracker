import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.dob,
    this.name,
  });

  final DateTime dob;
  final String? name;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool hadMigraine = false;
  double intensity = 5;

  int calculateAge() {
    DateTime today = DateTime.now();
    int age = today.year - widget.dob.year;

    if (today.month < widget.dob.month ||
        (today.month == widget.dob.month && today.day < widget.dob.day)) {
      age--;
    }
    return age;
  }

  void saveEntry() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          hadMigraine
              ? "Migraine logged. Intensity: ${intensity.toInt()}"
              : "No migraine today logged",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Migraine Prototype")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.name != null && widget.name!.isNotEmpty) ...[
              Text(
                "Hello, ${widget.name}",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              "Age: ${calculateAge()}",
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 30),
            SwitchListTile(
              title: const Text("Had Migraine Today"),
              value: hadMigraine,
              onChanged: (val) {
                setState(() {
                  hadMigraine = val;
                });
              },
            ),
            if (hadMigraine) ...[
              const SizedBox(height: 20),
              const Text("Intensity"),
              Slider(
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
            ],
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: saveEntry,
                child: const Text("Save Today"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
