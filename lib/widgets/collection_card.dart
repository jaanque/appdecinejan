import 'package:flutter/material.dart';
import '../models/collection.dart';
import '../models/movie.dart'; // Needed for DragTarget type
import '../services/collection_service.dart';
import '../screens/collection_detail_screen.dart';

class CollectionCard extends StatelessWidget {
  final Collection collection;
  final VoidCallback? onTap;
  final VoidCallback? onUpdate; // Callback to refresh parent after add
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelectionToggle;

  const CollectionCard({
    super.key,
    required this.collection,
    this.onTap,
    this.onUpdate,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionToggle,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(color: Colors.blue, width: 3)
            : Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_special_rounded,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  collection.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Collection",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          if (isSelectionMode)
            Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.black.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check_circle, color: Colors.blue, size: 40),
                    )
                  : const Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.circle_outlined, color: Colors.grey, size: 28),
                      ),
                    ),
            ),
        ],
      ),
    );

    if (isSelectionMode) {
      return GestureDetector(
        onTap: onSelectionToggle,
        child: cardContent,
      );
    }

    return DragTarget<Movie>(
      onWillAccept: (movie) => true,
      onAccept: (movie) async {
        if (collection.id != null && movie.id != null) {
          try {
            await CollectionService().addMovieToCollection(collection.id!, movie.id!);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Added to ${collection.name}")),
            );
            if (onUpdate != null) onUpdate!();
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to add movie")),
            );
          }
        }
      },
      builder: (context, candidateData, rejectedData) {
        final bool isHovered = candidateData.isNotEmpty;

        if (isHovered) {
          // Render hover state
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.blue,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_to_photos_rounded,
                  size: 48,
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    collection.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Add Movie",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return GestureDetector(
          onTap: () {
            if (onTap != null) {
              onTap!();
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CollectionDetailScreen(collection: collection),
                ),
              );
            }
          },
          child: cardContent,
        );
      },
    );
  }
}
