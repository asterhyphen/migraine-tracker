import 'package:flutter/material.dart';

enum PredictionRisk { low, moderate, high }

class RiskFactor {
  const RiskFactor({
    required this.title,
    required this.description,
    required this.impactWeight,
    required this.icon,
  });

  final String title;
  final String description;
  final double impactWeight; // e.g., +0.25
  final IconData icon;
}

class PredictionResult {
  const PredictionResult({
    required this.riskLevel,
    required this.probability,
    required this.factors,
    required this.recommendations,
    required this.hasSufficientData,
    required this.meanIntervalDays,
    required this.daysSinceLast,
    required this.accuracyRate,
    required this.totalFeedbackCount,
    this.calibrationBias = 0.0,
  });

  final PredictionRisk riskLevel;
  final double probability; // 0.0 to 1.0
  final List<RiskFactor> factors;
  final List<String> recommendations;
  final bool hasSufficientData;
  final double? meanIntervalDays;
  final int daysSinceLast;
  final double? accuracyRate; // e.g. 0.85
  final int totalFeedbackCount;
  final double calibrationBias;

  int get scorePercent => (probability * 100).round().clamp(0, 100);

  String get riskLabel {
    switch (riskLevel) {
      case PredictionRisk.low:
        return "Low Risk";
      case PredictionRisk.moderate:
        return "Moderate Risk";
      case PredictionRisk.high:
        return "High Risk";
    }
  }

  Color get riskColor {
    switch (riskLevel) {
      case PredictionRisk.low:
        return const Color(0xFF10AC84); // Emerald Teal
      case PredictionRisk.moderate:
        return const Color(0xFFFF9F43); // Amber Orange
      case PredictionRisk.high:
        return const Color(0xFFFF5252); // Coral Red
    }
  }
}

class PredictionFeedback {
  const PredictionFeedback({
    required this.dateKey,
    required this.predictedRisk,
    required this.predictedScore,
    required this.wasAccurate,
    required this.hadActualMigraine,
    required this.timestamp,
  });

  final String dateKey; // yyyy-MM-dd
  final String predictedRisk;
  final int predictedScore;
  final bool wasAccurate;
  final bool hadActualMigraine;
  final DateTime timestamp;

  Map<String, Object?> toJson() {
    return {
      'dateKey': dateKey,
      'predictedRisk': predictedRisk,
      'predictedScore': predictedScore,
      'wasAccurate': wasAccurate,
      'hadActualMigraine': hadActualMigraine,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PredictionFeedback.fromJson(Map<String, Object?> json) {
    return PredictionFeedback(
      dateKey: json['dateKey'] as String? ?? '',
      predictedRisk: json['predictedRisk'] as String? ?? 'low',
      predictedScore: (json['predictedScore'] as num?)?.toInt() ?? 0,
      wasAccurate: json['wasAccurate'] as bool? ?? true,
      hadActualMigraine: json['hadActualMigraine'] as bool? ?? false,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
