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
  String _currentName = '';

  @override
  void initState() {
    super.initState();
    _currentName = widget.collection.name;
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    if (widget.collection.id == null) return;

    setState(() => _isLoading = true);
    try {
      final movies = await _collectionService.getMoviesInCollection(widget.collection.id!);
      if (mounted) {
        setState(() {
          _movies = movies;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteCollection() async {
    if (widget.collection.id == null) return;

    final bool? confirmed = await showDialog<bool>(
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

  Future<void> _shareCollection() async {
    if (widget.collection.id == null) return;

    String? currentShareCode = widget.collection.shareCode;

    await showDialog(
      context: context,
      builder: (context) {
        bool hasPassword = false;
        final passController = TextEditingController();
        String? generatedCode = currentShareCode;
        bool isGenerating = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                   Icon(Icons.share_rounded, size: 24),
                   SizedBox(width: 12),
                   Text('Share Collection'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (generatedCode != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "ACCESS CODE",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            generatedCode!,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Share this code with others to let them join this collection.",
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ] else ...[
                     const Text("Create a unique access code to share this collection."),
                     const SizedBox(height: 24),
                     Row(
                       children: [
                         Checkbox(
                           value: hasPassword,
                           activeColor: Colors.black,
                           onChanged: (bool? val) => setState(() => hasPassword = val == true),
                         ),
                         const Text("Require Password"),
                       ],
                     ),
                     if (hasPassword)
                       TextField(
                         controller: passController,
                         obscureText: true,
                         decoration: const InputDecoration(
                           hintText: 'Enter password',
                           border: OutlineInputBorder(),
                           contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                         ),
                       ),
                  ],
                ],
              ),
              actions: [
                if (generatedCode == null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isGenerating ? null : () async {
                        setState(() => isGenerating = true);
                        try {
                          final code = await _collectionService.shareCollection(
                            widget.collection.id!,
                            password: hasPassword && passController.text.isNotEmpty
                                ? passController.text
                                : null
                          );
                          setState(() {
                             generatedCode = code;
                             isGenerating = false;
                          });
                        } catch (e) {
                          setState(() => isGenerating = false);
                          // Show error
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isGenerating
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Generate Code"),
                    ),
                  )
                else
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Done", style: TextStyle(color: Colors.black)),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _renameCollection() async {
    if (widget.collection.id == null) return;

    final TextEditingController controller = TextEditingController(text: _currentName);

    final String? newName = await showDialog<String>(
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

    final bool? confirmed = await showModalBottomSheet<bool>(
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
            // Replaced BackButton with explicit IconButton to avoid implicit Navigator.maybePop issues
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              _currentName,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              if (!widget.collection.isShared) // Only owner can share/rename/delete
                IconButton(
                  onPressed: _shareCollection,
                  icon: const Icon(Icons.share_rounded, color: Colors.black),
                  tooltip: 'Share Collection',
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded, color: Colors.black),
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
                onSelected: (String value) {
                  if (value == 'rename') {
                    _renameCollection();
                  } else if (value == 'delete') {
                    _deleteCollection();
                  } else if (value == 'leave') {
                     _collectionService.leaveCollection(widget.collection.id!).then((_) {
                       if (mounted) Navigator.pop(context, true);
                     });
                  }
                },
                // Explicitly typed return
                itemBuilder: (BuildContext context) {
                  if (widget.collection.isShared) {
                    return <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'leave',
                        child: Row(
                          children: [
                            Icon(Icons.exit_to_app_rounded, size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Leave Collection', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ];
                  }
                  return <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Rename'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Delete Collection', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ];
                },
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
                          ),
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
