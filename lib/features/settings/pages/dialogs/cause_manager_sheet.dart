import 'package:flutter/material.dart';

class CauseManagerSheet extends StatefulWidget {
  const CauseManagerSheet({
    super.key,
    required this.initialCauses,
    this.onChanged,
  });

  final List<String> initialCauses;
  final ValueChanged<List<String>>? onChanged;

  @override
  State<CauseManagerSheet> createState() => _CauseManagerSheetState();
}

class _CauseManagerSheetState extends State<CauseManagerSheet> {
  late List<String> _causes;
  final TextEditingController _newCauseController = TextEditingController();
  String? _errorMessage;

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

  void _commitPendingText() {
    final value = _newCauseController.text.trim();
    if (value.isEmpty) return;
    final exists = _causes.any((c) => c.toLowerCase() == value.toLowerCase());
    if (!exists) {
      final otherIndex = _causes.indexWhere((c) => c.toLowerCase() == 'other');
      if (otherIndex != -1) {
        _causes.insert(otherIndex, value);
      } else {
        _causes.add(value);
      }
      _newCauseController.clear();
      widget.onChanged?.call(_causes);
    }
  }

  void _addCause() {
    final value = _newCauseController.text.trim();
    if (value.isEmpty) return;
    final exists = _causes.any((c) => c.toLowerCase() == value.toLowerCase());
    if (exists) {
      setState(() {
        _errorMessage = '"$value" is already in your causes list';
      });
      return;
    }
    setState(() {
      _errorMessage = null;
      final otherIndex = _causes.indexWhere((c) => c.toLowerCase() == 'other');
      if (otherIndex != -1) {
        _causes.insert(otherIndex, value);
      } else {
        _causes.add(value);
      }
      _newCauseController.clear();
    });
    widget.onChanged?.call(_causes);
  }

  void _deleteCause(int index) {
    if (_causes.length <= 1) return;
    setState(() {
      _causes.removeAt(index);
    });
    widget.onChanged?.call(_causes);
  }

  void _moveCause(int index, int delta) {
    final next = index + delta;
    if (next < 0 || next >= _causes.length) return;
    setState(() {
      final item = _causes.removeAt(index);
      _causes.insert(next, item);
    });
    widget.onChanged?.call(_causes);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _commitPendingText();
        widget.onChanged?.call(_causes);
      },
      child: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
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
                      onPressed: () {
                        _commitPendingText();
                        Navigator.of(context).pop(_causes);
                      },
                      child: const Text("Done"),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newCauseController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: "Add new cause",
                          hintText: "e.g. Caffeine, Perfume, Noise",
                          errorText: _errorMessage,
                        ),
                        onChanged: (_) {
                          if (_errorMessage != null) {
                            setState(() => _errorMessage = null);
                          }
                        },
                        onSubmitted: (_) => _addCause(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: FilledButton.tonal(
                        onPressed: _addCause,
                        child: const Text("Add"),
                      ),
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
    ),
  ),
);
  }
}
