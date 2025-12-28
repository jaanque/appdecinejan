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
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10 // Thinner, finer border
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10); // Cleaner, less diffuse blur

    // Apple Intelligence-like colors
    final colors = [
      Colors.cyanAccent,
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.orangeAccent,
      Colors.cyanAccent, // Wrap around
    ];

    // Create a rotating sweep gradient
    final gradient = SweepGradient(
      colors: colors,
      stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
      transform: GradientRotation(animationValue * 2 * pi),
    );

    paint.shader = gradient.createShader(rect);

    // Draw the rectangle path
    // We inset slightly so the blur doesn't get clipped too much at the very edge,
    // although stroke stays centered on the path.
    // If strokeWidth is 40, we might want to draw closely to the edge.
    // Let's draw exactly on the edge.
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowingBorderPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
