import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../services/movie_service.dart';
import 'package:intl/intl.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  late Movie _movie;
  final TMDBService _tmdbService = TMDBService();
  final MovieService _movieService = MovieService();
  bool _isLoading = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _movie = widget.movie;
    _checkIfSaved();
    _fetchFullDetails();
  }

  Future<void> _checkIfSaved() async {
    // Logic to check if movie is in user's list (simplified for now as we don't have a direct check method without fetching all)
    // We could add `isSaved(id)` to MovieService, but for now let's assume it's not saved or check if we came from Home
    // Actually, let's just allow "Add" or "Delete" based on where we think we are, or just "Save" always.
    // Ideally we query `user_movies` by tmdb_id if available.
    // For this UI demo, we will toggle the icon state locally.
  }

  Future<void> _fetchFullDetails() async {
    if (_movie.cast == null) {
      setState(() => _isLoading = true);
      final fullMovie = await _tmdbService.getMovieDetails(_movie.title);
      if (mounted) {
        setState(() {
          if (fullMovie != null) _movie = fullMovie;
          _isLoading = false;
        });
      }
    }
  }

  String _formatRuntime(int? minutes) {
    if (minutes == null || minutes == 0) return '';
    final int hours = minutes ~/ 60;
    final int mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 1. Immersive Header
          SliverAppBar(
            expandedHeight: 500,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
                ],
              ),
              child: const BackButton(color: Colors.black),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Backdrop
                  Image.network(
                    _movie.posterUrl, // Using poster as backdrop usually looks better vertically on mobile if no backdrop
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                  // Gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.8),
                          Colors.black,
                        ],
                        stops: const [0.0, 0.5, 0.85, 1.0],
                      ),
                    ),
                  ),
                  // Content Overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            _movie.title,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Tagline
                          if (_movie.tagline != null && _movie.tagline!.isNotEmpty)
                            Text(
                              _movie.tagline!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.8),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          const SizedBox(height: 24),
                          // Key Metadata Row (Rating, Year, Runtime)
                          Row(
                            children: [
                              if (_movie.voteAverage != null)
                                _buildGlassBadge(
                                  Icons.star_rounded,
                                  _movie.voteAverage!.toStringAsFixed(1),
                                  Colors.amber,
                                ),
                              const SizedBox(width: 12),
                              if (_movie.releaseDate != null)
                                _buildGlassBadge(
                                  Icons.calendar_today_rounded,
                                  _movie.releaseDate!.split('-')[0],
                                  Colors.white,
                                ),
                              const SizedBox(width: 12),
                              if (_movie.runtime != null)
                                _buildGlassBadge(
                                  Icons.access_time_rounded,
                                  _formatRuntime(_movie.runtime),
                                  Colors.white,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Content Body
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black, // Continue dark theme from header fade
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Action Buttons (Save, Share)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Save logic
                              _movieService.saveMovie(_movie.title, _movie.posterUrl);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Saved to Library")),
                              );
                            },
                            icon: const Icon(Icons.bookmark_add_rounded),
                            label: const Text("Add to Library"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.share_rounded),
                            color: Colors.black,
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Genres
                    if (_movie.genres != null)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _movie.genres!.map((g) => Chip(
                          label: Text(g),
                          backgroundColor: Colors.grey.shade50,
                          side: BorderSide(color: Colors.grey.shade200),
                          labelStyle: TextStyle(color: Colors.grey.shade800, fontSize: 12),
                        )).toList(),
                      ),
                    const SizedBox(height: 32),

                    // Overview
                    const Text(
                      "Storyline",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _movie.overview ?? "No overview available.",
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Cast
                    if (_movie.cast != null && _movie.cast!.isNotEmpty) ...[
                      const Text(
                        "Cast",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _movie.cast!.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final actor = _movie.cast![index];
                            return Column(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundImage: actor.profileUrl != null
                                      ? NetworkImage(actor.profileUrl!)
                                      : null,
                                  backgroundColor: Colors.grey.shade200,
                                  child: actor.profileUrl == null
                                      ? const Icon(Icons.person, color: Colors.grey)
                                      : null,
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 70,
                                  child: Text(
                                    actor.name,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassBadge(IconData icon, String text, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
