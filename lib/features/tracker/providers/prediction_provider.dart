import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:migraine_tracker/features/tracker/data/prediction_feedback_repository.dart';
import 'package:migraine_tracker/features/tracker/models/prediction_result.dart';
import 'package:migraine_tracker/features/tracker/providers/entries_provider.dart';
import 'package:migraine_tracker/features/tracker/services/migraine_prediction_service.dart';

final predictionFeedbackRepositoryProvider =
    Provider<PredictionFeedbackRepository>(
      (ref) => const SharedPrefsPredictionFeedbackRepository(),
    );

final migrainePredictionServiceProvider =
    Provider<MigrainePredictionService>((ref) => const MigrainePredictionService());

final predictionFeedbackForTodayProvider =
    FutureProvider.autoDispose<PredictionFeedback?>((ref) async {
      final repository = ref.watch(predictionFeedbackRepositoryProvider);
      return repository.getFeedbackForDate(DateTime.now());
    });

final migrainePredictionProvider =
    AsyncNotifierProvider<MigrainePredictionController, PredictionResult>(
      MigrainePredictionController.new,
    );

class MigrainePredictionController extends AsyncNotifier<PredictionResult> {
  PredictionFeedbackRepository get _feedbackRepo =>
      ref.read(predictionFeedbackRepositoryProvider);
  MigrainePredictionService get _service =>
      ref.read(migrainePredictionServiceProvider);

  @override
  Future<PredictionResult> build() async {
    final entries = await ref.watch(migraineEntriesProvider.future);
    final bias = await _feedbackRepo.getCalibrationBias();
    final accuracy = await _feedbackRepo.getAccuracyRate();
    final allFeedback = await _feedbackRepo.getAllFeedback();

    return _service.predictRisk(
      entries: entries,
      targetDate: DateTime.now(),
      calibrationBias: bias,
      accuracyRate: accuracy,
      totalFeedbackCount: allFeedback.length,
    );
  }

  Future<void> submitFeedback({
    required bool wasAccurate,
    required bool hadActualMigraine,
  }) async {
    final current = state.value;
    final now = DateTime.now();
    final y = now.year;
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final dateKey = '$y-$m-$d';

    final feedback = PredictionFeedback(
      dateKey: dateKey,
      predictedRisk: current?.riskLabel ?? 'Moderate',
      predictedScore: current?.scorePercent ?? 50,
      wasAccurate: wasAccurate,
      hadActualMigraine: hadActualMigraine,
      timestamp: now,
    );

    await _feedbackRepo.saveFeedback(feedback);
    ref.invalidate(predictionFeedbackForTodayProvider);
    ref.invalidateSelf();
  }
}
