import 'package:flutter/material.dart';
import '../models/collection.dart';
import '../models/movie.dart'; // Needed for DragTarget type
import '../services/collection_service.dart';
import '../screens/collection_detail_screen.dart';

class CollectionCard extends StatelessWidget {
  final Collection collection;
  final VoidCallback? onTap;
  final VoidCallback? onUpdate; // Callback to refresh parent after add

  const CollectionCard({
    super.key,
    required this.collection,
    this.onTap,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isHovered ? Colors.blue.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHovered ? Colors.blue : Colors.grey.shade300,
                width: isHovered ? 2 : 1,
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
                Icon(
                  isHovered ? Icons.add_to_photos_rounded : Icons.folder_special_rounded,
                  size: 48,
                  color: isHovered ? Colors.blue : Colors.grey.shade400,
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
                      color: isHovered ? Colors.blue.shade900 : Colors.grey.shade800,
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
          ),
        );
      },
    );
  }
}
