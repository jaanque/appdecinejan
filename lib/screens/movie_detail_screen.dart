import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../services/movie_service.dart';
import 'package:intl/intl.dart';
import 'package:palette_generator/palette_generator.dart';
import '../models/watch_provider.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;
  final bool showSaveButton;

  const MovieDetailScreen({super.key, required this.movie, this.showSaveButton = false});

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
  Color _buttonColor = Colors.blue; // Pastel background for main button
  Color _buttonTextColor = Colors.white; // Text color for main button
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
        _darkColor = darkVibrant ?? darkMuted ?? dominant ?? Colors.black;
        // Ensure it's dark enough for text contrast if used as bg
        if (_darkColor.computeLuminance() > 0.1) {
          _darkColor = Color.alphaBlend(Colors.black.withOpacity(0.6), _darkColor);
        }

        // 3. Main Background Color (Soft Tint)
        // Use a very light muted or vibrant tone blended with white
        final Color baseLight = lightMuted ?? lightVibrant ?? dominant ?? Colors.white;
        // Blend heavily with white to ensure it's a soft tint but slightly more saturated than before
        _backgroundColor = Color.alphaBlend(baseLight.withOpacity(0.12), Colors.white);

        // 4. Vibrant Accent (Buttons & Icons)
        // Prefer the most vibrant option. If not found, look for any colorful option.
        _vibrantColor = vibrant ?? darkVibrant ?? lightVibrant ?? dominant ?? Colors.black;

        // 5. Pastel Button Color
        // Prioritize a light/pastel tone. If not available, tint the vibrant color with white.
        final Color rawPastel = lightVibrant ?? lightMuted ?? vibrant ?? dominant ?? Colors.grey;
        if (rawPastel.computeLuminance() < 0.6) {
           // If too dark, mix with white to make it pastel
           _buttonColor = Color.alphaBlend(rawPastel.withOpacity(0.4), Colors.white);
        } else {
           _buttonColor = rawPastel;
        }

        // Ensure text is readable on pastel background (usually dark)
        _buttonTextColor = _buttonColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

        // 6. Muted Text Color
        // For secondary text, use a dark muted tone if available, else standard grey/black
        _mutedColor = darkMuted ?? muted ?? Colors.black54;

        // 7. Chip Colors
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
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Badge (Top)
                          if (_movie.status != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Text(
                                _movie.status!.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),

                          // Title
                          Text(
                            _movie.title,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.05,
                              letterSpacing: -0.5,
                              shadows: [
                                Shadow(blurRadius: 16, color: Colors.black, offset: Offset(0, 4)),
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
                                fontWeight: FontWeight.w300,
                                shadows: const [
                                  Shadow(blurRadius: 4, color: Colors.black45, offset: Offset(0, 1)),
                                ],
                              ),
                            ),
                          const SizedBox(height: 20),
                          // Key Metadata Row (Rating, Year, Runtime)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (_movie.voteAverage != null)
                                  _buildGlassBadge(
                                    Icons.star_rounded,
                                    _movie.voteAverage!.toStringAsFixed(1),
                                    Colors.amber,
                                    fillColor: _darkColor.withOpacity(0.8),
                                  ),
                                const SizedBox(width: 8),
                                if (_movie.releaseDate != null)
                                  _buildGlassBadge(
                                    Icons.calendar_today_rounded,
                                    _movie.releaseDate!.split('-')[0],
                                    Colors.white,
                                    fillColor: _darkColor.withOpacity(0.8),
                                  ),
                                const SizedBox(width: 8),
                                if (_movie.runtime != null)
                                  _buildGlassBadge(
                                    Icons.access_time_rounded,
                                    _formatRuntime(_movie.runtime),
                                    Colors.white,
                                    fillColor: _darkColor.withOpacity(0.8),
                                  ),
                                const SizedBox(width: 8),
                                if (_movie.mediaType == 'tv' && _movie.numberOfSeasons != null)
                                  _buildGlassBadge(
                                    Icons.layers_rounded,
                                    "${_movie.numberOfSeasons} Seasons",
                                    Colors.white,
                                    fillColor: _darkColor.withOpacity(0.8),
                                  ),
                              ],
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
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_backgroundColor, Colors.white],
                    stops: const [0.0, 0.3],
                  ),
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
                    // Action Buttons
                    Row(
                      children: [
                        if (widget.showSaveButton) ...[
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  await _movieService.saveMovie(_movie);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Movie saved to your collection")),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Error saving movie")),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.bookmark_add_rounded),
                              label: const Text("Save Movie"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _buttonColor,
                                foregroundColor: _buttonTextColor,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 8,
                                shadowColor: _buttonColor.withOpacity(0.4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Share logic placeholder
                            },
                            icon: const Icon(Icons.ios_share_rounded, size: 20),
                            label: const Text("Share"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _vibrantColor,
                              side: BorderSide(color: _vibrantColor.withOpacity(0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Overview (Collapsible with Animation)
                    Text(
                      "Storyline",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _darkColor.withOpacity(0.8)),
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
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _darkColor.withOpacity(0.8)),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _watchProviders.map((provider) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _vibrantColor.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Tooltip(
                                message: provider.providerName,
                                child: Image.network(
                                  provider.logoUrl,
                                  width: 56,
                                  height: 56,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                          width: 56,
                                          height: 56,
                                          color: Colors.grey.shade200,
                                          child: Icon(Icons.tv_off_rounded, color: Colors.grey.shade400)
                                      ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                    ] else if (!_isLoading && _movie.tmdbId != null) ...[
                      // Empty state for watch providers if we tried to fetch them
                      Text(
                        "Where to Watch",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _darkColor.withOpacity(0.8)),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 20, color: secondaryTextColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "No streaming information available for your region.",
                                style: TextStyle(color: secondaryTextColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Cast
                    if (_movie.cast != null && _movie.cast!.isNotEmpty) ...[
                      Text(
                        "Cast",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _darkColor.withOpacity(0.8)),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 130, // Increased height
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _movie.cast!.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 20),
                          itemBuilder: (context, index) {
                            final actor = _movie.cast![index];
                            return SizedBox(
                              width: 80, // Fixed width container
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: _vibrantColor.withOpacity(0.3), width: 2),
                                      boxShadow: [
                                         BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 36, // Larger avatar
                                      backgroundImage: actor.profileUrl != null
                                          ? NetworkImage(actor.profileUrl!)
                                          : null,
                                      backgroundColor: Colors.grey.shade200,
                                      child: actor.profileUrl == null
                                          ? Icon(Icons.person, color: Colors.grey.shade400, size: 32)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    actor.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                      height: 1.2
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Genres (Moved to bottom)
                    if (_movie.genres != null && _movie.genres!.isNotEmpty) ...[
                      Divider(color: secondaryTextColor.withOpacity(0.1), height: 32),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _movie.genres!.map((g) => Chip(
                          label: Text(g),
                          backgroundColor: _chipColor,
                          shape: const StadiumBorder(side: BorderSide.none),
                          labelStyle: TextStyle(
                            color: _chipTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12
                          ),
                          padding: const EdgeInsets.all(0),
                        )).toList(),
                      ),
                       const SizedBox(height: 32),
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
