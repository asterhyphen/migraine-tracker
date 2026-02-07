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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final monthStats = _buildMonthlyStats();
    final avgStats = _buildMonthlyAverages();
    final causes = _buildCauseStats();
    final painkillerPercent = _painkillerUsage();
    final intensitySeries = _entries.take(6).map((e) => e.intensity).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Migraine Stats"),
        actions: const [
          IconButton(
            onPressed: null,
            icon: Icon(Icons.menu),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
          .where((e) => e.date.year == month.year && e.date.month == month.month)
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
          .where((e) => e.date.year == month.year && e.date.month == month.month)
          .toList();
      final avg = monthEntries.isEmpty
          ? 0.0
          : monthEntries
                  .map((e) => e.intensity)
                  .reduce((a, b) => a + b) /
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
    return sorted
        .map((e) => _CauseDatum(e.key, e.value, total))
        .toList();
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
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SizedBox(height: 140, child: child),
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
                  backgroundColor: Colors.white10,
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
            backgroundColor: Colors.white10,
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
          size.height - (values[i] / (maxVal == 0 ? 1.0 : maxVal)) * size.height;
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
