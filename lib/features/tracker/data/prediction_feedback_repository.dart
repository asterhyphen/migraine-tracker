import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prediction_result.dart';

abstract class PredictionFeedbackRepository {
  Future<void> saveFeedback(PredictionFeedback feedback);
  Future<List<PredictionFeedback>> getAllFeedback();
  Future<PredictionFeedback?> getFeedbackForDate(DateTime date);
  Future<double?> getAccuracyRate();
  Future<double> getCalibrationBias();
}

class SharedPrefsPredictionFeedbackRepository
    implements PredictionFeedbackRepository {
  const SharedPrefsPredictionFeedbackRepository();

  static const _feedbackKey = 'prediction_feedback_history';

  String _dateToKey(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Future<void> saveFeedback(PredictionFeedback feedback) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await getAllFeedback();

    // Replace if exists for date, else append
    final updated = all.where((f) => f.dateKey != feedback.dateKey).toList()
      ..add(feedback);

    final raw = jsonEncode(updated.map((f) => f.toJson()).toList());
    await prefs.setString(_feedbackKey, raw);
  }

  @override
  Future<List<PredictionFeedback>> getAllFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_feedbackKey);
    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map(
            (item) => PredictionFeedback.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (_) {
      return [];
    }
  }

  @override
  Future<PredictionFeedback?> getFeedbackForDate(DateTime date) async {
    final key = _dateToKey(date);
    final all = await getAllFeedback();
    for (final item in all) {
      if (item.dateKey == key) return item;
    }
    return null;
  }

  @override
  Future<double?> getAccuracyRate() async {
    final all = await getAllFeedback();
    if (all.isEmpty) return null;
    final accurateCount = all.where((f) => f.wasAccurate).length;
    return accurateCount / all.length;
  }

  @override
  Future<double> getCalibrationBias() async {
    // If user consistently marks High Risk predictions as inaccurate (false positives),
    // reduce probability bias. If user marks Low Risk as inaccurate (false negatives),
    // increase probability bias.
    final all = await getAllFeedback();
    if (all.length < 3) return 0.0;

    final recent = all.take(10).toList();
    double bias = 0.0;
    for (final f in recent) {
      if (!f.wasAccurate) {
        if (f.predictedScore >= 60 && !f.hadActualMigraine) {
          bias -= 0.04; // Dampen over-predictions
        } else if (f.predictedScore < 40 && f.hadActualMigraine) {
          bias += 0.04; // Boost under-predictions
        }
      }
    }
    return bias.clamp(-0.25, 0.25);
  }
}
