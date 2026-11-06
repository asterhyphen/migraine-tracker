import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/tracker/models/migraine_entry.dart';

void main() {
  group('MigraineOutcome', () {
    test('fromString parses correctly and defaults to unknown', () {
      expect(MigraineOutcome.fromString('unknown'), MigraineOutcome.unknown);
      expect(MigraineOutcome.fromString('resolved'), MigraineOutcome.resolved);
      expect(MigraineOutcome.fromString('persisted'), MigraineOutcome.persisted);
      expect(MigraineOutcome.fromString('Resolved'), MigraineOutcome.resolved);
      expect(MigraineOutcome.fromString('PERSISTED'), MigraineOutcome.persisted);
      expect(MigraineOutcome.fromString(null), MigraineOutcome.unknown);
      expect(MigraineOutcome.fromString(''), MigraineOutcome.unknown);
      expect(MigraineOutcome.fromString('invalid_value'), MigraineOutcome.unknown);
    });
  });

  group('MigraineEntry outcome serialization', () {
    test('defaults to unknown outcome', () {
      final entry = MigraineEntry(
        date: DateTime(2026, 6, 1),
        hadMigraine: true,
        intensity: 5,
        painkillers: false,
        notes: 'Test note',
      );
      expect(entry.outcome, MigraineOutcome.unknown);
    });

    test('serializes and deserializes outcome via toMap and fromMap', () {
      final entry = MigraineEntry(
        id: 42,
        date: DateTime(2026, 6, 1, 10, 0),
        hadMigraine: true,
        intensity: 7,
        painkillers: true,
        notes: 'Headache with aura',
        causes: ['Stress', 'Coffee'],
        outcome: MigraineOutcome.resolved,
      );

      final map = entry.toMap();
      expect(map['outcome'], 'resolved');

      final reconstructed = MigraineEntry.fromMap(map);
      expect(reconstructed.id, 42);
      expect(reconstructed.outcome, MigraineOutcome.resolved);
      expect(reconstructed.hadMigraine, true);
      expect(reconstructed.intensity, 7);
      expect(reconstructed.painkillers, true);
      expect(reconstructed.notes, 'Headache with aura');
      expect(reconstructed.causes, ['Stress', 'Coffee']);
    });

    test('copyWith updates outcome correctly', () {
      final entry = MigraineEntry(
        date: DateTime(2026, 6, 1),
        hadMigraine: true,
        intensity: 4,
        painkillers: false,
        notes: '',
        outcome: MigraineOutcome.unknown,
      );

      final updated = entry.copyWith(outcome: MigraineOutcome.persisted);
      expect(updated.outcome, MigraineOutcome.persisted);
      expect(entry.outcome, MigraineOutcome.unknown);
    });
  });
}
