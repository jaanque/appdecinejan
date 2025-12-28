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
    // Define the shape (Rounded Rectangle for a modern look)
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(32));

    // Apple Intelligence Colors (Vibrant & Smooth)
    final colors = [
      const Color(0xFF00C7BE), // Cyan
      const Color(0xFF007AFF), // Blue
      const Color(0xFFAF52DE), // Purple
      const Color(0xFFFF2D55), // Pink
      const Color(0xFFFF9500), // Orange
      const Color(0xFF00C7BE), // Loop back to Cyan
    ];

    // Rotating Gradient
    final gradient = SweepGradient(
      colors: colors,
      stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
      transform: GradientRotation(animationValue * 2 * pi),
    );

    // Breathing effect (pulsing opacity/width)
    final breathe = sin(animationValue * 4 * pi) * 0.5 + 0.5; // 0.0 to 1.0

    // --- Layer 1: Ambient Haze (Wide, soft, background) ---
    final paintHaze = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30
      ..shader = gradient.createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    // Reduce opacity for haze
    canvas.saveLayer(rect, Paint()..color = Colors.white.withOpacity(0.3));
    canvas.drawRRect(rrect, paintHaze);
    canvas.restore();

    // --- Layer 2: Primary Glow (Body) ---
    final paintGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 + (breathe * 4) // Pulse width slightly (8-12px)
      ..shader = gradient.createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.saveLayer(rect, Paint()..color = Colors.white.withOpacity(0.6));
    canvas.drawRRect(rrect, paintGlow);
    canvas.restore();

    // --- Layer 3: Core (Sharp definition) ---
    final paintCore = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = gradient.createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1); // Very slight blur for anti-aliasing

    // Draw core with full opacity
    canvas.drawRRect(rrect, paintCore);
  }

  @override
  bool shouldRepaint(covariant _GlowingBorderPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
