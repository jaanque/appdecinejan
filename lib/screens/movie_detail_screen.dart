import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../services/movie_service.dart';
import 'package:intl/intl.dart';
import 'package:palette_generator/palette_generator.dart';

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

  // Palette State
  Color _backgroundColor = Colors.white;
  Color _darkColor = Colors.black; // For gradient end and connector
  Color _accentColor = Colors.black; // For buttons/text accents

  @override
  void initState() {
    super.initState();
    _movie = widget.movie;
    _checkIfSaved();
    _fetchFullDetails();
    _updatePalette();
  }

  Future<void> _updatePalette() async {
    final PaletteGenerator generator = await PaletteGenerator.fromImageProvider(
      NetworkImage(_movie.posterUrl),
      size: const Size(100, 150), // Reduce size for performance
      maximumColorCount: 20,
    );

    if (mounted) {
      setState(() {
        // 1. Dark Color (Connector & Gradient End)
        // Prefer DarkVibrant, then DarkMuted, then Dominant (if dark), else Black
        _darkColor =
            generator.darkVibrantColor?.color ??
            generator.darkMutedColor?.color ??
            ((generator.dominantColor?.color.computeLuminance() ?? 1.0) < 0.2
                ? generator.dominantColor!.color
                : Colors.black);

        // 2. Background Color (Content Sheet)
        // We want a very soft tint. Take the LightMuted or Dominant and wash it out.
        Color baseLight =
            generator.lightMutedColor?.color ??
            generator.lightVibrantColor?.color ??
            generator.dominantColor?.color ??
            Colors.white;

        // Ensure it's very light (high luminance)
        if (baseLight.computeLuminance() < 0.8) {
          _backgroundColor = Color.alphaBlend(
            Colors.white.withOpacity(0.9),
            baseLight,
          );
        } else {
          _backgroundColor = baseLight.withOpacity(
            0.3,
          ); // Apply opacity to blend with white background of scaffold? No, scaffold is white.
          _backgroundColor = Color.alphaBlend(
            baseLight.withOpacity(0.2),
            Colors.white,
          );
        }

        // 3. Accent Color (Buttons)
        // Use Vibrant or Dominant
        _accentColor =
            generator.vibrantColor?.color ??
            generator.dominantColor?.color ??
            Colors.black;
      });
    }
  }

  Future<void> _checkIfSaved() async {
    // Logic to check if movie is in user's list (simplified for now)
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
    // Determine text color based on background luminance (usually black since we force light bg)
    final Color textColor = _backgroundColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
    final Color secondaryTextColor = textColor.withOpacity(0.6);

    return Scaffold(
      backgroundColor: _backgroundColor, // Apply dynamic background to Scaffold
      body: CustomScrollView(
        slivers: [
          // 1. Immersive Header
          SliverAppBar(
            expandedHeight: 500,
            pinned: true,
            backgroundColor: _backgroundColor, // Match Scaffold
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
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
                    _movie.posterUrl,
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
                          _darkColor.withOpacity(0.2),
                          _darkColor.withOpacity(0.8),
                          _darkColor, // Fade to dynamic dark color
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
                          if (_movie.tagline != null &&
                              _movie.tagline!.isNotEmpty)
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
              decoration: BoxDecoration(
                color: _darkColor, // Continue dynamic dark fade
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: _backgroundColor, // Dynamic light background
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
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
                              _movieService.saveMovie(
                                _movie.title,
                                _movie.posterUrl,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Saved to Library"),
                                ),
                              );
                            },
                            icon: const Icon(Icons.bookmark_add_rounded),
                            label: const Text("Add to Library"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _accentColor, // Use dynamic accent
                              foregroundColor:
                                  _accentColor.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(
                              0.05,
                            ), // Subtle tint
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.share_rounded),
                            color: textColor,
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
                        children: _movie.genres!
                            .map(
                              (g) => Chip(
                                label: Text(g),
                                backgroundColor: Colors.white.withOpacity(0.6),
                                side: BorderSide(
                                  color: Colors.black.withOpacity(0.1),
                                ),
                                labelStyle: TextStyle(
                                  color: textColor.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 32),

                    // Overview
                    Text(
                      "Storyline",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _movie.overview ?? "No overview available.",
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Cast
                    if (_movie.cast != null && _movie.cast!.isNotEmpty) ...[
                      Text(
                        "Cast",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _movie.cast!.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final actor = _movie.cast![index];
                            return Column(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundImage: actor.profileUrl != null
                                      ? NetworkImage(actor.profileUrl!)
                                      : null,
                                  backgroundColor: Colors.black.withOpacity(
                                    0.1,
                                  ),
                                  child: actor.profileUrl == null
                                      ? Icon(
                                          Icons.person,
                                          color: secondaryTextColor,
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 70,
                                  child: Text(
                                    actor.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: textColor,
                                    ),
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
