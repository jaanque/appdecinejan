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
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildAnimatedOrb({
    required Animation<double> animation,
    required Alignment alignment,
    required List<Color> colors,
    required double offsetMultiplier,
    bool isVerticalMovement = true,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double value = sin(animation.value * 2 * pi + offsetMultiplier);
        final double offset = value * 30; // Movement range

        double? top, bottom, left, right;

        // Base positions based on alignment
        if (alignment == Alignment.topLeft) {
          top = -100 + (isVerticalMovement ? offset : 0);
          left = -100 + (!isVerticalMovement ? offset : 0);
        } else if (alignment == Alignment.topRight) {
          top = -100 + (isVerticalMovement ? offset : 0);
          right = -100 + (!isVerticalMovement ? offset : 0);
        } else if (alignment == Alignment.bottomLeft) {
          bottom = -100 + (isVerticalMovement ? offset : 0);
          left = -100 + (!isVerticalMovement ? offset : 0);
        } else if (alignment == Alignment.bottomRight) {
          bottom = -100 + (isVerticalMovement ? offset : 0);
          right = -100 + (!isVerticalMovement ? offset : 0);
        }

        return Positioned(
          top: top,
          bottom: bottom,
          left: left,
          right: right,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: colors.map((c) => c.withOpacity(0.5)).toList(),
                center: Alignment.center,
                radius: 0.6,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) _initController();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top Left - Purple/Blue
          _buildAnimatedOrb(
            animation: _controller!,
            alignment: Alignment.topLeft,
            colors: [Colors.purple, Colors.deepPurpleAccent],
            offsetMultiplier: 0,
            isVerticalMovement: true,
          ),

          // Top Right - Blue/Cyan
          _buildAnimatedOrb(
            animation: _controller!,
            alignment: Alignment.topRight,
            colors: [Colors.blue, Colors.cyan],
            offsetMultiplier: pi / 2,
            isVerticalMovement: false, // Move horizontally
          ),

          // Bottom Right - Pink/Orange
          _buildAnimatedOrb(
            animation: _controller!,
            alignment: Alignment.bottomRight,
            colors: [Colors.pink, Colors.orange],
            offsetMultiplier: pi,
            isVerticalMovement: true,
          ),

          // Bottom Left - Teal/Green
          _buildAnimatedOrb(
            animation: _controller!,
            alignment: Alignment.bottomLeft,
            colors: [Colors.teal, Colors.greenAccent],
            offsetMultiplier: 3 * pi / 2,
            isVerticalMovement: false, // Move horizontally
          ),

          // Heavy Blur to blend everything into a frame aura
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                color: Colors.white.withOpacity(0.3),
              ),
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
