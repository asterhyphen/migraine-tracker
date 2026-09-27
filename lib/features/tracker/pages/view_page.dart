import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'package:migraine_tracker/features/tracker/models/migraine_entry.dart';
import 'package:migraine_tracker/features/tracker/providers/entries_provider.dart';
import 'package:migraine_tracker/core/utils/date_utils.dart';
import 'package:migraine_tracker/core/widgets/app_snackbar.dart';
import 'package:migraine_tracker/core/theme/app_theme.dart';
import '_utils/view_utils.dart' as view_utils;
import '_widgets/view_widgets.dart';
import 'log_page.dart';

Route<void> viewMigraineRoute({required MigraineEntry entry}) {
  return PageRouteBuilder<void>(
    pageBuilder: (context, animation, secondaryAnimation) {
      return ViewMigrainePage(entry: entry);
    },
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) {
        return child;
      }

      final slide = Tween<Offset>(
        begin: const Offset(0.06, 0.04),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
      );
      final scale = Tween<double>(begin: 0.982, end: 1).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
      );
      final fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0, 0.78, curve: Curves.easeOut),
          reverseCurve: const Interval(0.12, 1, curve: Curves.easeIn),
        ),
      );

      return FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: slide,
          child: ScaleTransition(
            scale: scale,
            alignment: Alignment.topCenter,
            child: child,
          ),
        ),
      );
    },
  );
}

class ViewMigrainePage extends ConsumerWidget {
  const ViewMigrainePage({super.key, required this.entry});

  final MigraineEntry entry;

  Future<void> _deleteEntry(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete entry?"),
          content: const Text("Are you sure? This action is irreversible."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await ref.read(migraineEntriesProvider.notifier).deleteEntry(entry.id!);
    if (!context.mounted) return;
    HapticFeedback.mediumImpact();
    AppSnackBar.showSuccess(
      context,
      title: 'Entry deleted',
      message: 'The migraine log was removed.',
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final entriesState = ref.watch(migraineEntriesProvider);
    final comparisonStats = entriesState.maybeWhen(
      data: (allEntries) => view_utils.buildComparisonStats(entry, allEntries),
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("View Migraine"),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => LogMigrainePage(entry: entry),
                ),
              );
              if (!context.mounted) return;
              if (result == true) {
                await ref.read(migraineEntriesProvider.notifier).reload();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            icon: const Icon(Icons.edit_outlined),
            tooltip: "Edit",
          ),
          IconButton(
            onPressed: () => _deleteEntry(context, ref),
            icon: const Icon(Icons.delete_outline),
            tooltip: "Delete",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Section
            Container(
              width: double.infinity,
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
                    "Date",
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${formatDdMmYyyy(entry.date)} (${formatDay(entry.date)})",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Intensity Section
            Container(
              width: double.infinity,
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
                    "Intensity",
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        "${entry.intensity}/10",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: entry.intensity / 10,
                            minHeight: 8,
                            backgroundColor: scheme.faintTrack,
                            valueColor: AlwaysStoppedAnimation(
                              view_utils.getIntensityColor(entry.intensity, scheme),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (comparisonStats != null) ...[
              ComparisonStatsCard(stats: comparisonStats),
              const SizedBox(height: 16),
            ],

            // Painkillers Section
            Container(
              width: double.infinity,
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
                    "Painkillers",
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Chip(
                    label: Text(entry.painkillers ? "Yes" : "No"),
                    backgroundColor: entry.painkillers
                        ? scheme.primary.withValues(alpha: 0.2)
                        : scheme.errorContainer,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Causes Section
            if (entry.causes.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
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
                          "Probable Causes",
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: entry.causes
                              .map(
                                (cause) => Chip(
                                  label: Text(cause),
                                  backgroundColor: scheme.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Notes Section
            if (entry.notes.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
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
                          "Notes",
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(entry.notes),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Edit Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => LogMigrainePage(entry: entry),
                    ),
                  );
                  if (!context.mounted) return;
                  if (result == true) {
                    await ref.read(migraineEntriesProvider.notifier).reload();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
                icon: const Icon(Icons.edit),
                label: const Text("Edit Entry"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
