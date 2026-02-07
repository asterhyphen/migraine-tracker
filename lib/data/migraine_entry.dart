class MigraineEntry {
  MigraineEntry({
    this.id,
    required this.date,
    required this.hadMigraine,
    required this.intensity,
    required this.painkillers,
    required this.medication,
    required this.notes,
    required this.causes,
  });

  final int? id;
  final DateTime date;
  final bool hadMigraine;
  final int intensity;
  final bool painkillers;
  final String medication;
  final String notes;
  final List<String> causes;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'had_migraine': hadMigraine ? 1 : 0,
      'intensity': intensity,
      'painkillers': painkillers ? 1 : 0,
      'medication': medication,
      'notes': notes,
      'causes': causes.join(','),
    };
  }

  static MigraineEntry fromMap(Map<String, Object?> map) {
    return MigraineEntry(
      id: map['id'] as int?,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      hadMigraine: (map['had_migraine'] as int) == 1,
      intensity: (map['intensity'] as int?) ?? 0,
      painkillers: (map['painkillers'] as int?) == 1,
      medication: (map['medication'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
      causes: _parseCauses(map['causes'] as String?),
    );
  }

  static List<String> _parseCauses(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    return raw.split(',').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
  }
}
