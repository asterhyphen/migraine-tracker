import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/tracker/models/migraine_entry.dart';
import 'package:migraine_tracker/features/tracker/models/prediction_result.dart';
import 'package:migraine_tracker/features/tracker/services/migraine_prediction_service.dart';

void main() {
  const service = MigrainePredictionService();

  test('returns baseline low risk when entries count is less than 2', () {
    final result = service.predictRisk(
      entries: [
        MigraineEntry(
          date: DateTime(2026, 9, 20),
          hadMigraine: true,
          intensity: 5,
          painkillers: false,
          notes: '',
          causes: const [],
        ),
      ],
      targetDate: DateTime(2026, 9, 27),
    );

    expect(result.hasSufficientData, isFalse);
    expect(result.riskLevel, PredictionRisk.low);
    expect(result.probability, 0.15);
  });

  test('calculates higher risk when within typical cycle window', () {
    // Episodes roughly every 5 days
    final entries = [
      MigraineEntry(
        date: DateTime(2026, 9, 22),
        hadMigraine: true,
        intensity: 7,
        painkillers: false,
        notes: '',
        causes: const ['Stress'],
      ),
      MigraineEntry(
        date: DateTime(2026, 9, 17),
        hadMigraine: true,
        intensity: 8,
        painkillers: true,
        notes: '',
        causes: const [],
      ),
      MigraineEntry(
        date: DateTime(2026, 9, 12),
        hadMigraine: true,
        intensity: 6,
        painkillers: false,
        notes: '',
        causes: const [],
      ),
    ];

    final result = service.predictRisk(
      entries: entries,
      targetDate: DateTime(2026, 9, 27), // 5 days after Sep 22
    );

    expect(result.hasSufficientData, isTrue);
    expect(result.daysSinceLast, 5);
    expect(result.meanIntervalDays, closeTo(5.0, 0.1));
    expect(result.probability, greaterThan(0.50));
    expect(
      result.factors.any((f) => f.title.contains("Cycle Window Reached")),
      isTrue,
    );
  });

  test('applies calibration bias correctly from feedback', () {
    final entries = [
      MigraineEntry(
        date: DateTime(2026, 9, 22),
        hadMigraine: true,
        intensity: 4,
        painkillers: false,
        notes: '',
        causes: const [],
      ),
      MigraineEntry(
        date: DateTime(2026, 9, 17),
        hadMigraine: true,
        intensity: 4,
        painkillers: false,
        notes: '',
        causes: const [],
      ),
    ];

    final raw = service.predictRisk(
      entries: entries,
      targetDate: DateTime(2026, 9, 27),
      calibrationBias: 0.0,
    );

    final biased = service.predictRisk(
      entries: entries,
      targetDate: DateTime(2026, 9, 27),
      calibrationBias: -0.15,
    );

    expect(biased.probability, lessThan(raw.probability));
  });
}
