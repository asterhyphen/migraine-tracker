import 'package:flutter/material.dart';

class NfcPulse extends StatelessWidget {
  const NfcPulse({required this.controller, required this.color});

  final AnimationController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final t = controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              _ring(0.75 + t * 0.9, (1 - t) * 0.32),
              _ring(0.45 + t * 0.7, (1 - t) * 0.22),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.2),
                ),
                child: Icon(Icons.nfc, color: color),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _ring(double scale, double alpha) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: alpha.clamp(0.0, 1.0)),
            width: 2,
          ),
        ),
      ),
    );
  }
}
