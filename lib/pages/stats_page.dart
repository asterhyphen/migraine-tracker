import 'package:flutter/material.dart';

import '../data/migraine_db.dart';
import '../data/migraine_entry.dart';
import '../utils/date_utils.dart';
import '../widgets/wavy_surface.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  bool _loading = true;
  List<MigraineEntry> _entries = [];
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<DateTime> _monthOptions = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final entries = await MigraineDb.instance.getMigraineEntriesOnly();
    final monthOptions = _buildMonthOptions(entries);
    final hasSelected = monthOptions.any(
      (m) => m.year == _selectedMonth.year && m.month == _selectedMonth.month,
    );
    setState(() {
      _entries = entries;
      _monthOptions = monthOptions;
      if (!hasSelected) {
        _selectedMonth = monthOptions.first;
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _StatsLoadingView();
    }

    final filtered = _entries.where((e) {
      return e.date.year == _selectedMonth.year &&
          e.date.month == _selectedMonth.month;
    }).toList();
    final monthStats = _buildWeeklyFrequency(filtered, _selectedMonth);
    final avgStats = _buildWeeklyAverages(filtered, _selectedMonth);
    final causes = _buildCauseStats(filtered);
    final painkillerPercent = _painkillerUsage(filtered);
    final intensitySeries =
        filtered.reversed.map((e) => e.intensity).toList().take(14).toList();
    final summary = _buildSummary(filtered);
    final recent = filtered.take(8).toList();
    final weekly = _buildWeeklyCounts(filtered, _selectedMonth);
    final overallAvg = _entries.isEmpty
        ? 0.0
        : _entries.map((e) => e.intensity).reduce((a, b) => a + b) /
            _entries.length;
    final selectedAvg = filtered.isEmpty
        ? 0.0
        : filtered.map((e) => e.intensity).reduce((a, b) => a + b) /
            filtered.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistics"),
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: _entries.isEmpty
              ? const _StatsEmptyState()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MonthFilterCard(
                      selectedMonth: _selectedMonth,
                      options: _monthOptions,
                      onChanged: (month) {
                        setState(() {
                          _selectedMonth = month;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _DashboardHeader(
                      totalEntries: filtered.length,
                      monthLabel: _monthLabelFull(_selectedMonth),
                    ),
                    const SizedBox(height: 24),
                    if (filtered.isEmpty) ...[
                      _SelectedMonthEmptyState(
                        monthLabel: _monthLabelFull(_selectedMonth),
                      ),
                      const SizedBox(height: 20),
                    ],
                    const _SectionTitle(
                      title: "Summary",
                      subtitle: "High-level indicators for selected month",
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
                            title: "Weekly Frequency",
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
                            title: "Weekly Avg. Intensity",
                            child: _BarChart(data: avgStats),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ChartCard(
                      title: "Intensity Graph",
                      child: Column(
                        children: [
                          Expanded(child: _LineChart(values: intensitySeries)),
                          const SizedBox(height: 8),
                          Text(
                            "Overall avg ${overallAvg.toStringAsFixed(1)} • ${_monthLabel(_selectedMonth)} avg ${selectedAvg.toStringAsFixed(1)}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle(
                      title: "Weekly Pulse",
                      subtitle: "Daily migraine counts for final week of selected month",
                    ),
                    const SizedBox(height: 12),
                    _WeeklyGraph(data: weekly),    
                  ],
                ),
        ),
      ),
    );
  }

  List<_BarDatum> _buildWeeklyFrequency(
    List<MigraineEntry> source,
    DateTime month,
  ) {
    final counts = List<int>.filled(5, 0);
    for (final entry in source) {
      if (entry.date.year != month.year || entry.date.month != month.month) {
        continue;
      }
      final bucket = ((entry.date.day - 1) / 7).floor().clamp(0, 4);
      counts[bucket] += 1;
    }
    return List<_BarDatum>.generate(
      5,
      (i) => _BarDatum("W${i + 1}", counts[i].toDouble()),
    );
  }

  List<_BarDatum> _buildWeeklyAverages(
    List<MigraineEntry> source,
    DateTime month,
  ) {
    final buckets = List<List<int>>.generate(5, (_) => []);
    for (final entry in source) {
      if (entry.date.year != month.year || entry.date.month != month.month) {
        continue;
      }
      final bucket = ((entry.date.day - 1) / 7).floor().clamp(0, 4);
      buckets[bucket].add(entry.intensity);
    }
    return List<_BarDatum>.generate(5, (i) {
      final values = buckets[i];
      if (values.isEmpty) return _BarDatum("W${i + 1}", 0);
      final avg = values.reduce((a, b) => a + b) / values.length;
      return _BarDatum("W${i + 1}", avg);
    });
  }

  List<DateTime> _buildMonthOptions(List<MigraineEntry> entries) {
    final set = <String, DateTime>{};
    final now = DateTime.now();
    set["${now.year}-${now.month}"] = DateTime(now.year, now.month);
    for (final e in entries) {
      final month = DateTime(e.date.year, e.date.month);
      set["${month.year}-${month.month}"] = month;
    }
    final months = set.values.toList()
      ..sort((a, b) => b.compareTo(a));
    return months;
  }

  List<_CauseDatum> _buildCauseStats(List<MigraineEntry> source) {
    final Map<String, int> counts = {};
    for (final entry in source) {
      for (final cause in entry.causes) {
        counts[cause] = (counts[cause] ?? 0) + 1;
      }
    }
    final total = counts.values.fold<int>(0, (sum, v) => sum + v);
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => _CauseDatum(e.key, e.value, total)).toList();
  }

  double _painkillerUsage(List<MigraineEntry> source) {
    if (source.isEmpty) return 0;
    final used = source.where((e) => e.painkillers).length;
    return used / source.length;
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

  String _monthLabelFull(DateTime month) {
    return "${_monthLabel(month)} ${month.year}";
  }

  List<_SummaryItem> _buildSummary(List<MigraineEntry> source) {
    if (source.isEmpty) {
      return [
        _SummaryItem("Total Entries", "0", "No logs in selected month"),
        _SummaryItem("Avg. Intensity", "-", "No data yet"),
        _SummaryItem("Highest Pain Day", "-", "No data yet"),
        _SummaryItem("Top Cause", "-", "No data yet"),
        _SummaryItem("Painkiller Rate", "0%", "For selected month"),
      ];
    }

    final total = source.length;
    final avgIntensity =
        source.map((e) => e.intensity).reduce((a, b) => a + b) / total;
    final maxIntensity =
        source.map((e) => e.intensity).reduce((a, b) => a > b ? a : b);
    final minIntensity =
        source.map((e) => e.intensity).reduce((a, b) => a < b ? a : b);

    final causeCounts = <String, int>{};
    for (final entry in source) {
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

    final painkillerRate = (_painkillerUsage(source) * 100).round();
    final highestPainEntry = source.reduce((a, b) {
      if (a.intensity == b.intensity) {
        return a.date.isAfter(b.date) ? a : b;
      }
      return a.intensity > b.intensity ? a : b;
    });

    return [
      _SummaryItem("Total Entries", "$total", "Max $maxIntensity • Min $minIntensity"),
      _SummaryItem(
        "Avg. Intensity",
        avgIntensity.toStringAsFixed(1),
        "For selected month",
      ),
      _SummaryItem(
        "Highest Pain Day",
        formatDdMmYyyy(highestPainEntry.date),
        "Intensity ${highestPainEntry.intensity}/10",
      ),
      _SummaryItem("Top Cause", topCause, "Most frequent trigger"),
      _SummaryItem("Painkiller Rate", "$painkillerRate%", "For selected month"),
    ];
  }

  List<_WeeklyDatum> _buildWeeklyCounts(
    List<MigraineEntry> source,
    DateTime month,
  ) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final start = daysInMonth > 7 ? daysInMonth - 6 : 1;
    final List<_WeeklyDatum> data = [];
    for (int dayNum = start; dayNum <= daysInMonth; dayNum++) {
      final day = DateTime(month.year, month.month, dayNum);
      final count = source.where((e) {
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

class _StatsLoadingView extends StatelessWidget {
  const _StatsLoadingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Statistics")),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: const [
          _StatsSkeletonBox(height: 80, radius: 18),
          SizedBox(height: 24),
          _StatsSkeletonBox(height: 18, width: 120),
          SizedBox(height: 12),
          _StatsSkeletonBox(height: 200, radius: 14),
          SizedBox(height: 16),
          _StatsSkeletonBox(height: 170, radius: 14),
        ],
      ),
    );
  }
}

class _StatsEmptyState extends StatelessWidget {
  const _StatsEmptyState();

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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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

class _StatsSkeletonBox extends StatelessWidget {
  const _StatsSkeletonBox({
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

class _MonthFilterCard extends StatelessWidget {
  const _MonthFilterCard({
    required this.selectedMonth,
    required this.options,
    required this.onChanged,
  });

  final DateTime selectedMonth;
  final List<DateTime> options;
  final ValueChanged<DateTime> onChanged;

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
      child: DropdownButtonFormField<DateTime>(
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
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class _SelectedMonthEmptyState extends StatelessWidget {
  const _SelectedMonthEmptyState({required this.monthLabel});

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

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.totalEntries,
    required this.monthLabel,
  });

  final int totalEntries;
  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return WavySurface(
      borderRadius: BorderRadius.circular(18),
      borderColor: scheme.primary.withValues(alpha: 0.20),
      gradient: LinearGradient(
        colors: [
          scheme.surface,
          scheme.tertiary.withValues(alpha: 0.14),
        ],
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
                    "$totalEntries logged migraines • $monthLabel",
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
              Container(
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      scheme.primary.withValues(alpha: 0.85),
                      scheme.tertiary.withValues(alpha: 0.75),
                    ],
                  ),
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
      children: data.take(3).map((item) {
        return Padding(
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
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _LinePainter(
        values: values,
        lineColor: scheme.primary,
        pointColor: scheme.secondary,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
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
          size.height - (values[i] / (maxVal == 0 ? 1.0 : maxVal)) * size.height;
      canvas.drawCircle(Offset(x, y), 2.6, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _WeeklyDatum {
  _WeeklyDatum(this.label, this.count);

  final String label;
  final int count;
}

class _WeeklyGraph extends StatelessWidget {
  const _WeeklyGraph({required this.data});

  final List<_WeeklyDatum> data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.13)),
        color: scheme.surface.withValues(alpha: 0.74),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 130,
            child: CustomPaint(
              painter: _WeeklyGraphPainter(
                data: data,
                color: scheme.primary,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: data
                .map(
                  (d) => Expanded(
                    child: Text(
                      d.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _WeeklyGraphPainter extends CustomPainter {
  _WeeklyGraphPainter({
    required this.data,
    required this.color,
  });

  final List<_WeeklyDatum> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final maxCount =
        data.map((d) => d.count).reduce((a, b) => a > b ? a : b).toDouble();
    final normalizedMax = maxCount == 0 ? 1.0 : maxCount;

    final axisPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      axisPaint,
    );

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;

    final stepX = size.width / (data.length - 1);
    final linePath = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height -
          ((data[i].count / normalizedMax) * (size.height - 12)) -
          6;
      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);

    final pointPaint = Paint()..color = color;
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height -
          ((data[i].count / normalizedMax) * (size.height - 12)) -
          6;
      canvas.drawCircle(Offset(x, y), 3.2, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyGraphPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}

