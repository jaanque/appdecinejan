import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/movie.dart';

class UserTasteProfile extends StatelessWidget {
  final List<Movie> movies;

  const UserTasteProfile({super.key, required this.movies});

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) {
      return const SizedBox.shrink();
    }

    final stats = _calculateGenreStats(movies);
    final topGenres = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 5 for the chart
    final displayGenres = topGenres.take(5).toList();
    final totalMovies = movies.length;

    if (displayGenres.isEmpty) {
      return const SizedBox.shrink();
    }

    final dominantGenre = displayGenres.isNotEmpty ? displayGenres.first.key : null;
    final userType = _getUserType(dominantGenre);
    final userTypeDescription = _getUserTypeDescription(dominantGenre);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Your Cinematic Persona',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          userType,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Text(
            userTypeDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 200,
          width: 200,
          child: CustomPaint(
            painter: _DonutChartPainter(
              data: displayGenres.map((e) => e.value.toDouble()).toList(),
              colors: _getGenreColors(displayGenres.map((e) => e.key).toList()),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    totalMovies.toString(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  Text(
                    'Movies',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Column(
          children: displayGenres.map((entry) {
            final percentage = (entry.value / totalMovies);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getGenreColor(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.grey.shade100,
                        color: _getGenreColor(entry.key).withOpacity(0.8),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${(percentage * 100).toInt()}%',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Map<String, int> _calculateGenreStats(List<Movie> movies) {
    final Map<String, int> stats = {};
    for (var movie in movies) {
      if (movie.genres != null) {
        for (var genre in movie.genres!) {
          stats[genre] = (stats[genre] ?? 0) + 1;
        }
      }
    }
    return stats;
  }

  String _getUserType(String? dominantGenre) {
    if (dominantGenre == null) return 'Movie Buff';

    switch (dominantGenre.toLowerCase()) {
      case 'action':
        return 'Action Hero';
      case 'adventure':
        return 'Explorer';
      case 'animation':
        return 'Dreamer';
      case 'comedy':
        return 'Jokester';
      case 'crime':
        return 'Detective';
      case 'documentary':
        return 'Knowledge Seeker';
      case 'drama':
        return 'Dramatic Soul';
      case 'family':
        return 'Family Oriented';
      case 'fantasy':
        return 'Visionary';
      case 'history':
        return 'Historian';
      case 'horror':
        return 'Thrill Seeker';
      case 'music':
        return 'Melophile';
      case 'mystery':
        return 'Enigma';
      case 'romance':
        return 'Hopeless Romantic';
      case 'science fiction':
      case 'sci-fi':
        return 'Futurist';
      case 'tv movie':
        return 'Couch Potato';
      case 'thriller':
        return 'Adrenaline Junkie';
      case 'war':
        return 'Strategist';
      case 'western':
        return 'Outlaw';
      default:
        return 'Cinephile';
    }
  }

  String _getUserTypeDescription(String? dominantGenre) {
    if (dominantGenre == null) return "You love movies of all kinds!";

    switch (dominantGenre.toLowerCase()) {
      case 'action':
        return "You live for the adrenaline rush, explosions, and high-stakes chases.";
      case 'horror':
        return "You enjoy the suspense and the thrill of the unknown.";
      case 'romance':
        return "You believe in love, emotions, and happy endings.";
      case 'comedy':
        return "You love to laugh and don't take life too seriously.";
      case 'drama':
        return "You appreciate deep stories, complex characters, and emotional journeys.";
      case 'sci-fi':
      case 'science fiction':
        return "Your mind is always in the future, wondering 'what if?'.";
      case 'documentary':
        return "You have a hunger for truth and understanding the real world.";
      case 'fantasy':
        return "You love escaping to magical worlds and epic adventures.";
      case 'thriller':
        return "You love being on the edge of your seat with twists and turns.";
      default:
        return "You have a diverse taste and appreciate good cinema.";
    }
  }

  Color _getGenreColor(String genre) {
    // Generate a consistent pastel/soft color based on the genre string hash
    final hash = genre.hashCode;
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = (hash & 0x0000FF);

    // Mix with white to make it pastel
    return Color.fromARGB(255, (r + 255) ~/ 2, (g + 255) ~/ 2, (b + 255) ~/ 2);
  }

  List<Color> _getGenreColors(List<String> genres) {
    return genres.map((g) => _getGenreColor(g)).toList();
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<double> data;
  final List<Color> colors;

  _DonutChartPainter({required this.data, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final total = data.reduce((a, b) => a + b);
    double startAngle = -math.pi / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i] / total) * 2 * math.pi;
      // Add a small gap between segments if there are multiple
      final gap = data.length > 1 ? 0.1 : 0.0;

      paint.color = colors[i];

      // Draw arc
      canvas.drawArc(
        rect.deflate(12), // Deflate by half stroke width
        startAngle + (gap / 2),
        sweepAngle - gap,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
