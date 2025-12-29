import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math';
import 'package:shake/shake.dart';
import 'package:palette_generator/palette_generator.dart';
import '../models/movie.dart';
import '../services/movie_service.dart';
import '../services/ai_service.dart';
import '../services/tmdb_service.dart';
import 'movie_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  // Usamos late para asegurar que se inicialicen en initState
  late AnimationController _controller;
  AnimationController? _iconShakeController;
  ShakeDetector? _shakeDetector;

  final MovieService _movieService = MovieService();
  final AIService _aiService = AIService();
  final TMDBService _tmdbService = TMDBService();

  bool _isSearching = false;
  Movie? _recommendedMovie;
  List<Color>? _glowColors;

  @override
  void initState() {
    super.initState();
    _initController();
    _initShakeDetector();
  }

  void _initController() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _initShakeController();
  }

  void _initShakeController() {
    _iconShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: false);
  }

  AnimationController get _safeIconShakeController {
    if (_iconShakeController == null) {
      _initShakeController();
    }
    return _iconShakeController!;
  }

  void _initShakeDetector() {
    _shakeDetector = ShakeDetector.autoStart(
      // CORRECCIÓN: Se agrega el parámetro (event)
      onPhoneShake: (ShakeEvent event) {
        _handleShake();
      },
      minimumShakeCount: 1,
      shakeSlopTimeMS: 500,
      shakeCountResetTime: 3000,
      shakeThresholdGravity: 2.7,
    );
  }

  // Mantenemos la lógica pero la llamamos desde el detector corregido
  Future<void> _handleShake() async {
    if (_isSearching || _recommendedMovie != null) return;

    if (mounted) {
      setState(() {
        _isSearching = true;
      });
    }

    try {
      // 1. Obtener películas recientes
      final movies = await _movieService.getLastSavedMovies(5);

      // 2. Obtener recomendación de IA
      final recommendedTitle = await _aiService.getRecommendation(movies);

      if (recommendedTitle != null) {
        // 3. Obtener detalles de TMDB
        final movie = await _tmdbService.getMovieDetails(recommendedTitle);

        // 4. Generate dynamic aura
        List<Color>? palette;
        if (movie != null) {
          palette = await _generatePalette(movie);
        }

        if (mounted) {
          setState(() {
            _recommendedMovie = movie;
            _glowColors = palette;
            _isSearching = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isSearching = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Could not generate a recommendation at this time.",
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error discovering movie: $e");
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error discovering movie. Please try again."),
          ),
        );
      }
    }
  }

  Future<List<Color>?> _generatePalette(Movie movie) async {
    try {
      final PaletteGenerator generator =
          await PaletteGenerator.fromImageProvider(
            NetworkImage(movie.posterUrl),
            size: const Size(100, 150),
            maximumColorCount: 20,
          );

      final candidates = [
        generator.vibrantColor?.color,
        generator.lightVibrantColor?.color,
        generator.darkVibrantColor?.color,
        generator.mutedColor?.color,
        generator.dominantColor?.color,
      ].whereType<Color>().toList();

      if (candidates.isNotEmpty) {
        // Ensure we have a nice loop of 6 colors
        List<Color> newColors = [];
        for (int i = 0; i < 6; i++) {
          newColors.add(candidates[i % candidates.length]);
        }
        // Force start and end match for smooth sweep gradient
        newColors[5] = newColors[0];
        return newColors;
      }
    } catch (e) {
      debugPrint("Error generating palette: $e");
    }
    return null;
  }

  void _resetDiscovery() {
    setState(() {
      _recommendedMovie = null;
      _glowColors = null;
      _isSearching = false;
    });
  }

  Future<void> _addToHome() async {
    if (_recommendedMovie == null) return;

    try {
      await _movieService.saveMovie(_recommendedMovie!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${_recommendedMovie!.title} added to Home"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Error adding movie")));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _iconShakeController?.dispose();
    _shakeDetector?.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Eliminamos la inicialización que estaba aquí para evitar errores
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Apple Intelligence Style Glow
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _DiscreteGlowPainter(
                    animationValue: _controller.value,
                    customColors: _glowColors,
                  ),
                );
              },
            ),
          ),

          // Content
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _recommendedMovie != null
                  ? _buildRecommendationCard()
                  : _buildShakePrompt(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShakePrompt() {
    return GestureDetector(
      onTap: _isSearching ? null : _handleShake,
      behavior: HitTestBehavior.opaque,
      child: Column(
        key: const ValueKey('prompt'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isSearching) ...[
            const CircularProgressIndicator(color: Colors.black54),
            const SizedBox(height: 24),
            const Text(
              "Analyzing your taste...",
              style: TextStyle(
                fontSize: 18,
                color: Colors.black54,
                letterSpacing: -0.5,
              ),
            ),
          ] else ...[
            // Animated Shake Icon
            AnimatedBuilder(
              animation: _safeIconShakeController,
              builder: (context, child) {
                // Create a shake effect: only shake during the first 20% of the cycle
                double offset = 0;
                final t = _safeIconShakeController.value;
                if (t < 0.2) {
                  // Shake 3 times in the first 0.2 (400ms)
                  offset = sin(t * 5 * 2 * pi) * 0.1;
                }
                return Transform.rotate(angle: offset, child: child);
              },
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.phone_iphone_rounded,
                  size: 64,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Shake to discover",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "or tap here",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationCard() {
    return Column(
      key: const ValueKey('card'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MovieDetailScreen(
                  movie: _recommendedMovie!,
                  showSaveButton: true,
                ),
              ),
            );
          },
          child: Hero(
            tag: _recommendedMovie!.title,
            child: Container(
              width: 250,
              height: 375,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                image: DecorationImage(
                  image: NetworkImage(_recommendedMovie!.posterUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            _recommendedMovie!.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _addToHome,
              icon: const Icon(Icons.add),
              label: const Text("Add to Home"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: _resetDiscovery,
              icon: const Icon(Icons.refresh),
              tooltip: "Try again",
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DiscreteGlowPainter extends CustomPainter {
  final double animationValue;
  final List<Color>? customColors;

  _DiscreteGlowPainter({required this.animationValue, this.customColors});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    List<Color> colors;

    if (customColors != null && customColors!.isNotEmpty) {
      colors = customColors!.map((c) => c.withOpacity(0.3)).toList();
      // Ensure we have enough colors for the gradient logic below, or duplicate if too few
      if (colors.length < 2) {
        colors = List.filled(6, colors.first);
      }
    } else {
      colors = [
        const Color(0xFF40C8E0).withOpacity(0.3),
        const Color(0xFF6439FF).withOpacity(0.3),
        const Color(0xFFA839FF).withOpacity(0.3),
        const Color(0xFFFF39A0).withOpacity(0.3),
        const Color(0xFFFF8539).withOpacity(0.3),
        const Color(0xFF40C8E0).withOpacity(0.3),
      ];
    }

    final gradient = SweepGradient(
      center: Alignment.center,
      colors: colors,
      // If custom colors count != 6, stops might need adjustment or be null for even distribution
      stops: colors.length == 6 ? const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0] : null,
      transform: GradientRotation(animationValue * 2 * pi),
    );

    final breathe = sin(animationValue * 2 * pi) * 0.5 + 0.5;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 35 + (breathe * 10)
      ..shader = gradient.createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _DiscreteGlowPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.customColors != customColors;
  }
}
