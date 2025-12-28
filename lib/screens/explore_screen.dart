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
      duration: const Duration(seconds: 4),
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
          // Glowing Border
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller!,
              builder: (context, child) {
                return CustomPaint(
                  painter: _GlowingBorderPainter(
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
                  color: Colors.grey.shade600,
                ),
                const SizedBox(height: 24),
                const Text(
                  "Shake to discover",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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

class _GlowingBorderPainter extends CustomPainter {
  final double animationValue;

  _GlowingBorderPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Apple Intelligence Colors
    final colors = [
      const Color(0xFF40C8E0), // Cyan
      const Color(0xFF6439FF), // Deep Blue/Purple
      const Color(0xFFA839FF), // Purple
      const Color(0xFFFF39A0), // Pink
      const Color(0xFFFF8539), // Orange
      const Color(0xFF40C8E0), // Cyan loop
    ];

    // Rotating Gradient
    final gradient = SweepGradient(
      center: Alignment.center,
      colors: colors,
      stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
      transform: GradientRotation(animationValue * 2 * pi),
    );

    // Breathing effect (pulsing opacity/width)
    final breathe = sin(animationValue * 4 * pi); // -1 to 1

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(rect);

    // Layer 1: Ambient Atmosphere (Wide, Soft, Diffuse)
    // Acts as the backlight
    paint
      ..strokeWidth = 80 + (breathe * 5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

    canvas.saveLayer(rect, Paint()..color = Colors.white.withOpacity(0.4));
    canvas.drawRect(rect, paint);
    canvas.restore();

    // Layer 2: Defined Glow (Closer to edge, slightly sharper)
    // Gives the structure without a hard line
    paint
      ..strokeWidth = 30 + (breathe * 2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.saveLayer(rect, Paint()..color = Colors.white.withOpacity(0.7));
    canvas.drawRect(rect, paint);
    canvas.restore();

    // Note: Removed the "Core" 2px line to comply with "no marques tu los bordes" (don't mark the borders).
    // The glow itself defines the boundary.
  }

  @override
  bool shouldRepaint(covariant _GlowingBorderPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
