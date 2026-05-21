import 'package:flutter/material.dart';
import 'package:migraine_tracker/core/theme/app_theme.dart';
import 'package:migraine_tracker/core/widgets/wavy_surface.dart';
import '../_utils/stats_utils.dart';

class StatsLoadingView extends StatelessWidget {
  const StatsLoadingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Statistics")),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: const [
          StatsSkeletonBox(height: 80, radius: 18),
          SizedBox(height: 24),
          StatsSkeletonBox(height: 18, width: 120),
          SizedBox(height: 12),
          StatsSkeletonBox(height: 200, radius: 14),
          SizedBox(height: 16),
          StatsSkeletonBox(height: 170, radius: 14),
        ],
      ),
    );
  }
}

class StatsEmptyState extends StatelessWidget {
  const StatsEmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.12)),
        color: scheme.surface.withValues(alpha: 0.72),
      ),
      child: Column(
        children: [
          Icon(Icons.insights_outlined, size: 36, color: scheme.primary),
          const SizedBox(height: 10),
          Text(
            "No stats yet",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            "Log your first migraine entry to unlock trends, triggers, and intensity charts.",
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.72)),
          ),
          const SizedBox(height: 10),
          Text(
            "Tip: Pull down to refresh after adding new logs.",
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: 0.58),
            ),
          ),
        ],
      ),
    );
  }
}

class StatsSkeletonBox extends StatelessWidget {
  const StatsSkeletonBox({
    required this.height,
    this.width = double.infinity,
    this.radius = 10,
  });

  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            colors: [
              scheme.surface.withValues(alpha: 0.85),
              scheme.surface.withValues(alpha: 0.56),
            ],
          ),
        ),
      ),
    );
  }
}

class MonthFilterCard extends StatelessWidget {
  const MonthFilterCard({
    required this.selectedMonth,
    required this.compareMonth,
    required this.options,
    required this.onSelectedChanged,
    required this.onCompareChanged,
  });

  final DateTime selectedMonth;
  final DateTime? compareMonth;
  final List<DateTime> options;
  final ValueChanged<DateTime> onSelectedChanged;
  final ValueChanged<DateTime?> onCompareChanged;

  String _monthLabel(DateTime month) {
    const labels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return "${labels[month.month - 1]} ${month.year}";
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.13)),
        color: scheme.surface.withValues(alpha: 0.74),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<DateTime>(
            initialValue: selectedMonth,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: "Filter by month",
              border: OutlineInputBorder(),
            ),
            items: options
                .map(
                  (month) => DropdownMenuItem<DateTime>(
                    value: month,
                    child: Text(_monthLabel(month)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onSelectedChanged(value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<DateTime?>(
            initialValue: compareMonth,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: "Compare with",
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<DateTime?>(
                value: null,
                child: Text("No comparison"),
              ),
              ...options
                  .where(
                    (month) =>
                        month.year != selectedMonth.year ||
                        month.month != selectedMonth.month,
                  )
                  .map(
                    (month) => DropdownMenuItem<DateTime?>(
                      value: month,
                      child: Text(_monthLabel(month)),
                    ),
                  ),
            ],
            onChanged: onCompareChanged,
          ),
        ],
      ),
    );
  }
}

class SelectedMonthEmptyState extends StatelessWidget {
  const SelectedMonthEmptyState({required this.monthLabel});

  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.13)),
        color: scheme.surface.withValues(alpha: 0.74),
      ),
      child: Row(
        children: [
          Icon(Icons.event_busy_outlined, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "No entries for $monthLabel. Showing empty monthly stats.",
              style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.72)),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    required this.totalEntries,
    required this.monthLabel,
    this.compareLabel,
  });

  final int totalEntries;
  final String monthLabel;
  final String? compareLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return WavySurface(
      borderRadius: BorderRadius.circular(18),
      borderColor: scheme.primary.withValues(alpha: 0.20),
      gradient: LinearGradient(
        colors: [scheme.surface, scheme.tertiary.withValues(alpha: 0.14)],
        begin: Alignment.topCenter,
        end: Alignment.bottomRight,
      ),
      waveColorA: scheme.primary.withValues(alpha: 0.10),
      waveColorB: scheme.secondary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.15),
              ),
              child: Icon(Icons.analytics_rounded, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Stats Overview",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    compareLabel == null
                        ? "$totalEntries logged migraines • $monthLabel"
                        : "$totalEntries logged migraines • $monthLabel vs $compareLabel",
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.68),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            color: scheme.onSurface.withValues(alpha: 0.62),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class ChartCard extends StatelessWidget {
  const ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.13)),
        color: scheme.surface.withValues(alpha: 0.74),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(height: 140, child: child),
        ],
      ),
    );
  }
}

class InsightCard extends StatelessWidget {
  const InsightCard({
    required this.title,
    required this.value,
    required this.subtitle,
    this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: '$title: $value - $subtitle',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 170,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: scheme.onSurface.withValues(alpha: 0.13),
              ),
              color: scheme.surface.withValues(alpha: 0.74),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ComparisonCard extends StatelessWidget {
  const ComparisonCard({required this.item});

  final ComparisonItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isNeutral = item.deltaLabel == "No change";
    final isPositive = item.deltaLabel.startsWith("+");
    final deltaColor = isNeutral
        ? scheme.onSurface.withValues(alpha: 0.6)
        : isPositive
        ? scheme.primary
        : scheme.error;

    return Tooltip(
      message:
          '${item.title}: ${item.selectedValue} vs ${item.compareValue} (${item.deltaLabel})',
      child: Container(
        width: 220,
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
              item.title,
              style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 8),
            Text(
              "${item.selectedValue} vs ${item.compareValue}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              item.deltaLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: deltaColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.subtitle,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BarChart extends StatelessWidget {
  const BarChart({required this.data});

  final List<BarDatum> data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxValue = data.isEmpty
        ? 1.0
        : data.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((datum) {
        final height = maxValue == 0 ? 0.0 : (datum.value / maxValue) * 100;
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Tooltip(
                message: '${datum.label}: ${datum.value.toStringAsFixed(1)}',
                child: Container(
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: scheme.barGradient,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(datum.label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class CauseList extends StatelessWidget {
  const CauseList({required this.data});

  final List<CauseDatum> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text("No causes logged"));
    }
    return Column(
      children: data.take(3).map((item) {
        return GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(item.label),
                content: Text(
                  '${item.count} occurrences (${(item.percent * 100).toStringAsFixed(1)}%)',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: LinearProgressIndicator(
                    value: item.percent,
                    minHeight: 6,
                    backgroundColor: Theme.of(context).colorScheme.faintTrack,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class Gauge extends StatelessWidget {
  const Gauge({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    return Tooltip(
      message: 'Painkiller usage: $percent%',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "$percent%",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: Theme.of(context).colorScheme.faintTrack,
            ),
          ],
        ),
      ),
    );
  }
}

class LineChart extends StatelessWidget {
  const LineChart({required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const Center(child: Text("No entries yet"));
    }
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Intensity over last 14 days: ${values.join(', ')}',
      child: CustomPaint(
        painter: LinePainter(
          values: values,
          lineColor: scheme.chartLine,
          pointColor: scheme.chartPoint,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class LinePainter extends CustomPainter {
  LinePainter({
    required this.values,
    required this.lineColor,
    required this.pointColor,
  });

  final List<int> values;
  final Color lineColor;
  final Color pointColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxVal = values.reduce((a, b) => a > b ? a : b).toDouble();

    // Draw intensity zones
    const lowThreshold = 3.0; // 0-3: Low intensity
    const moderateThreshold = 6.0; // 4-6: Moderate intensity
    const maxIntensity = 10.0; // 7-10: High intensity

    // Green zone (low intensity)
    final greenHeight = (lowThreshold / maxIntensity) * size.height;
    final greenRect = Rect.fromLTWH(
      0,
      size.height - greenHeight,
      size.width,
      greenHeight,
    );
    canvas.drawRect(
      greenRect,
      Paint()..color = Color.fromARGB(40, 76, 175, 80),
    ); // Green with transparency

    // Yellow zone (moderate intensity)
    final yellowHeight =
        ((moderateThreshold - lowThreshold) / maxIntensity) * size.height;
    final yellowRect = Rect.fromLTWH(
      0,
      size.height - greenHeight - yellowHeight,
      size.width,
      yellowHeight,
    );
    canvas.drawRect(
      yellowRect,
      Paint()..color = Color.fromARGB(40, 255, 193, 7),
    ); // Yellow with transparency

    // Red zone (high intensity)
    final redHeight =
        ((maxIntensity - moderateThreshold) / maxIntensity) * size.height;
    final redRect = Rect.fromLTWH(0, 0, size.width, redHeight);
    canvas.drawRect(
      redRect,
      Paint()..color = Color.fromARGB(40, 244, 67, 54),
    ); // Red with transparency

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final step = size.width / (values.length - 1);
    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = step * i;
      final y =
          size.height -
          (values[i] / (maxVal == 0 ? 1.0 : maxVal)) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    final pointPaint = Paint()..color = pointColor;
    for (int i = 0; i < values.length; i++) {
      final x = step * i;
      final y =
          size.height -
          (values[i] / (maxVal == 0 ? 1.0 : maxVal)) * size.height;
      canvas.drawCircle(Offset(x, y), 2.6, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
