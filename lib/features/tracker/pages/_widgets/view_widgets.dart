import 'package:flutter/material.dart';
import '../_utils/view_utils.dart';

class ComparisonStatsCard extends StatelessWidget {
  const ComparisonStatsCard({required this.stats});

  final EntryComparisonStats stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.13)),
        color: scheme.surface.withValues(alpha: 0.74),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Compared with your logs",
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 340;
              final cards = [
                StatTile(
                  label: "Overall avg",
                  value: stats.averageIntensity.toStringAsFixed(1),
                  detail: _deltaLabel(stats.intensityDelta),
                ),
                StatTile(
                  label: "This month avg",
                  value: stats.monthAverageIntensity?.toStringAsFixed(1) ?? "-",
                  detail: stats.monthIntensityDelta == null
                      ? "No other logs"
                      : _deltaLabel(stats.monthIntensityDelta!),
                ),
                StatTile(
                  label: "Range",
                  value: "${stats.minIntensity}-${stats.maxIntensity}",
                  detail: "Above ${stats.percentile}% of logs",
                ),
              ];

              if (isNarrow) {
                return Column(
                  children: [
                    for (final card in cards) ...[
                      card,
                      if (card != cards.last) const SizedBox(height: 8),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (final card in cards) ...[
                    Expanded(child: card),
                    if (card != cards.last) const SizedBox(width: 8),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            "Based on ${stats.totalCompared} other ${stats.totalCompared == 1 ? 'migraine entry' : 'migraine entries'}.",
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }

  static String _deltaLabel(double value) {
    final absValue = value.abs().toStringAsFixed(1);
    if (value.abs() < 0.05) return "Same as avg";
    return value > 0 ? "$absValue above avg" : "$absValue below avg";
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: scheme.primary.withValues(alpha: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: scheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: scheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}
