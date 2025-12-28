import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Slow, elegant rotation
    )..repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) _initController();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Discrete Dynamic Glow
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller!,
              builder: (context, child) {
                return CustomPaint(
                  painter: _DiscreteGlowPainter(
                    animationValue: _controller!.value,
                  ),
                );
              },
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.vibration_rounded,
                  size: 64,
                  color: Colors.grey.shade400, // Softer grey for discretion
                ),
                const SizedBox(height: 24),
                const Text(
                  "Shake to discover",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54, // Softer black
                    letterSpacing: -0.5,
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

class _DiscreteGlowPainter extends CustomPainter {
  final double animationValue;

  _DiscreteGlowPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Apple Intelligence Colors - Pastel & Soft
    final colors = [
      const Color(0xFF40C8E0).withOpacity(0.3), // Cyan
      const Color(0xFF6439FF).withOpacity(0.3), // Deep Blue/Purple
      const Color(0xFFA839FF).withOpacity(0.3), // Purple
      const Color(0xFFFF39A0).withOpacity(0.3), // Pink
      const Color(0xFFFF8539).withOpacity(0.3), // Orange
      const Color(0xFF40C8E0).withOpacity(0.3), // Cyan loop
    ];

    // Rotating Gradient
    final gradient = SweepGradient(
      center: Alignment.center,
      colors: colors,
      stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
      transform: GradientRotation(animationValue * 2 * pi),
    );

    // Subtle Breathing (very minimal)
    final breathe = sin(animationValue * 2 * pi) * 0.5 + 0.5; // 0 to 1

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30 + (breathe * 10) // 30-40px wide stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40); // High blur for softness

    // Draw strictly along the edge (centered on the boundary)
    // This allows the blur to bleed inward softly while the main stroke is half-offscreen
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _DiscreteGlowPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
