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
    // If we are missing details (like runtime or full overview if it was truncated), try to fetch them.
    // Checking runtime or genres is a good proxy for "full details loaded".
    if (_movie.runtime == null || _movie.genres == null) {
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

  String _formatRuntime(int? minutes) {
    if (minutes == null || minutes == 0) return '';
    final int hours = minutes ~/ 60;
    final int mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 450,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: const BackButton(color: Colors.black),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'movie_poster_${widget.movie.title}',
                    child: Image.network(
                      _movie.posterUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_movie.tagline != null && _movie.tagline!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              _movie.tagline!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontStyle: FontStyle.italic,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        Text(
                          _movie.title,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ],
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
                      // Metadata Row (Rating, Year, Runtime, Genres)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (_movie.voteAverage != null && _movie.voteAverage! > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      _movie.voteAverage!.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            if (_movie.releaseDate != null && _movie.releaseDate!.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _movie.releaseDate!.split('-')[0],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            if (_movie.runtime != null && _movie.runtime! > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _formatRuntime(_movie.runtime),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Genres
                      if (_movie.genres != null && _movie.genres!.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _movie.genres!.map((genre) {
                            return Chip(
                              label: Text(genre),
                              labelStyle: const TextStyle(fontSize: 12),
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 24),

                      // Overview
                      const Text(
                        "Overview",
                        style: TextStyle(
                          fontSize: 20,
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
                              height: 1.6,
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
