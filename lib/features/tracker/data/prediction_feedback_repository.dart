import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prediction_result.dart';

abstract class PredictionFeedbackRepository {
  Future<void> saveFeedback(PredictionFeedback feedback);
  Future<List<PredictionFeedback>> getAllFeedback();
  Future<PredictionFeedback?> getFeedbackForDate(DateTime date);
  Future<double?> getAccuracyRate();
  Future<double> getCalibrationBias({DateTime? targetDate});
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
  Future<double> getCalibrationBias({DateTime? targetDate}) async {
    final all = await getAllFeedback();
    if (all.isEmpty) return 0.0;

    final target = targetDate ?? DateTime.now();
    final targetWeekday = target.weekday;

    // 1. Calculate general gradient residual error across recent feedback items
    final recent = all.take(15).toList();
    double weightedErrorSum = 0.0;
    double totalWeights = 0.0;

    for (int i = 0; i < recent.length; i++) {
      final f = recent[i];
      final actual = f.hadActualMigraine ? 1.0 : 0.0;
      final predicted = (f.predictedScore / 100.0).clamp(0.05, 0.95);
      final residual = actual - predicted;

      // Exponential decay weight for older feedback
      final weight = math.exp(-0.08 * i);
      weightedErrorSum += residual * weight;
      totalWeights += weight;
    }

    final meanResidual = totalWeights > 0 ? weightedErrorSum / totalWeights : 0.0;
    // Learning rate factor for smooth continuous convergence
    final generalBias = (meanResidual * 0.40).clamp(-0.25, 0.25);

    // 2. Calculate day-of-week specific feedback calibration
    final sameWeekdayFeedback = all.where((f) {
      final dt = DateTime.tryParse(f.dateKey);
      return dt != null && dt.weekday == targetWeekday;
    }).toList();

    double weekdayBias = 0.0;
    if (sameWeekdayFeedback.isNotEmpty) {
      double dayErrorSum = 0.0;
      for (final f in sameWeekdayFeedback) {
        final actual = f.hadActualMigraine ? 1.0 : 0.0;
        final predicted = (f.predictedScore / 100.0).clamp(0.05, 0.95);
        dayErrorSum += (actual - predicted);
      }
      weekdayBias = (dayErrorSum / sameWeekdayFeedback.length) * 0.15;
    }

    final totalBias = (generalBias + weekdayBias).clamp(-0.30, 0.30);
    return totalBias;
  }
}
