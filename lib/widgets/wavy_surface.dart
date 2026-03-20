import 'dart:math' as math;

import 'package:flutter/material.dart';

class WavySurface extends StatefulWidget {
  const WavySurface({
    super.key,
    required this.child,
    required this.borderRadius,
    required this.gradient,
    required this.borderColor,
    required this.waveColorA,
    required this.waveColorB,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final Gradient gradient;
  final Color borderColor;
  final Color waveColorA;
  final Color waveColorB;

  @override
  State<WavySurface> createState() => _WavySurfaceState();
}

class _WavySurfaceState extends State<WavySurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        border: Border.all(color: widget.borderColor),
        gradient: widget.gradient,
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _WavyPainter(
                      t: _controller.value,
                      colorA: widget.waveColorA,
                      colorB: widget.waveColorB,
                    ),
                  );
                },
              ),
            ),
            widget.child,
          ],
        ),
      ),
    );
  }
}

class _WavyPainter extends CustomPainter {
  const _WavyPainter({
    required this.t,
    required this.colorA,
    required this.colorB,
  });

  final double t;
  final Color colorA;
  final Color colorB;

  @override
  void paint(Canvas canvas, Size size) {
    _drawWave(
      canvas: canvas,
      size: size,
      baseYFactor: 0.74,
      amp: 12,
      freq: 1.7,
      phase: t * math.pi * 2,
      color: colorA,
    );
    _drawWave(
      canvas: canvas,
      size: size,
      baseYFactor: 0.82,
      amp: 16,
      freq: 1.25,
      phase: -t * math.pi * 2 * 1.1,
      color: colorB,
    );
  }

  void _drawWave({
    required Canvas canvas,
    required Size size,
    required double baseYFactor,
    required double amp,
    required double freq,
    required double phase,
    required Color color,
  }) {
    final path = Path();
    final baseY = size.height * baseYFactor;
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      final y =
          baseY + math.sin((x / size.width) * freq * math.pi * 2 + phase) * amp;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavyPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.colorA != colorA ||
        oldDelegate.colorB != colorB;
  }
}
