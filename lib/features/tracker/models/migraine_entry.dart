enum MigraineOutcome {
  unknown('unknown', 'Unknown'),
  resolved('resolved', 'Got Better'),
  persisted('persisted', 'Persisted');

  const MigraineOutcome(this.value, this.label);
  final String value;
  final String label;

  static MigraineOutcome fromString(String? raw) {
    if (raw == null) return MigraineOutcome.unknown;
    final lower = raw.trim().toLowerCase();
    for (final outcome in MigraineOutcome.values) {
      if (outcome.value == lower || outcome.name.toLowerCase() == lower) {
        return outcome;
      }
    }
    return MigraineOutcome.unknown;
  }
}

class MigraineEntry {
  MigraineEntry({
    this.id,
    required this.date,
    required this.hadMigraine,
    required this.intensity,
    required this.painkillers,
    required this.notes,
    this.causes = const [],
    this.outcome = MigraineOutcome.unknown,
  });

  final int? id;
  final DateTime date;
  final bool hadMigraine;
  final int intensity;
  final bool painkillers;
  final String notes;
  final List<String> causes;
  final MigraineOutcome outcome;

  MigraineEntry copyWith({
    int? id,
    DateTime? date,
    bool? hadMigraine,
    int? intensity,
    bool? painkillers,
    String? notes,
    List<String>? causes,
    MigraineOutcome? outcome,
  }) {
    return MigraineEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      hadMigraine: hadMigraine ?? this.hadMigraine,
      intensity: intensity ?? this.intensity,
      painkillers: painkillers ?? this.painkillers,
      notes: notes ?? this.notes,
      causes: causes ?? this.causes,
      outcome: outcome ?? this.outcome,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'had_migraine': hadMigraine ? 1 : 0,
      'intensity': intensity,
      'painkillers': painkillers ? 1 : 0,
      'notes': notes,
      'causes': causes.join(','),
      'outcome': outcome.value,
    };
  }

  static MigraineEntry fromMap(Map<String, Object?> map) {
    return MigraineEntry(
      id: map['id'] as int?,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      hadMigraine: (map['had_migraine'] as int) == 1,
      intensity: (map['intensity'] as int?) ?? 0,
      painkillers: (map['painkillers'] as int?) == 1,
      notes: (map['notes'] as String?) ?? '',
      causes: _parseCauses(map['causes'] as String?),
      outcome: MigraineOutcome.fromString(map['outcome'] as String?),
    );
  }

  static List<String> _parseCauses(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    return raw
        .split(',')
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();
  }
}
