import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:migraine_tracker/core/theme/app_theme.dart';
import 'package:migraine_tracker/core/widgets/wavy_surface.dart';
import 'package:migraine_tracker/features/tracker/models/migraine_entry.dart';
import '../_utils/stats_utils.dart';

class StatsLoadingView extends StatelessWidget {
  const StatsLoadingView({super.key});

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
  const StatsEmptyState({super.key});

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
  const StatsSkeletonBox({super.key, required this.height,
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
  const MonthFilterCard({super.key, required this.selectedMonth,
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
  const SelectedMonthEmptyState({super.key, required this.monthLabel});

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

class MonthlyProgressCard extends StatelessWidget {
  const MonthlyProgressCard({
    super.key,
    required this.comparison,
  });

  final MonthlyProgressComparison comparison;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconData = switch (comparison.status) {
      MonthlyProgressStatus.better => Icons.trending_down_rounded,
      MonthlyProgressStatus.worse => Icons.trending_up_rounded,
      MonthlyProgressStatus.steady => Icons.trending_flat_rounded,
      MonthlyProgressStatus.mixed => Icons.swap_horiz_rounded,
      MonthlyProgressStatus.insufficient => Icons.hourglass_top_rounded,
    };
    final color = switch (comparison.status) {
      MonthlyProgressStatus.better => scheme.primary,
      MonthlyProgressStatus.worse => scheme.error,
      MonthlyProgressStatus.steady => scheme.secondary,
      MonthlyProgressStatus.mixed => scheme.tertiary,
      MonthlyProgressStatus.insufficient =>
        scheme.onSurface.withValues(alpha: 0.55),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        color: scheme.surface.withValues(alpha: 0.74),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(iconData, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comparison.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      comparison.periodLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comparison.message,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurface.withValues(alpha: 0.72),
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

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key, required this.totalEntries,
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
  const SectionTitle({super.key, required this.title, required this.subtitle});

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
  const ChartCard({super.key, required this.title, required this.child});

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
  const InsightCard({super.key, required this.title,
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
  const ComparisonCard({super.key, required this.item});

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
  const BarChart({super.key, required this.data});

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

class CalendarStatPill extends StatelessWidget {
  const CalendarStatPill({super.key, required this.dotColor, required this.label});

  final Color dotColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dotColor,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class AppleCalendarCard extends StatelessWidget {
  const AppleCalendarCard({super.key, required this.month,
    required this.entries,
    this.onDayTap,
  });

  final DateTime month;
  final List<MigraineEntry> entries;
  final void Function(DateTime date, MigraineEntry? entry)? onDayTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final calendarDays = buildCalendarMonthDays(
      month: month,
      entries: entries,
    );

    final migraineDaysCount =
        calendarDays.where((d) => d.isCurrentMonth && d.hasMigraine).length;
    final totalDaysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final painFreeDaysCount = totalDaysInMonth - migraineDaysCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.13)),
        color: scheme.surface.withValues(alpha: 0.74),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primary.withValues(alpha: 0.14),
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      size: 18,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "${monthLabel(month)} ${month.year}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF453A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFF453A).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFF453A),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      "Migraine",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF453A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            thickness: 0.5,
            color: scheme.onSurface.withValues(alpha: 0.10),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: calendarDays.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 4,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              final dayInfo = calendarDays[index];
              final isCurrent = dayInfo.isCurrentMonth;
              final isToday = dayInfo.isToday;
              final hasMigraine = dayInfo.hasMigraine;
              final entry = dayInfo.entry;

              final textColor = isCurrent
                  ? scheme.onSurface
                  : scheme.onSurface.withValues(alpha: 0.22);

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (onDayTap != null) {
                      onDayTap!(dayInfo.date, entry);
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: hasMigraine && isCurrent
                          ? const Color(0xFFFF453A).withValues(alpha: 0.10)
                          : isToday
                          ? scheme.primary.withValues(alpha: 0.08)
                          : Colors.transparent,
                      border: isToday
                          ? Border.all(
                              color: scheme.primary.withValues(alpha: 0.6),
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${dayInfo.date.day}",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isToday || (hasMigraine && isCurrent)
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (hasMigraine && isCurrent)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFF453A),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF453A,
                                  ).withValues(alpha: 0.45),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          )
                        else
                          const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CalendarStatPill(
                  dotColor: const Color(0xFFFF453A),
                  label:
                      "$migraineDaysCount ${migraineDaysCount == 1 ? 'Migraine Day' : 'Migraine Days'}",
                ),
                Container(
                  width: 1,
                  height: 16,
                  color: scheme.onSurface.withValues(alpha: 0.12),
                ),
                CalendarStatPill(
                  dotColor: const Color(0xFF34C759),
                  label: "$painFreeDaysCount Pain-Free",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CausesGraphCard extends StatelessWidget {
  const CausesGraphCard({super.key, required this.data,
    required this.totalEntries,
  });

  final List<CauseDatum> data;
  final int totalEntries;

  static const List<List<Color>> causeGradients = [
    [Color(0xFFFF5C5C), Color(0xFFFF7E7E)], // Coral Red
    [Color(0xFFFF9F43), Color(0xFFFFBE76)], // Amber Orange
    [Color(0xFF7E57C2), Color(0xFF9575CD)], // Purple Indigo
    [Color(0xFF00D2D3), Color(0xFF54ECEE)], // Teal Cyan
    [Color(0xFF10AC84), Color(0xFF1DD1A1)], // Emerald Green
    [Color(0xFFFF6B81), Color(0xFFFF9AA2)], // Rose Pink
    [Color(0xFF54A0FF), Color(0xFF74B9FF)], // Sky Blue
    [Color(0xFFFED330), Color(0xFFFFEAA7)], // Golden Yellow
  ];

  static IconData getCauseIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('stress') ||
        lower.contains('anxiety') ||
        lower.contains('tension')) {
      return Icons.psychology_rounded;
    }
    if (lower.contains('sleep') ||
        lower.contains('insomnia') ||
        lower.contains('tired')) {
      return Icons.bedtime_rounded;
    }
    if (lower.contains('coffee') ||
        lower.contains('caffeine') ||
        lower.contains('tea')) {
      return Icons.coffee_rounded;
    }
    if (lower.contains('screen') ||
        lower.contains('computer') ||
        lower.contains('phone')) {
      return Icons.devices_rounded;
    }
    if (lower.contains('food') ||
        lower.contains('sugar') ||
        lower.contains('meal') ||
        lower.contains('diet')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('water') ||
        lower.contains('dehydration') ||
        lower.contains('drink')) {
      return Icons.water_drop_rounded;
    }
    if (lower.contains('weather') ||
        lower.contains('pressure') ||
        lower.contains('heat') ||
        lower.contains('sun')) {
      return Icons.wb_sunny_rounded;
    }
    if (lower.contains('noise') || lower.contains('sound')) {
      return Icons.volume_up_rounded;
    }
    if (lower.contains('light') ||
        lower.contains('glare') ||
        lower.contains('bright')) {
      return Icons.lightbulb_rounded;
    }
    if (lower.contains('hormone') ||
        lower.contains('period') ||
        lower.contains('menstrual')) {
      return Icons.favorite_rounded;
    }
    return Icons.bubble_chart_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totalOccurrences = data.fold<int>(0, (sum, item) => sum + item.count);

    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.onSurface.withValues(alpha: 0.13)),
          color: scheme.surface.withValues(alpha: 0.74),
        ),
        child: Column(
          children: [
            Icon(
              Icons.bubble_chart_outlined,
              size: 36,
              color: scheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 8),
            const Text(
              "No triggers logged",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              "Tag causes when logging migraines to see your personalized triggers graph.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.65),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.13)),
        color: scheme.surface.withValues(alpha: 0.74),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.secondary.withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      Icons.bubble_chart_rounded,
                      size: 18,
                      color: scheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Causes & Triggers",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.22),
                  ),
                ),
                child: Text(
                  "${data.length} ${data.length == 1 ? 'trigger' : 'triggers'} ($totalOccurrences total)",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: List.generate(data.length, (index) {
                  final item = data[index];
                  final gradient =
                      causeGradients[index % causeGradients.length];
                  return Expanded(
                    flex: (item.percent * 1000).toInt().clamp(1, 1000),
                    child: Container(
                      margin: EdgeInsets.only(
                        right: index < data.length - 1 ? 2 : 0,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 18),
          ...List.generate(data.length, (index) {
            final item = data[index];
            final gradient =
                causeGradients[index % causeGradients.length];
            final icon = getCauseIcon(item.label);
            final percentStr = (item.percent * 100).toStringAsFixed(0);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        title: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: gradient),
                              ),
                              child: Icon(icon, size: 18, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(item.label)),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Logged in ${item.count} ${item.count == 1 ? 'migraine' : 'migraines'} this month.",
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Accounts for $percentStr% of all recorded triggers.",
                              style: TextStyle(
                                color: scheme.onSurface.withValues(alpha: 0.72),
                              ),
                            ),
                            if (item.avgIntensity > 0) ...[
                              const SizedBox(height: 8),
                              Text(
                                "Average pain intensity with this trigger: ${item.avgIntensity.toStringAsFixed(1)} / 10",
                                style: TextStyle(
                                  color: scheme.onSurface.withValues(alpha: 0.72),
                                ),
                              ),
                            ],
                          ],
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: scheme.onSurface.withValues(alpha: 0.03),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: gradient[0].withValues(alpha: 0.15),
                              ),
                              child: Icon(icon, size: 14, color: gradient[0]),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${item.count}x",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: scheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: gradient[0].withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "$percentStr%",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: gradient[0],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Stack(
                            children: [
                              Container(
                                height: 7,
                                color: scheme.faintTrack,
                              ),
                              FractionallySizedBox(
                                widthFactor: item.percent.clamp(0.02, 1.0),
                                child: Container(
                                  height: 7,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: gradient,
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class CauseList extends StatelessWidget {
  const CauseList({super.key, required this.data});

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
  const Gauge({super.key, required this.value});

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
  const LineChart({super.key, required this.values});

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

// ==========================================
// ADVANCED STATS SUITE WIDGETS
// ==========================================

class AdvancedStatsSection extends StatelessWidget {
  const AdvancedStatsSection({
    super.key,
    required this.entries,
    required this.allEntries,
    required this.selectedMonth,
  });

  final List<MigraineEntry> entries;
  final List<MigraineEntry> allEntries;
  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final correlations = calculateTriggerCorrelations(entries);
    final riskMultipliers = calculateTriggerRiskMultipliers(entries);
    final intervals = calculateCycleIntervalMetrics(allEntries);
    final weekdayDist = calculateWeekdayDistribution(entries);
    final severityDist = calculateSeverityDistribution(entries);
    final medRisk = calculateMedicationRisk(allEntries, selectedMonth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_graph_rounded, size: 16, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    "PRO ANALYTICS",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const SectionTitle(
          title: "Periodicity & Interval Regularity",
          subtitle: "Clinical cycle metrics and attack recurrence gaps",
        ),
        const SizedBox(height: 12),
        _PeriodicityCard(metrics: intervals),
        const SizedBox(height: 20),
        const SectionTitle(
          title: "Weekday Vulnerability Profile",
          subtitle: "Day-of-week recurrence and weekend let-down patterns",
        ),
        const SizedBox(height: 12),
        _WeekdayProfileCard(distribution: weekdayDist),
        const SizedBox(height: 20),
        const SectionTitle(
          title: "Trigger Impact & Correlations",
          subtitle: "Pairwise co-occurrences and pain intensity multipliers",
        ),
        const SizedBox(height: 12),
        _TriggerImpactCard(
          correlations: correlations,
          riskMultipliers: riskMultipliers,
        ),
        const SizedBox(height: 20),
        const SectionTitle(
          title: "Pain Severity & Volatility",
          subtitle: "Mild/Mod/Severe distribution and clinical pain stability",
        ),
        const SizedBox(height: 12),
        _SeverityVolatilityCard(distribution: severityDist),
        const SizedBox(height: 20),
        const SectionTitle(
          title: "Medication Overuse (MOH) Guard",
          subtitle: "Analgesic frequency monitoring against rebound risk thresholds",
        ),
        const SizedBox(height: 12),
        _MedicationOveruseCard(metrics: medRisk),
      ],
    );
  }
}

class _PeriodicityCard extends StatelessWidget {
  const _PeriodicityCard({required this.metrics});

  final CycleIntervalMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (metrics.intervalCount == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.onSurface.withValues(alpha: 0.12)),
          color: scheme.surface.withValues(alpha: 0.72),
        ),
        child: Row(
          children: [
            Icon(Icons.timeline_rounded, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Need at least 2 migraine entries across your history to calculate cycle periodicity and interval metrics.",
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.12)),
        color: scheme.surface.withValues(alpha: 0.76),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _IntervalMetricPill(
                label: "Mean Interval",
                value: "${metrics.meanIntervalDays.toStringAsFixed(1)}d",
              ),
              _IntervalMetricPill(
                label: "Median Gap",
                value: "${metrics.medianIntervalDays.toStringAsFixed(1)}d",
              ),
              _IntervalMetricPill(
                label: "Regularity",
                value: "${metrics.regularityScore.toInt()}%",
                badgeColor: metrics.regularityScore > 70
                    ? Colors.green
                    : (metrics.regularityScore > 40 ? Colors.orange : Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            "Recurrence Interval Breakdown",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 8),
          _IntervalDistributionBar(metrics: metrics),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Min gap: ${metrics.minIntervalDays}d",
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withValues(alpha: 0.60),
                ),
              ),
              Text(
                "Max pain-free gap: ${metrics.maxIntervalDays}d",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IntervalMetricPill extends StatelessWidget {
  const _IntervalMetricPill({required this.label,
    required this.value,
    this.badgeColor,});

  final String label;
  final String value;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: scheme.onSurface.withValues(alpha: 0.60),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: badgeColor ?? scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _IntervalDistributionBar extends StatelessWidget {
  const _IntervalDistributionBar({required this.metrics});

  final CycleIntervalMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final total = metrics.intervalCount;
    if (total == 0) return const SizedBox.shrink();

    final pUnder4 = metrics.intervalsUnder4Days / total;
    final p4to7 = metrics.intervals4to7Days / total;
    final p8to14 = metrics.intervals8to14Days / total;
    final p15plus = metrics.intervals15PlusDays / total;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                if (pUnder4 > 0)
                  Expanded(
                    flex: (pUnder4 * 100).toInt().clamp(1, 100),
                    child: Container(color: Colors.redAccent),
                  ),
                if (p4to7 > 0)
                  Expanded(
                    flex: (p4to7 * 100).toInt().clamp(1, 100),
                    child: Container(color: Colors.orangeAccent),
                  ),
                if (p8to14 > 0)
                  Expanded(
                    flex: (p8to14 * 100).toInt().clamp(1, 100),
                    child: Container(color: Colors.lightGreen),
                  ),
                if (p15plus > 0)
                  Expanded(
                    flex: (p15plus * 100).toInt().clamp(1, 100),
                    child: Container(color: Colors.green),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _IntervalLegendItem(
              label: "< 4d (${metrics.intervalsUnder4Days})",
              color: Colors.redAccent,
            ),
            _IntervalLegendItem(
              label: "4-7d (${metrics.intervals4to7Days})",
              color: Colors.orangeAccent,
            ),
            _IntervalLegendItem(
              label: "8-14d (${metrics.intervals8to14Days})",
              color: Colors.lightGreen,
            ),
            _IntervalLegendItem(
              label: "15+d (${metrics.intervals15PlusDays})",
              color: Colors.green,
            ),
          ],
        ),
      ],
    );
  }
}

class _IntervalLegendItem extends StatelessWidget {
  const _IntervalLegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _WeekdayProfileCard extends StatelessWidget {
  const _WeekdayProfileCard({required this.distribution});

  final WeekdayDistribution distribution;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = distribution.days.fold<int>(0, (sum, d) => sum + d.count);

    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.onSurface.withValues(alpha: 0.12)),
          color: scheme.surface.withValues(alpha: 0.72),
        ),
        child: Text(
          "No migraine logs in this period to construct weekday attack patterns.",
          style: TextStyle(
            fontSize: 13,
            color: scheme.onSurface.withValues(alpha: 0.72),
          ),
        ),
      );
    }

    final maxDayCount =
        distribution.days.map((d) => d.count).reduce(math.max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.12)),
        color: scheme.surface.withValues(alpha: 0.76),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_view_week_rounded,
                color: scheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  distribution.isWeekendPeak
                      ? "Weekend Vulnerability Alert (${distribution.peakDayName})"
                      : "Peak Attack Day: ${distribution.peakDayName} (${distribution.peakDayCount} attacks)",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: distribution.isWeekendPeak
                        ? Colors.orangeAccent
                        : scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: distribution.days.map((day) {
              final ratio = maxDayCount > 0 ? day.count / maxDayCount : 0.0;
              final isPeak = day.count == maxDayCount && day.count > 0;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${day.count}",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isPeak ? FontWeight.w800 : FontWeight.w500,
                      color: isPeak ? scheme.primary : scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 28,
                    height: (ratio * 70).clamp(6.0, 70.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: isPeak
                          ? LinearGradient(
                              colors: [scheme.primary, scheme.secondary],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            )
                          : LinearGradient(
                              colors: [
                                scheme.onSurface.withValues(alpha: 0.15),
                                scheme.onSurface.withValues(alpha: 0.28),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    day.shortName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isPeak ? FontWeight.w700 : FontWeight.w500,
                      color: isPeak ? scheme.primary : scheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TriggerImpactCard extends StatelessWidget {
  const _TriggerImpactCard({required this.correlations,
    required this.riskMultipliers,});

  final List<TriggerCorrelation> correlations;
  final List<TriggerRiskMultiplier> riskMultipliers;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (correlations.isEmpty && riskMultipliers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.onSurface.withValues(alpha: 0.12)),
          color: scheme.surface.withValues(alpha: 0.72),
        ),
        child: Text(
          "No multi-trigger logs recorded yet for correlation and impact analysis.",
          style: TextStyle(
            fontSize: 13,
            color: scheme.onSurface.withValues(alpha: 0.72),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.12)),
        color: scheme.surface.withValues(alpha: 0.76),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (riskMultipliers.isNotEmpty) ...[
            Text(
              "Intensity Impact (Delta when Trigger Present)",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withValues(alpha: 0.90),
              ),
            ),
            const SizedBox(height: 10),
            ...riskMultipliers.take(3).map((item) {
              final isPositive = item.intensityDelta >= 0;
              final sign = isPositive ? "+" : "";
              final deltaStr = "$sign${item.intensityDelta.toStringAsFixed(1)} pts";
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.cause,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      "avg ${item.avgIntensityWith.toStringAsFixed(1)}/10",
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withValues(alpha: 0.60),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isPositive
                            ? Colors.red.withValues(alpha: 0.15)
                            : Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        deltaStr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isPositive ? Colors.redAccent : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (correlations.isNotEmpty) ...[
            if (riskMultipliers.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 12),
            ],
            Text(
              "Top Trigger Co-occurrences",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withValues(alpha: 0.90),
              ),
            ),
            const SizedBox(height: 10),
            ...correlations.take(3).map((corr) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.link_rounded,
                      size: 16,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${corr.causeA} + ${corr.causeB}",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      "${corr.coOccurrences}x (${corr.correlationPercent.toInt()}%)",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _SeverityVolatilityCard extends StatelessWidget {
  const _SeverityVolatilityCard({required this.distribution});

  final SeverityDistribution distribution;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (distribution.totalCount == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.onSurface.withValues(alpha: 0.12)),
          color: scheme.surface.withValues(alpha: 0.72),
        ),
        child: Text(
          "No migraine logs in this period to measure severity brackets.",
          style: TextStyle(
            fontSize: 13,
            color: scheme.onSurface.withValues(alpha: 0.72),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.12)),
        color: scheme.surface.withValues(alpha: 0.76),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Pain Stability Index",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.85),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "σ = ${distribution.standardDeviation.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  if (distribution.mildPercent > 0)
                    Expanded(
                      flex: distribution.mildPercent.toInt().clamp(1, 100),
                      child: Container(color: Colors.green),
                    ),
                  if (distribution.moderatePercent > 0)
                    Expanded(
                      flex: distribution.moderatePercent.toInt().clamp(1, 100),
                      child: Container(color: Colors.amber),
                    ),
                  if (distribution.severePercent > 0)
                    Expanded(
                      flex: distribution.severePercent.toInt().clamp(1, 100),
                      child: Container(color: Colors.redAccent),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SeverityLegendPill(
                label: "Mild (1-3)",
                count: distribution.mildCount,
                percent: distribution.mildPercent,
                color: Colors.green,
              ),
              _SeverityLegendPill(
                label: "Moderate (4-6)",
                count: distribution.moderateCount,
                percent: distribution.moderatePercent,
                color: Colors.amber,
              ),
              _SeverityLegendPill(
                label: "Severe (7-10)",
                count: distribution.severeCount,
                percent: distribution.severePercent,
                color: Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeverityLegendPill extends StatelessWidget {
  const _SeverityLegendPill({required this.label,
    required this.count,
    required this.percent,
    required this.color,});

  final String label;
  final int count;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          "$count (${percent.toInt()}%)",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MedicationOveruseCard extends StatelessWidget {
  const _MedicationOveruseCard({required this.metrics});

  final MedicationRiskMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (metrics.riskLevel) {
      case MedicationOveruseLevel.high:
        badgeColor = Colors.redAccent;
        badgeText = "HIGH RISK";
        badgeIcon = Icons.warning_amber_rounded;
        break;
      case MedicationOveruseLevel.caution:
        badgeColor = Colors.orangeAccent;
        badgeText = "CAUTION";
        badgeIcon = Icons.info_outline_rounded;
        break;
      case MedicationOveruseLevel.low:
        badgeColor = Colors.green;
        badgeText = "SAFE";
        badgeIcon = Icons.check_circle_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
        color: scheme.surface.withValues(alpha: 0.76),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.medication_outlined, color: badgeColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "${metrics.medicationDaysThisMonth} medication days this month",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 12, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            metrics.riskMessage,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: scheme.onSurface.withValues(alpha: 0.76),
            ),
          ),
          if (metrics.consecutiveDaysMax > 1) ...[
            const SizedBox(height: 8),
            Text(
              "Max consecutive analgesic days: ${metrics.consecutiveDaysMax} days",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.60),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
