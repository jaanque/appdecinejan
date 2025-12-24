import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  late Movie _movie;
  final TMDBService _tmdbService = TMDBService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _movie = widget.movie;
    _fetchFullDetails();
  }

  Future<void> _fetchFullDetails() async {
    // If we are missing details, try to fetch them
    if (_movie.overview == null || _movie.overview!.isEmpty) {
      setState(() {
        _isLoading = true;
      });

      final fullMovie = await _tmdbService.getMovieDetails(_movie.title);

      if (mounted && fullMovie != null) {
        setState(() {
          _movie = fullMovie; // Update with full details
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const BackButton(color: Colors.black),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'movie_poster_${widget.movie.title}', // Use original tag for transition
                    child: Image.network(
                      _movie.posterUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Gradient overlay for text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        _movie.title,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Metadata Row (Rating, Year)
                      Row(
                        children: [
                          if (_movie.voteAverage != null && _movie.voteAverage! > 0) ...[
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                            const SizedBox(width: 4),
                            Text(
                              _movie.voteAverage!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          if (_movie.releaseDate != null && _movie.releaseDate!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _movie.releaseDate!.split('-')[0], // Year only
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Overview
                      const Text(
                        "Overview",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _isLoading
                        ? const Center(child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                          ))
                        : Text(
                            _movie.overview ?? "No description available.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              height: 1.5,
                            ),
                          ),

                      const SizedBox(height: 40),
                    ],
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
