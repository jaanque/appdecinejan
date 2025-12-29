import 'package:flutter/material.dart';
import '../models/collection.dart';
import '../models/movie.dart';
import '../services/collection_service.dart';
import '../widgets/movie_card.dart';

class CollectionDetailScreen extends StatefulWidget {
  final Collection collection;

  const CollectionDetailScreen({super.key, required this.collection});

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  final CollectionService _collectionService = CollectionService();
  List<Movie> _movies = [];
  bool _isLoading = true;
  late String _currentName;

  @override
  void initState() {
    super.initState();
    _currentName = widget.collection.name;
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    if (widget.collection.id == null) return;

    setState(() => _isLoading = true);
    final movies = await _collectionService.getMoviesInCollection(widget.collection.id!);

    if (mounted) {
      setState(() {
        _movies = movies;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCollection() async {
    if (widget.collection.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Collection?'),
        content: const Text('This action cannot be undone. Movies will remain in your library.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _collectionService.deleteCollection(widget.collection.id!);
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate deletion
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error deleting collection')),
          );
        }
      }
    }
  }

  Future<void> _renameCollection() async {
    if (widget.collection.id == null) return;

    final TextEditingController controller = TextEditingController(text: _currentName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Collection'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter new name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != _currentName && mounted) {
      try {
        await _collectionService.renameCollection(widget.collection.id!, newName);
        setState(() {
          _currentName = newName;
        });
        // Optionally notify parent to refresh
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error renaming collection')),
          );
        }
      }
    }
  }

  Future<void> _removeMovie(Movie movie) async {
    if (widget.collection.id == null || movie.id == null) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Remove '${movie.title}'?",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
             ListTile(
               leading: const Icon(Icons.delete_outline, color: Colors.red),
               title: const Text("Remove from Collection", style: TextStyle(color: Colors.red)),
               onTap: () => Navigator.pop(context, true),
             ),
             ListTile(
               leading: const Icon(Icons.close),
               title: const Text("Cancel"),
               onTap: () => Navigator.pop(context, false),
             ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _collectionService.removeMovieFromCollection(widget.collection.id!, movie.id!);
        setState(() {
          _movies.removeWhere((m) => m.id == movie.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Movie removed'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.black,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error removing movie')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            floating: true,
            pinned: true,
            leading: const BackButton(color: Colors.black),
            title: Text(
              _currentName,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded, color: Colors.black),
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
                onSelected: (value) {
                  if (value == 'rename') _renameCollection();
                  if (value == 'delete') _deleteCollection();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Rename'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Delete Collection', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Header Stats
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                         decoration: BoxDecoration(
                           color: Colors.grey.shade100,
                           borderRadius: BorderRadius.circular(20),
                         ),
                         child: Row(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             Icon(Icons.movie_creation_outlined, size: 16, color: Colors.grey.shade600),
                             const SizedBox(width: 6),
                             Text(
                               '${_movies.length} movies',
                               style: TextStyle(
                                 fontSize: 13,
                                 fontWeight: FontWeight.w500,
                                 color: Colors.grey.shade700,
                               ),
                             ),
                           ],
                         ),
                       ),
                       const SizedBox(width: 12),
                       // Could add more stats here like "Total Runtime" later
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Colors.black)),
            )
          else if (_movies.isEmpty)
             SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Icon(
                          Icons.folder_open_rounded,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Collection is empty",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Drag movies here from your home screen",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
             )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.55,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final movie = _movies[index];
                    return GestureDetector(
                      onLongPress: () => _removeMovie(movie),
                      child: Stack(
                        children: [
                          MovieCard(
                            movie: movie,
                            // Ensure onTap works normally if MovieCard exposes it,
                            // otherwise defaults to card behavior (likely nav to details)
                          ),
                          // Optional visual cue for long press?
                          // For now, standard behavior is fine.
                        ],
                      ),
                    );
                  },
                  childCount: _movies.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
