import 'package:flutter/material.dart';

import '../data/migraine_db.dart';
import '../data/migraine_entry.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  bool _loading = true;
  List<MigraineEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final entries = await MigraineDb.instance.getMigraineEntriesOnly();
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final monthStats = _buildMonthlyStats();
    final avgStats = _buildMonthlyAverages();
    final causes = _buildCauseStats();
    final painkillerPercent = _painkillerUsage();
    final intensitySeries = _entries.take(6).map((e) => e.intensity).toList();
    final summary = _buildSummary();
    final recent = _entries.take(6).toList();
    final weekly = _buildWeeklyCounts();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistics"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DashboardHeader(totalEntries: _entries.length),
            const SizedBox(height: 24),
            const _SectionTitle(
              title: "Summary",
              subtitle: "High-level indicators across all logs",
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: summary.map((item) {
                return _InsightCard(
                  title: item.title,
                  value: item.value,
                  subtitle: item.subtitle,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const _SectionTitle(
              title: "Trends",
              subtitle: "Patterns across month, causes, and intensity",
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ChartCard(
                    title: "Monthly Frequency",
                    child: _BarChart(data: monthStats),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ChartCard(
                    title: "Causes",
                    child: _CauseList(data: causes),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ChartCard(
                    title: "Painkiller Usage",
                    child: _Gauge(value: painkillerPercent),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ChartCard(
                    title: "Avg. Intensity",
                    child: _BarChart(data: avgStats),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ChartCard(
              title: "Recent Intensity",
              child: _LineChart(values: intensitySeries),
            ),
            const SizedBox(height: 20),
            const _SectionTitle(
              title: "Weekly Pulse",
              subtitle: "Daily migraine counts over the last 7 days",
            ),
            const SizedBox(height: 12),
            _WeeklyRow(data: weekly),
            const SizedBox(height: 20),
            const _SectionTitle(
              title: "Recent Logs",
              subtitle: "Latest entries for quick review",
            ),
            const SizedBox(height: 12),
            _RecentList(entries: recent),
          ],
        ),
      ),
    );
  }

  List<_BarDatum> _buildMonthlyStats() {
    final now = DateTime.now();
    final List<_BarDatum> data = [];
    for (int i = 3; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final count = _entries
          .where(
            (e) => e.date.year == month.year && e.date.month == month.month,
          )
          .length;
      data.add(_BarDatum(_monthLabel(month), count.toDouble()));
    }
    return data;
  }

  List<_BarDatum> _buildMonthlyAverages() {
    final now = DateTime.now();
    final List<_BarDatum> data = [];
    for (int i = 3; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final monthEntries = _entries
          .where(
            (e) => e.date.year == month.year && e.date.month == month.month,
          )
          .toList();
      final avg = monthEntries.isEmpty
          ? 0.0
          : monthEntries.map((e) => e.intensity).reduce((a, b) => a + b) /
                monthEntries.length;
      data.add(_BarDatum(_monthLabel(month), avg));
    }
    return data;
  }

  List<_CauseDatum> _buildCauseStats() {
    final Map<String, int> counts = {};
    for (final entry in _entries) {
      for (final cause in entry.causes) {
        counts[cause] = (counts[cause] ?? 0) + 1;
      }
    }
    final total = counts.values.fold<int>(0, (sum, v) => sum + v);
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => _CauseDatum(e.key, e.value, total)).toList();
  }

  double _painkillerUsage() {
    if (_entries.isEmpty) return 0;
    final used = _entries.where((e) => e.painkillers).length;
    return used / _entries.length;
  }

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
    return labels[month.month - 1];
  }

  List<_SummaryItem> _buildSummary() {
    if (_entries.isEmpty) {
      return [
        _SummaryItem("Total Entries", "0", "Log your first migraine"),
        _SummaryItem("Avg. Intensity", "-", "No data yet"),
        _SummaryItem("Top Cause", "-", "No data yet"),
        _SummaryItem("Painkiller Rate", "0%", "Across all logs"),
      ];
    }

    final total = _entries.length;
    final avgIntensity =
        _entries.map((e) => e.intensity).reduce((a, b) => a + b) / total;
    final maxIntensity =
        _entries.map((e) => e.intensity).reduce((a, b) => a > b ? a : b);
    final minIntensity =
        _entries.map((e) => e.intensity).reduce((a, b) => a < b ? a : b);

    final causeCounts = <String, int>{};
    for (final entry in _entries) {
      for (final cause in entry.causes) {
        causeCounts[cause] = (causeCounts[cause] ?? 0) + 1;
      }
    }
    String topCause = "No cause tagged";
    if (causeCounts.isNotEmpty) {
      final sorted = causeCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topCause = sorted.first.key;
    }

    final painkillerRate = (_painkillerUsage() * 100).round();

    return [
      _SummaryItem("Total Entries", "$total", "Max $maxIntensity • Min $minIntensity"),
      _SummaryItem(
        "Avg. Intensity",
        avgIntensity.toStringAsFixed(1),
        "Across all logs",
      ),
      _SummaryItem("Top Cause", topCause, "Most frequent trigger"),
      _SummaryItem("Painkiller Rate", "$painkillerRate%", "Across all logs"),
    ];
  }

  List<_WeeklyDatum> _buildWeeklyCounts() {
    final now = DateTime.now();
    final List<_WeeklyDatum> data = [];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final count = _entries.where((e) {
        return e.date.year == day.year &&
            e.date.month == day.month &&
            e.date.day == day.day;
      }).length;
      data.add(_WeeklyDatum(_weekdayLabel(day), count));
    }
    return data;
  }

  String _weekdayLabel(DateTime date) {
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return labels[date.weekday % 7];
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.totalEntries});

  final int totalEntries;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.20)),
        gradient: LinearGradient(
          colors: [
            scheme.surface,
            scheme.tertiary.withValues(alpha: 0.14),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
        ),
      ),
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
                  "$totalEntries total logged migraines",
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
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
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

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

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

class _SummaryItem {
  _SummaryItem(this.title, this.value, this.subtitle);

  final String title;
  final String value;
  final String subtitle;
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 170,
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
            title,
            style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
    );
  }
}

class _BarDatum {
  _BarDatum(this.label, this.value);

  final String label;
  final double value;
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.data});

  final List<_BarDatum> data;

  @override
  Widget build(BuildContext context) {
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
              Container(
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(4),
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

class _CauseDatum {
  _CauseDatum(this.label, this.count, this.total);

  final String label;
  final int count;
  final int total;

  double get percent => total == 0 ? 0 : count / total;
}

class _CauseList extends StatelessWidget {
  const _CauseList({required this.data});

  final List<_CauseDatum> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text("No causes logged"));
    }
    return Column(
      children: data.take(4).map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(child: Text(item.label)),
              SizedBox(
                width: 60,
                child: LinearProgressIndicator(
                  value: item.percent,
                  minHeight: 6,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _Gauge extends StatelessWidget {
  const _Gauge({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    return Center(
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
            backgroundColor: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.12),
          ),
        ],
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  const _LineChart({required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const Center(child: Text("No entries yet"));
    }
    return CustomPaint(
      painter: _LinePainter(values: values),
      child: const SizedBox.expand(),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({required this.values});

  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxVal = values.reduce((a, b) => a > b ? a : b).toDouble();
    final paint = Paint()
      ..color = Colors.white70
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _WeeklyDatum {
  _WeeklyDatum(this.label, this.count);

  final String label;
  final int count;
}

class _WeeklyRow extends StatelessWidget {
  const _WeeklyRow({required this.data});

  final List<_WeeklyDatum> data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: data.map((datum) {
        final height = (datum.count * 12).clamp(6, 60).toDouble();
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                datum.label,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({required this.entries});

  final List<MigraineEntry> entries;

  String _formatDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return "$dd-$mm-${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Text("No entries yet.");
    }
    return Column(
      children: entries.map((entry) {
        final causes = entry.causes.isEmpty
            ? "No causes tagged"
            : entry.causes.join(" • ");
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.13),
            ),
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.18),
                ),
                child: Center(
                  child: Text(
                    entry.intensity.toString(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(entry.date),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      causes,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
