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
      duration: const Duration(seconds: 10), // Slower, more elegant rotation
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
          // Full Screen Dynamic Aura
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller!,
              builder: (context, child) {
                return CustomPaint(
                  painter: _AuroraPainter(
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
                  color: Colors.black54,
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

class _AuroraPainter extends CustomPainter {
  final double animationValue;

  _AuroraPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;

    // Apple Intelligence / Aurora Colors
    // Using slightly lighter/pastel variants for a professional full-screen wash
    final colors = [
      const Color(0xFF40C8E0).withOpacity(0.6), // Cyan
      const Color(0xFF6439FF).withOpacity(0.6), // Deep Blue/Purple
      const Color(0xFFA839FF).withOpacity(0.6), // Purple
      const Color(0xFFFF39A0).withOpacity(0.6), // Pink
      const Color(0xFFFF8539).withOpacity(0.6), // Orange
      const Color(0xFF40C8E0).withOpacity(0.6), // Cyan loop
    ];

    // Rotating Gradient
    final gradient = SweepGradient(
      center: Alignment.center,
      colors: colors,
      stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
      transform: GradientRotation(animationValue * 2 * pi),
    );

    // Breathing effect (pulsing scale/intensity)
    final breathe = sin(animationValue * 2 * pi); // -1 to 1

    final paint = Paint()
      ..style = PaintingStyle.stroke // Keep stroke to push color from edges inward
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(rect);

    // To cover the whole screen with a "border" based effect, we need a massive stroke
    // and massive blur.

    // Layer 1: The Deep Background Wash
    // Covers almost everything with soft diffuse light
    paint
      ..strokeWidth = size.shortestSide * 1.5 // Massive stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120); // Huge blur

    canvas.saveLayer(rect, Paint()..color = Colors.white.withOpacity(0.5));
    canvas.drawRect(rect.inflate(50), paint); // Draw slightly outside to pull gradient in
    canvas.restore();

    // Layer 2: The "Structure" (Slightly more defined, moving)
    // This retains the "border" feel but highly diffused into the center
    paint
      ..strokeWidth = size.shortestSide * 0.5 + (breathe * 20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    canvas.saveLayer(rect, Paint()..color = Colors.white.withOpacity(0.8));
    canvas.drawRect(rect, paint);
    canvas.restore();

    // We removed the sharp core layer entirely to ensure it's "mas difuminado" (more blurred)
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
