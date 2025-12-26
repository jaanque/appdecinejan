import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../screens/movie_detail_screen.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onDelete; // Kept for compatibility but might be unused in selection mode
  final VoidCallback? onTap;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelectionToggle;

  const MovieCard({
    super.key,
    required this.movie,
    this.onDelete,
    this.onTap,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionToggle,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: isSelected
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
                isSelectionMode
                    ? Image.network(
                        movie.posterUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      )
                    : Hero(
                        tag: 'movie_poster_${movie.title}',
                        child: Image.network(
                          movie.posterUrl,
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
                if (isSelectionMode)
                  Container(
                    color: isSelected ? Colors.black.withOpacity(0.3) : Colors.transparent,
                    child: isSelected
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
            movie.title,
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
    if (isSelectionMode) {
      return GestureDetector(
        onTap: onSelectionToggle,
        child: cardContent,
      );
    }

    return LongPressDraggable<Movie>(
      data: movie,
      feedback: Transform.scale(
        scale: 1.05,
        child: SizedBox(
          width: 150,
          height: 220,
          child: Material(
            color: Colors.transparent,
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                movie.posterUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: cardContent,
      ),
      child: GestureDetector(
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MovieDetailScreen(movie: movie),
              ),
            );
          }
        },
        child: cardContent,
      ),
    );
  }
}
