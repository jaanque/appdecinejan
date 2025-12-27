import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../services/movie_service.dart';
import 'package:intl/intl.dart';
import 'package:palette_generator/palette_generator.dart';
import '../widgets/skeletons.dart';

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
  Color _backgroundColor = Colors.white; // Main body background
  Color _darkColor = Colors.black; // Gradient end & connector
  Color _vibrantColor = Colors.blue; // Primary accents (buttons)
  Color _mutedColor = Colors.grey; // Secondary text
  Color _chipColor = Colors.grey.shade100; // Chip background
  Color _chipTextColor = Colors.black; // Chip text

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
      size: const Size(100, 150),
      maximumColorCount: 20,
    );

    if (mounted) {
      setState(() {
        // 1. Core Colors
        final darkVibrant = generator.darkVibrantColor?.color;
        final vibrant = generator.vibrantColor?.color;
        final lightVibrant = generator.lightVibrantColor?.color;
        final darkMuted = generator.darkMutedColor?.color;
        final muted = generator.mutedColor?.color;
        final lightMuted = generator.lightMutedColor?.color;
        final dominant = generator.dominantColor?.color;

        // 2. Connector & Header Dark Color
        // Prioritize a rich dark color from the poster
        _darkColor = darkVibrant ?? darkMuted ?? (dominant != null && dominant.computeLuminance() < 0.2 ? dominant : Colors.black);

        // 3. Main Background Color (Soft Tint)
        // Use a very light muted or vibrant tone blended with white
        final Color baseLight = lightMuted ?? lightVibrant ?? dominant ?? Colors.white;
        // Blend heavily with white to ensure it's a soft tint
        _backgroundColor = Color.alphaBlend(baseLight.withOpacity(0.15), Colors.white);

        // 4. Vibrant Accent (Buttons)
        // Prefer the most vibrant option
        _vibrantColor = vibrant ?? darkVibrant ?? dominant ?? Colors.black;

        // 5. Muted Text Color
        // For secondary text, use a dark muted tone if available, else standard grey/black
        _mutedColor = darkMuted ?? muted ?? Colors.black54;

        // 6. Chip Colors
        // Background: Light vibrant or light muted with transparency
        _chipColor = (lightVibrant ?? lightMuted ?? dominant ?? Colors.grey.shade200).withOpacity(0.2);
        // Text: Dark vibrant or dark muted
        _chipTextColor = darkVibrant ?? darkMuted ?? Colors.black87;
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const MovieDetailSkeleton(),
      );
    }

    // Calculate contrast-safe text colors
    final Color textColor = _backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    // Secondary text should be legible. If background is light, use _mutedColor (dark). If dark, use light grey.
    final Color secondaryTextColor = _backgroundColor.computeLuminance() > 0.5
        ? _mutedColor
        : Colors.white70;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: CustomScrollView(
        slivers: [
          // 1. Immersive Header
          SliverAppBar(
            expandedHeight: 500,
            pinned: true,
            backgroundColor: _backgroundColor,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _backgroundColor.withOpacity(0.8), // Adapt to theme
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
                ],
              ),
              child: BackButton(color: textColor), // Adapt icon color
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
                          _darkColor.withOpacity(0.3),
                          _darkColor.withOpacity(0.9),
                          _darkColor, // Seamless transition to connector
                        ],
                        stops: const [0.0, 0.4, 0.85, 1.0],
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
                              shadows: [
                                Shadow(blurRadius: 10, color: Colors.black45, offset: Offset(0, 2)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Tagline
                          if (_movie.tagline != null && _movie.tagline!.isNotEmpty)
                            Text(
                              _movie.tagline!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                                fontStyle: FontStyle.italic,
                                shadows: const [
                                  Shadow(blurRadius: 4, color: Colors.black45, offset: Offset(0, 1)),
                                ],
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
                                  fillColor: _vibrantColor.withOpacity(0.3),
                                ),
                              const SizedBox(width: 12),
                              if (_movie.releaseDate != null)
                                _buildGlassBadge(
                                  Icons.calendar_today_rounded,
                                  _movie.releaseDate!.split('-')[0],
                                  Colors.white,
                                  fillColor: _vibrantColor.withOpacity(0.2),
                                ),
                              const SizedBox(width: 12),
                              if (_movie.runtime != null)
                                _buildGlassBadge(
                                  Icons.access_time_rounded,
                                  _formatRuntime(_movie.runtime),
                                  Colors.white,
                                  fillColor: _vibrantColor.withOpacity(0.2),
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
                color: _darkColor, // Matches gradient end
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: _backgroundColor, // Dynamic light body
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5)
                    ),
                  ],
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
                              _movieService.saveMovie(_movie.title, _movie.posterUrl);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Saved to Library")),
                              );
                            },
                            icon: const Icon(Icons.bookmark_add_rounded),
                            label: const Text("Add to Library"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _vibrantColor, // Dynamic accent
                              foregroundColor: _vibrantColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                              shadowColor: _vibrantColor.withOpacity(0.4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: _chipColor, // Subtle tint
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.share_rounded),
                            color: _chipTextColor,
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
                          backgroundColor: _chipColor,
                          side: BorderSide.none,
                          labelStyle: TextStyle(
                            color: _chipTextColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        )).toList(),
                      ),
                    const SizedBox(height: 32),

                    // Overview
                    Text(
                      "Storyline",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
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
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _movie.cast!.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final actor = _movie.cast![index];
                            return Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _vibrantColor.withOpacity(0.3), width: 2),
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: CircleAvatar(
                                    radius: 30,
                                    backgroundImage: actor.profileUrl != null
                                        ? NetworkImage(actor.profileUrl!)
                                        : null,
                                    backgroundColor: _chipColor,
                                    child: actor.profileUrl == null
                                        ? Icon(Icons.person, color: _mutedColor)
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 70,
                                  child: Text(
                                    actor.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: textColor
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

  Widget _buildGlassBadge(IconData icon, String text, Color iconColor, {Color? fillColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fillColor ?? Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
              fontWeight: FontWeight.bold,
              shadows: [
                 Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(0, 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
