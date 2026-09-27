import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:migraine_tracker/features/tracker/models/migraine_entry.dart';
import '../models/prediction_result.dart';

class MigrainePredictionService {
  const MigrainePredictionService();

  PredictionResult predictRisk({
    required List<MigraineEntry> entries,
    DateTime? targetDate,
    double calibrationBias = 0.0,
    double? accuracyRate,
    int totalFeedbackCount = 0,
  }) {
    final target = targetDate ?? DateTime.now();
    final migraineEntries = entries
        .where((e) => e.hadMigraine)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (migraineEntries.length < 2) {
      return PredictionResult(
        riskLevel: PredictionRisk.low,
        probability: 0.15,
        factors: const [
          RiskFactor(
            title: "Insufficient Historical Data",
            description: "Log at least 2 migraine entries to unlock personalized pattern forecasting.",
            impactWeight: 0.0,
            icon: Icons.hourglass_empty_rounded,
          ),
        ],
        recommendations: const [
          "Continue logging migraine episodes and triggers when they occur.",
          "Track your sleep, hydration, and daily stress levels.",
        ],
        hasSufficientData: false,
        meanIntervalDays: null,
        daysSinceLast: migraineEntries.isEmpty
            ? 0
            : target.difference(migraineEntries.first.date).inDays.clamp(0, 999),
        accuracyRate: accuracyRate,
        totalFeedbackCount: totalFeedbackCount,
      );
    }

    final latestEntry = migraineEntries.first;
    final daysSinceLast = target
        .difference(
          DateTime(
            latestEntry.date.year,
            latestEntry.date.month,
            latestEntry.date.day,
          ),
        )
        .inDays
        .clamp(0, 999);

    // 1. Calculate Inter-Migraine Intervals (Days between episodes)
    final intervals = <int>[];
    for (int i = 0; i < migraineEntries.length - 1; i++) {
      final diff = migraineEntries[i].date
          .difference(migraineEntries[i + 1].date)
          .inDays
          .abs();
      if (diff > 0) intervals.add(diff);
    }

    final meanInterval = intervals.isEmpty
        ? 7.0
        : intervals.reduce((a, b) => a + b) / intervals.length;

    // Variance & Standard deviation
    double variance = 0.0;
    for (final interval in intervals) {
      variance += math.pow(interval - meanInterval, 2);
    }
    final stdDev = intervals.isNotEmpty
        ? math.sqrt(variance / intervals.length)
        : 2.0;

    // 2. Interval-based Risk Score (0.0 to 1.0)
    double intervalScore = 0.20;
    final factors = <RiskFactor>[];

    if (daysSinceLast == 0) {
      // If already had one today
      intervalScore = 0.40;
      factors.add(
        const RiskFactor(
          title: "Active Episode Window",
          description: "A migraine has already occurred today; residual symptoms may persist.",
          impactWeight: 0.20,
          icon: Icons.crisis_alert_rounded,
        ),
      );
    } else if (daysSinceLast == 1) {
      // Next day post-drome
      intervalScore = 0.25;
      factors.add(
        const RiskFactor(
          title: "Post-Drome Recovery Phase",
          description: "1 day since last migraine. Vulnerability is typically reduced during early recovery.",
          impactWeight: -0.15,
          icon: Icons.spa_rounded,
        ),
      );
    } else {
      // Normal cycle evaluation
      final lowerBound = (meanInterval - stdDev).clamp(1.0, meanInterval);
      final upperBound = meanInterval + (stdDev * 1.2);

      if (daysSinceLast >= lowerBound && daysSinceLast <= upperBound) {
        // In the peak expected cycle window
        final proximity = 1.0 - ((daysSinceLast - meanInterval).abs() / (stdDev + 1.0)).clamp(0.0, 0.8);
        intervalScore = 0.55 + (proximity * 0.35);
        factors.add(
          RiskFactor(
            title: "Typical Cycle Window Reached",
            description: "Day $daysSinceLast since last migraine falls into your typical ${meanInterval.toStringAsFixed(1)}-day recurrence cycle.",
            impactWeight: 0.35,
            icon: Icons.cyclone_rounded,
          ),
        );
      } else if (daysSinceLast > upperBound) {
        // Overdue based on historical rhythm
        intervalScore = 0.65;
        factors.add(
          RiskFactor(
            title: "Extended Pain-Free Stretch",
            description: "$daysSinceLast days without a migraine (average cycle is ${meanInterval.toStringAsFixed(1)} days).",
            impactWeight: 0.25,
            icon: Icons.timer_outlined,
          ),
        );
      } else {
        // Safely before typical interval
        intervalScore = 0.20;
        factors.add(
          RiskFactor(
            title: "Within Safe Cycle Window",
            description: "$daysSinceLast days since last episode, well before your average ${meanInterval.toStringAsFixed(1)}-day cycle.",
            impactWeight: -0.20,
            icon: Icons.shield_outlined,
          ),
        );
      }
    }

    // 3. Day of Week (Circadian / Weekly Pattern)
    final targetWeekday = target.weekday;
    final weekdayCounts = List<int>.filled(8, 0);
    for (final e in migraineEntries) {
      weekdayCounts[e.date.weekday] += 1;
    }
    final targetDayCount = weekdayCounts[targetWeekday];
    final avgPerWeekday = migraineEntries.length / 7.0;
    double weekdayScore = 0.20;

    if (targetDayCount > (avgPerWeekday * 1.35) && targetDayCount >= 2) {
      weekdayScore = 0.70;
      factors.add(
        RiskFactor(
          title: "Higher ${_weekdayName(targetWeekday)} Frequency",
          description: "$targetDayCount of your recorded migraines occurred on a ${_weekdayName(targetWeekday)}.",
          impactWeight: 0.20,
          icon: Icons.calendar_today_rounded,
        ),
      );
    } else if (targetDayCount < (avgPerWeekday * 0.5) && migraineEntries.length >= 6) {
      weekdayScore = 0.10;
      factors.add(
        RiskFactor(
          title: "Favorable Day Pattern",
          description: "Migraines are historically rare for you on ${_weekdayName(targetWeekday)}s.",
          impactWeight: -0.15,
          icon: Icons.sentiment_satisfied_alt_rounded,
        ),
      );
    }

    // 4. Recent Intensity & Cluster Momentum
    final recentEntries = migraineEntries.take(3).toList();
    double momentumScore = 0.15;
    if (recentEntries.isNotEmpty) {
      final recentAvgIntensity = recentEntries.map((e) => e.intensity).reduce((a, b) => a + b) / recentEntries.length;
      if (recentAvgIntensity >= 7.0) {
        momentumScore = 0.65;
        factors.add(
          RiskFactor(
            title: "High Recent Intensity",
            description: "Average pain intensity over your last 3 episodes was high (${recentAvgIntensity.toStringAsFixed(1)}/10).",
            impactWeight: 0.15,
            icon: Icons.bolt_rounded,
          ),
        );
      }
    }

    // 5. Medication Overuse / Rebound Risk
    final last7DaysEntries = entries.where((e) {
      final diff = target.difference(e.date).inDays;
      return diff >= 0 && diff <= 7;
    }).toList();
    final painkillerDays = last7DaysEntries.where((e) => e.painkillers).length;
    double medScore = 0.10;
    if (painkillerDays >= 3) {
      medScore = 0.60;
      factors.add(
        RiskFactor(
          title: "Medication Rebound Risk",
          description: "Painkillers taken on $painkillerDays days in the past week, increasing rebound susceptibility.",
          impactWeight: 0.15,
          icon: Icons.medication_liquid_rounded,
        ),
      );
    }

    // 6. Combine weighted probability + calibration feedback bias
    double finalProbability = (intervalScore * 0.45) +
        (weekdayScore * 0.25) +
        (momentumScore * 0.15) +
        (medScore * 0.15) +
        calibrationBias;

    finalProbability = finalProbability.clamp(0.05, 0.95);

    final PredictionRisk riskLevel;
    if (finalProbability >= 0.60) {
      riskLevel = PredictionRisk.high;
    } else if (finalProbability >= 0.35) {
      riskLevel = PredictionRisk.moderate;
    } else {
      riskLevel = PredictionRisk.low;
    }

    // 7. Contextual Recommendations
    final recommendations = <String>[];
    if (riskLevel == PredictionRisk.high) {
      recommendations.add("Keep your rescue medication within easy reach.");
      recommendations.add("Prioritize 8+ hours of restful sleep and avoid bright screen glare.");
      recommendations.add("Drink plenty of water and stay mindful of known dietary triggers.");
    } else if (riskLevel == PredictionRisk.moderate) {
      recommendations.add("Maintain regular meal and hydration schedules today.");
      recommendations.add("Take short visual breaks if working in front of screens.");
      recommendations.add("Be mindful of sudden stress or caffeine fluctuations.");
    } else {
      recommendations.add("Low expected risk today. Continue your healthy daily routine.");
      recommendations.add("Stay hydrated and enjoy your pain-free day.");
    }

    return PredictionResult(
      riskLevel: riskLevel,
      probability: finalProbability,
      factors: factors,
      recommendations: recommendations,
      hasSufficientData: true,
      meanIntervalDays: meanInterval,
      daysSinceLast: daysSinceLast,
      accuracyRate: accuracyRate,
      totalFeedbackCount: totalFeedbackCount,
    );
  }

  static String _weekdayName(int weekday) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    if (weekday >= 1 && weekday <= 7) return names[weekday - 1];
    return 'Day';
  }
}
