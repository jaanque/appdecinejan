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
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure controller is initialized (handles hot reload case)
    if (_controller == null) {
      _initController();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Dynamic Aura - Left Side
          AnimatedBuilder(
            animation: _controller!,
            builder: (context, child) {
              return Positioned(
                top: MediaQuery.of(context).size.height * 0.2 + (sin(_controller!.value * 2 * pi) * 50),
                left: -100,
                child: Container(
                  width: 200,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple.withOpacity(0.4),
                        Colors.blue.withOpacity(0.4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              );
            },
          ),

          // Dynamic Aura - Right Side
          AnimatedBuilder(
            animation: _controller!,
            builder: (context, child) {
              return Positioned(
                bottom: MediaQuery.of(context).size.height * 0.2 + (cos(_controller!.value * 2 * pi) * 50),
                right: -100,
                child: Container(
                  width: 200,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.pink.withOpacity(0.4),
                        Colors.orange.withOpacity(0.4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              );
            },
          ),

          // Blur Overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.vibration_rounded, // Shake/Phone icon
                  size: 64,
                  color: Colors.grey.shade400,
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
