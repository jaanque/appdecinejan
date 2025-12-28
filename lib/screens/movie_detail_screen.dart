import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../services/movie_service.dart';
import 'package:intl/intl.dart';
import 'package:palette_generator/palette_generator.dart';
import '../models/watch_provider.dart';

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
  List<WatchProvider> _watchProviders = [];
  bool _isOverviewExpanded = false;
  final GlobalKey _overviewKey = GlobalKey();

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

      List<WatchProvider> providers = [];
      if (fullMovie != null && fullMovie.tmdbId != null) {
        // Default to 'US' for now, but method supports 'ES', 'MX' etc.
        providers = await _tmdbService.getWatchProviders(
          fullMovie.tmdbId!,
          mediaType: fullMovie.mediaType ?? 'movie',
          countryCode: 'US'
        );
      }

      if (mounted) {
        setState(() {
          if (fullMovie != null) _movie = fullMovie;
          _watchProviders = providers;
          _isLoading = false;
        });
      }
    } else if (_movie.tmdbId != null) {
        // Even if cast is present, providers might not be
        final providers = await _tmdbService.getWatchProviders(
          _movie.tmdbId!,
          mediaType: _movie.mediaType ?? 'movie',
          countryCode: 'US'
        );
        if (mounted) {
          setState(() {
            _watchProviders = providers;
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
                              const SizedBox(width: 12),
                              if (_movie.mediaType == 'tv' && _movie.numberOfSeasons != null)
                                _buildGlassBadge(
                                  Icons.layers_rounded,
                                  "${_movie.numberOfSeasons} S • ${_movie.numberOfEpisodes ?? '?'} E",
                                  Colors.white,
                                  fillColor: _vibrantColor.withOpacity(0.2),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Status Badge (if available and relevant)
                          if (_movie.status != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _movie.status == 'Ended' || _movie.status == 'Canceled'
                                    ? Colors.red.withOpacity(0.2)
                                    : Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _movie.status == 'Ended' || _movie.status == 'Canceled'
                                      ? Colors.red.withOpacity(0.5)
                                      : Colors.green.withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                _movie.status!.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
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
                    // Action Buttons (Share)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: _chipColor, // Subtle tint
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextButton.icon(
                              onPressed: () {},
                              icon: Icon(Icons.share_rounded, color: _chipTextColor),
                              label: Text("Share", style: TextStyle(color: _chipTextColor, fontWeight: FontWeight.bold)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Overview (Collapsible with Animation)
                    Text(
                      "Storyline",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isOverviewExpanded = !_isOverviewExpanded;
                        });

                        if (!_isOverviewExpanded) {
                          // Scroll back up when collapsing
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            Scrollable.ensureVisible(
                              _overviewKey.currentContext!,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              alignment: 0.1, // Leave a little space at top
                            );
                          });
                        }
                      },
                      child: Column(
                        key: _overviewKey,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: Stack(
                              children: [
                                Text(
                                  _movie.overview ?? "No overview available.",
                                  style: TextStyle(
                                    fontSize: 16,
                                    height: 1.6,
                                    color: secondaryTextColor,
                                  ),
                                  maxLines: _isOverviewExpanded ? null : 4,
                                  overflow: _isOverviewExpanded ? TextOverflow.visible : TextOverflow.fade,
                                ),
                                if (!_isOverviewExpanded && (_movie.overview?.length ?? 0) > 150)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 60,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            _backgroundColor.withOpacity(0.0),
                                            _backgroundColor,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if ((_movie.overview?.length ?? 0) > 150)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _isOverviewExpanded ? "Show less" : "Read more",
                                style: TextStyle(
                                  color: _vibrantColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Watch Providers
                    if (_watchProviders.isNotEmpty) ...[
                      Text(
                        "Where to Watch",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _watchProviders.map((provider) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Tooltip(
                                message: provider.providerName,
                                child: Image.network(
                                  provider.logoUrl,
                                  width: 50,
                                  height: 50,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.grey.shade300,
                                          child: const Icon(Icons.tv_off)
                                      ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Genres (Moved to bottom or hidden if considered clutter, keeping for now but less prominent)
                    if (_movie.genres != null && _movie.genres!.isNotEmpty) ...[
                       Text(
                        "Genres",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 12),
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
                    ],

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
