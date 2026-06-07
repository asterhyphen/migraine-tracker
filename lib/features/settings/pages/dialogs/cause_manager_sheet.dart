import 'package:flutter/material.dart';

class CauseManagerSheet extends StatefulWidget {
  const CauseManagerSheet({required this.initialCauses});

  final List<String> initialCauses;

  @override
  State<CauseManagerSheet> createState() => _CauseManagerSheetState();
}

class _CauseManagerSheetState extends State<CauseManagerSheet> {
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
