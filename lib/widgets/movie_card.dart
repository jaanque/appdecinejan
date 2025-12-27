import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../screens/movie_detail_screen.dart';

class MovieCard extends StatefulWidget {
  final Movie movie;
  final VoidCallback? onDelete; // Kept for compatibility but might be unused in selection mode
  final VoidCallback? onTap;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelectionToggle;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;

  const MovieCard({
    super.key,
    required this.movie,
    this.onDelete,
    this.onTap,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionToggle,
    this.onDragStarted,
    this.onDragEnd,
  });

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  int _dropCount = 0;

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: widget.isSelected
                  ? Border.all(color: Colors.blue, width: 3)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // If we are in selection mode, disable the Hero to avoid conflicts during UI updates
                widget.isSelectionMode
                    ? Image.network(
                        widget.movie.posterUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      )
                    : Hero(
                        tag: 'movie_poster_${widget.movie.title}',
                        child: Image.network(
                          widget.movie.posterUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),

                // Selection Overlay
                if (widget.isSelectionMode)
                  Container(
                    color: widget.isSelected ? Colors.black.withOpacity(0.3) : Colors.transparent,
                    child: widget.isSelected
                        ? const Center(
                            child: Icon(Icons.check_circle, color: Colors.white, size: 40),
                          )
                        : const Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.circle_outlined, color: Colors.white, size: 28),
                            ),
                          ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            widget.movie.title,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );

    // If in selection mode, disable Draggable and just use Tap
    if (widget.isSelectionMode) {
      return GestureDetector(
        onTap: widget.onSelectionToggle,
        child: cardContent,
      );
    }

    return LongPressDraggable<Movie>(
      data: widget.movie,
      onDragStarted: widget.onDragStarted,
      onDragEnd: (details) {
        if (widget.onDragEnd != null) widget.onDragEnd!();
        // Only animate back if the drop was NOT accepted by a target (e.g. collection)
        if (!details.wasAccepted && mounted) {
          setState(() {
            _dropCount++;
          });
        }
      },
      feedback: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 1.2), // Pop to 1.2
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: SizedBox(
              width: 150,
              height: 220,
              child: Material(
                color: Colors.transparent,
                elevation: 16, // Higher elevation
                borderRadius: BorderRadius.circular(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    widget.movie.posterUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          );
        },
      ),
      childWhenDragging: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 0.0), // Fade to transparent
        duration: const Duration(milliseconds: 200),
        builder: (context, opacity, child) {
          return Opacity(
            opacity: opacity,
            child: cardContent,
          );
        },
      ),
      child: GestureDetector(
        onTap: () {
          if (widget.onTap != null) {
            widget.onTap!();
          } else {
            // Custom "Zoom" Transition
            Navigator.of(context).push(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 350),
                reverseTransitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (context, animation, secondaryAnimation) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                      reverseCurve: Curves.easeInCubic,
                    ),
                    child: MovieDetailScreen(movie: widget.movie),
                  );
                },
              ),
            );
          }
        },
        child: _dropCount > 0
            ? TweenAnimationBuilder<double>(
                key: ValueKey(_dropCount), // Restart animation on drop
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800), // Slower, fluid
                curve: Curves.elasticOut, // Bounce effect
                builder: (context, value, child) {
                  // Scale: 1.2 -> 1.0
                  final scale = 1.2 - (0.2 * value);
                  // Opacity: 0.0 -> 1.0
                  final opacity = value; // Simple linear opacity or easeIn

                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: cardContent,
                    ),
                  );
                },
              )
            : cardContent,
      ),
    );
  }
}
