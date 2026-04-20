import 'package:flutter/material.dart';

enum AppSnackBarTone { success, error, info }

class AppSnackBar {
  static void showSuccess(
    BuildContext context, {
    String? title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      tone: AppSnackBarTone.success,
      title: title ?? 'Saved',
      message: message,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context, {
    String? title,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      tone: AppSnackBarTone.error,
      title: title ?? 'Something went wrong',
      message: message,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context, {
    String? title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      tone: AppSnackBarTone.info,
      title: title ?? 'Notice',
      message: message,
      duration: duration,
    );
  }

  static void _show(
    BuildContext context, {
    required AppSnackBarTone tone,
    required String title,
    required String message,
    required Duration duration,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          duration: duration,
          content: _SnackBarCard(tone: tone, title: title, message: message),
        ),
      );
  }
}

class _SnackBarCard extends StatefulWidget {
  const _SnackBarCard({
    required this.tone,
    required this.title,
    required this.message,
  });

  final AppSnackBarTone tone;
  final String title;
  final String message;

  @override
  State<_SnackBarCard> createState() => _SnackBarCardState();
}

class _SnackBarCardState extends State<_SnackBarCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _lift;
  late final Animation<double> _scale;
  late final Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.72, curve: Curves.easeOutCubic),
    );
    _lift = Tween<double>(
      begin: 18,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _scale = Tween<double>(
      begin: 0.96,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _iconScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.82,
          end: 1.08,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.08,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = switch (widget.tone) {
      AppSnackBarTone.success => scheme.primary,
      AppSnackBarTone.error => scheme.error,
      AppSnackBarTone.info => scheme.tertiary,
    };
    final icon = switch (widget.tone) {
      AppSnackBarTone.success => Icons.check_circle_rounded,
      AppSnackBarTone.error => Icons.error_rounded,
      AppSnackBarTone.info => Icons.notifications_active_rounded,
    };
    final cardColor = Color.alphaBlend(
      accent.withValues(alpha: isDark ? 0.18 : 0.10),
      scheme.surface,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fade.value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, _lift.value),
            child: Transform.scale(
              scale: _scale.value,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.40 : 0.24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Transform.scale(
                scale: _iconScale.value,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.22 : 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.82),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
