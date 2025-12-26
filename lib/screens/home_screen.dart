import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/movie.dart';
import '../models/collection.dart';
import '../services/movie_service.dart';
import '../services/collection_service.dart';
import '../services/tmdb_service.dart';
import 'movie_detail_screen.dart';
import 'collection_detail_screen.dart';
import '../widgets/movie_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final MovieService _movieService = MovieService();
  final CollectionService _collectionService = CollectionService();
  final TMDBService _tmdbService = TMDBService();
  String _result = '';
  String? _posterUrl;
  bool _isLoading = false;
  List<Movie> _searchHistory = [];
  List<Collection> _collections = [];

  // Selection Mode State
  bool _isSelectionMode = false;
  final Set<int> _selectedMovieIds = {};

  // API Key provided by the user (Groq)
  final String _apiKey = dotenv.env['GROQ_API_KEY'] ?? '';

  // TMDB Access Token
  final String _tmdbAccessToken = dotenv.env['TMDB_ACCESS_TOKEN'] ?? '';

  @override
  void initState() {
    super.initState();
    _loadData();
    // Listen to Auth State Changes to reload data if user logs in
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
       _loadData();
    });
  }

  Future<void> _loadData() async {
    await _loadSearchHistory();
    await _loadCollections();
  }

  Future<void> _loadCollections() async {
    final cols = await _collectionService.getCollections();
    if (mounted) {
      setState(() {
        _collections = cols;
      });
    }
  }

  Future<void> _loadSearchHistory() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      // 1. Fetch from Supabase if logged in
      try {
        final movies = await _movieService.getMovies();
        if (mounted) {
          setState(() {
            _searchHistory = movies;
          });
        }
      } catch (e) {
        debugPrint('Error loading movies from Supabase: $e');
        // Fallback or show error? For now, silent fail or maybe fallback to local
      }
    } else {
      // 2. Fetch from SharedPreferences if guest
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString('search_history');
      if (historyJson != null) {
        final List<dynamic> decodedList = jsonDecode(historyJson);
        if (mounted) {
          setState(() {
            _searchHistory = decodedList.map((item) => Movie.fromJson(item)).toList();
          });
        }
      } else {
        if (mounted) {
           setState(() {
            _searchHistory = [];
          });
        }
      }
    }
  }

  Future<void> _saveSearchHistory(Movie newMovie) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      // 1. Save to Supabase
      try {
        await _movieService.saveMovie(newMovie.title, newMovie.posterUrl);
        // Reload to get the new ID and correct order, or just manually insert to list
        // Re-fetching is safer for consistency
        await _loadSearchHistory();
      } catch (e) {
        debugPrint('Error saving to Supabase: $e');
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error saving to cloud")));
        }
      }
    } else {
      // 2. Save to SharedPreferences
      setState(() {
        _searchHistory.removeWhere((m) => m.title == newMovie.title);
        _searchHistory.insert(0, newMovie);
      });

      final prefs = await SharedPreferences.getInstance();
      final String historyJson = jsonEncode(_searchHistory.map((m) => m.toJson()).toList());
      await prefs.setString('search_history', historyJson);
    }
  }

  Future<void> _deleteMovie(Movie movie) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null && movie.id != null) {
      // Delete from Supabase
      try {
        await _movieService.deleteMovie(movie.id!);
        await _loadSearchHistory(); // Refresh list
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error deleting movie')),
          );
        }
      }
    } else {
      // Delete from Local Storage
      setState(() {
        _searchHistory.removeWhere((m) => m.title == movie.title);
      });
      final prefs = await SharedPreferences.getInstance();
      final String historyJson = jsonEncode(_searchHistory.map((m) => m.toJson()).toList());
      await prefs.setString('search_history', historyJson);
    }
  }

  Future<void> _deleteSelectedMovies() async {
    if (_selectedMovieIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Delete Movies"),
        content: Text("Are you sure you want to delete ${_selectedMovieIds.length} items?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        for (final id in _selectedMovieIds) {
          await _movieService.deleteMovie(id);
        }
      } else {
        // Local storage deletion logic
        setState(() {
           // This assumes local movies have temporary negative IDs or handle by title if needed
           // For simplicity in this demo, we mainly handle cloud deletion via ID
           // If local, we might need a better ID strategy, but here we assume Supabase mainly.
        });
      }

      await _loadSearchHistory();
      setState(() {
        _isSelectionMode = false;
        _selectedMovieIds.clear();
      });
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedMovieIds.clear();
    });
  }

  void _toggleMovieSelection(int id) {
    setState(() {
      if (_selectedMovieIds.contains(id)) {
        _selectedMovieIds.remove(id);
      } else {
        _selectedMovieIds.add(id);
      }
    });
  }

  void _showCollectionDialog() {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Center(
            child: Text(
              "New Collection",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: nameController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: 'Collection name',
                    border: InputBorder.none,
                    icon: Icon(Icons.folder_open_rounded, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      try {
                        await _collectionService.createCollection(name);
                        await _loadCollections();
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        // Handle error
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Create Collection",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processUrl() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isLoading = true;
      _result = '';
      _posterUrl = null;
    });

    debugPrint('Processing URL: $url');

    final client = HttpClient();
    try {
      // 1. Extraction of Metadata (JSON)
      // We use the public oembed endpoint
      final oembedUri = Uri.parse('https://www.tiktok.com/oembed?url=$url');
      debugPrint('Fetching oEmbed from: $oembedUri');

      final oembedRequest = await client.getUrl(oembedUri);
      final oembedResponse = await oembedRequest.close();

      if (oembedResponse.statusCode != 200) {
        debugPrint('TikTok oEmbed failed with status: ${oembedResponse.statusCode}');
        throw Exception('Error fetching TikTok metadata: ${oembedResponse.statusCode}');
      }

      final jsonString = await oembedResponse.transform(utf8.decoder).join();
      debugPrint('TikTok Metadata: $jsonString');

      // 2. Consultation with AI via REST API
      // Endpoint: https://api.groq.com/openai/v1/chat/completions
      final groqUri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      final prompt = '''
Analyze the following JSON metadata from a TikTok video: $jsonString. Your goal is to identify the movie or TV show based on the title, description, and context. Respond ONLY with the name of the movie or TV show. REMEMBER: RESPOND ONLY WITH THE OFFICIAL US TITLE AND NO OTHER TEXT. If you cannot identify it with certainty, respond 'No identificada'.
''';

      final requestBody = {
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {
            'role': 'user',
            'content': prompt
          }
        ]
      };

      debugPrint('Sending prompt to Groq...');
      final groqRequest = await client.postUrl(groqUri);
      groqRequest.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      groqRequest.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_apiKey');
      groqRequest.add(utf8.encode(jsonEncode(requestBody)));

      final groqResponse = await groqRequest.close();
      final groqResponseBody = await groqResponse.transform(utf8.decoder).join();
      debugPrint('Groq Response: $groqResponseBody');

      if (groqResponse.statusCode != 200) {
        throw Exception('Error from Groq API: $groqResponseBody');
      }

      final groqJson = jsonDecode(groqResponseBody);

      String? aiText;
      if (groqJson['choices'] != null &&
          (groqJson['choices'] as List).isNotEmpty) {
        final choice = groqJson['choices'][0];
        if (choice['message'] != null &&
            choice['message']['content'] != null) {
          aiText = choice['message']['content'];
        }
      }

      final movieName = aiText ?? 'No valid response from AI';
      debugPrint('AI identified movie: $movieName');

      String? posterPath;
      if (movieName != 'No identificada' && !movieName.contains('No valid response')) {
        // 3. Fetch Full Details from TMDB using Service
        final movieDetails = await _tmdbService.searchMovie(movieName);

        if (movieDetails != null) {
          posterPath = movieDetails.posterUrl;
          await _saveSearchHistory(movieDetails);
        }
      }

      setState(() {
        _result = movieName;
        _posterUrl = posterPath;
      });

    } catch (e) {
      debugPrint('Error caught: $e');
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      client.close();
      setState(() {
        _isLoading = false;
      });
    }
  }


  void _showInputDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Paste TikTok link...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
                      ),
                      onSubmitted: (_) {
                        Navigator.of(context).pop();
                        _processUrl();
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _processUrl();
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isPrimary ? Colors.black : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isPrimary ? Colors.black : Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: isPrimary ? Colors.white : Colors.black87),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isPrimary ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main Content
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 2,
              ),
            )
          else
            CustomScrollView(
              slivers: [
                // 1. Header
                SliverAppBar(
                  floating: true,
                  pinned: false,
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  titleSpacing: 16,
                  leading: _isSelectionMode
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.black),
                          onPressed: _toggleSelectionMode,
                        )
                      : null,
                  title: _isSelectionMode
                      ? Text(
                          "${_selectedMovieIds.length} Selected",
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        )
                      : Row(
                          children: [
                            Icon(Icons.movie_filter_rounded, size: 32, color: Colors.black),
                            const SizedBox(width: 12),
                            const Text(
                              "loremipsum",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                  actions: [
                    if (_isSelectionMode)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: _selectedMovieIds.isNotEmpty ? _deleteSelectedMovies : null,
                      )
                    else
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.black),
                        onSelected: (value) {
                          if (value == 'delete') {
                            _toggleSelectionMode();
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete items'),
                            ),
                          ];
                        },
                      ),
                  ],
                ),
                // 2. Action Menu
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    child: Row(
                      children: [
                        _buildMenuButton(
                          icon: Icons.add,
                          label: 'New film',
                          onTap: _showInputDialog,
                          isPrimary: true,
                        ),
                        const SizedBox(width: 12),
                        _buildMenuButton(
                          icon: Icons.collections_bookmark_outlined,
                          label: 'New collection',
                          onTap: _showCollectionDialog,
                          isPrimary: false,
                        ),
                      ],
                    ),
                  ),
                ),
                // 3. Content (Collections + Grid or Empty State)
                if (_collections.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Container(
                      height: 130,
                      margin: const EdgeInsets.only(bottom: 20),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _collections.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final collection = _collections[index];
                          return DragTarget<Movie>(
                            onWillAccept: (movie) => true,
                            onAccept: (movie) async {
                              if (collection.id != null && movie.id != null) {
                                try {
                                  await _collectionService.addMovieToCollection(collection.id!, movie.id!);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Added to ${collection.name}")),
                                  );
                                  _loadCollections(); // Update counts if implemented
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CollectionDetailScreen(collection: collection),
                                    ),
                                  );
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 150,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isHovered ? Colors.blue.shade50 : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isHovered ? Colors.blue : Colors.grey.shade100,
                                      width: isHovered ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isHovered ? Colors.blue.withOpacity(0.1) : Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          isHovered ? Icons.add_to_photos_rounded : Icons.folder_special_rounded,
                                          color: isHovered ? Colors.blue : Colors.black87,
                                          size: 24,
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            collection.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: isHovered ? Colors.blue.shade900 : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "0 items", // Placeholder count
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isHovered ? Colors.blue.shade300 : Colors.grey.shade500,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],

                if (_searchHistory.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        "History", // Renamed from "Collection" to avoid confusion
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7, // Movie poster ratio
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final movie = _searchHistory[index];
                          return MovieCard(
                            movie: movie,
                            isSelectionMode: _isSelectionMode,
                            isSelected: movie.id != null && _selectedMovieIds.contains(movie.id),
                            onSelectionToggle: () {
                              if (movie.id != null) {
                                _toggleMovieSelection(movie.id!);
                              }
                            },
                            // Pass default delete/tap behavior which MovieCard uses if NOT in selection mode
                            onDelete: () => _deleteMovie(movie),
                          );
                        },
                        childCount: _searchHistory.length,
                      ),
                    ),
                  ),
                ] else
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.movie_creation_outlined,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "Seen a movie on TikTok?",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Find the title instantly.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

          // Result Modal / Overlay if result is present?
          if (_result.isNotEmpty && !_isLoading && _posterUrl != null)
             Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _result = ''; // Close overlay
                  });
                },
                child: Container(
                  color: Colors.black.withOpacity(0.8),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          constraints: const BoxConstraints(maxHeight: 450, maxWidth: 300),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Image.network(_posterUrl!),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _result,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        const Text(
                          "Tap to close",
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
