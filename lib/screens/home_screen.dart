import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../widgets/collection_card.dart';

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
  List<dynamic> _gridItems = []; // Unified list
  String _currentFilter = 'All'; // 'All', 'Movies', 'Collections'

  // Selection Mode State
  bool _isSelectionMode = false;
  final Set<int> _selectedMovieIds = {};
  final Set<int> _selectedCollectionIds = {};

  // API Key provided by the user (Groq)
  final String _apiKey = dotenv.env['GROQ_API_KEY'] ?? '';

  // TMDB Access Token
  final String _tmdbAccessToken = dotenv.env['TMDB_ACCESS_TOKEN'] ?? '';

  @override
  void initState() {
    super.initState();
    _refreshData();
    // Listen to Auth State Changes to reload data if user logs in
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
       _refreshData();
    });
    // Listen to controller to update UI (suffix icon)
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final movies = await _fetchSearchHistory();
    final collections = await _fetchCollections();

    if (mounted) {
      setState(() {
        _searchHistory = movies;
        _collections = collections;
        _applyFilter();
      });
    }
  }

  void _applyFilter() {
    if (_currentFilter == 'Movies') {
      _gridItems = [..._searchHistory];
    } else if (_currentFilter == 'Collections') {
      _gridItems = [..._collections];
    } else {
      _gridItems = [..._collections, ..._searchHistory];
    }
  }

  void _setFilter(String filter) {
    setState(() {
      _currentFilter = filter;
      _applyFilter();
    });
  }

  Future<List<Collection>> _fetchCollections() async {
    return await _collectionService.getCollections();
  }

  Future<List<Movie>> _fetchSearchHistory() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      try {
        return await _movieService.getMovies();
      } catch (e) {
        debugPrint('Error loading movies from Supabase: $e');
        return [];
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString('search_history');
      if (historyJson != null) {
        final List<dynamic> decodedList = jsonDecode(historyJson);
        return decodedList.map((item) => Movie.fromJson(item)).toList();
      }
      return [];
    }
  }

  Future<void> _saveSearchHistory(Movie newMovie) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      try {
        await _movieService.saveMovie(newMovie.title, newMovie.posterUrl);
        await _refreshData();
      } catch (e) {
        debugPrint('Error saving to Supabase: $e');
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error saving to cloud")));
        }
      }
    } else {
      // Optimistic update for local storage or guest
      setState(() {
        _searchHistory.removeWhere((m) => m.title == newMovie.title);
        _searchHistory.insert(0, newMovie);
        _applyFilter();
      });

      final prefs = await SharedPreferences.getInstance();
      final String historyJson = jsonEncode(_searchHistory.map((m) => m.toJson()).toList());
      await prefs.setString('search_history', historyJson);
    }
  }

  Future<void> _deleteMovie(Movie movie) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null && movie.id != null) {
      try {
        await _movieService.deleteMovie(movie.id!);
        await _refreshData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error deleting movie')),
          );
        }
      }
    } else {
      setState(() {
        _searchHistory.removeWhere((m) => m.title == movie.title);
        _applyFilter();
      });
      final prefs = await SharedPreferences.getInstance();
      final String historyJson = jsonEncode(_searchHistory.map((m) => m.toJson()).toList());
      await prefs.setString('search_history', historyJson);
    }
  }

  Future<void> _deleteSelectedItems() async {
    final totalCount = _selectedMovieIds.length + _selectedCollectionIds.length;
    if (totalCount == 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Delete Items"),
        content: Text("Are you sure you want to delete $totalCount items?"),
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
        for (final id in _selectedCollectionIds) {
          await _collectionService.deleteCollection(id);
        }
      } else {
        // Handle local bulk delete if needed
      }

      await _refreshData();
      setState(() {
        _isSelectionMode = false;
        _selectedMovieIds.clear();
        _selectedCollectionIds.clear();
      });
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedMovieIds.clear();
      _selectedCollectionIds.clear();
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

  void _toggleCollectionSelection(int id) {
    setState(() {
      if (_selectedCollectionIds.contains(id)) {
        _selectedCollectionIds.remove(id);
      } else {
        _selectedCollectionIds.add(id);
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
                        await _refreshData();
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
    ).then((_) => _refreshData());
  }

  Future<void> _processUrl() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

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
        _controller.clear(); // Clear input on success
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

  void _handleSmartPasteOrSubmit() async {
    if (_controller.text.isEmpty) {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null) {
        setState(() {
          _controller.text = data!.text!;
        });
      }
    } else {
      _processUrl();
    }
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
                          "${_selectedMovieIds.length + _selectedCollectionIds.length} Selected",
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
                        onPressed: (_selectedMovieIds.isNotEmpty || _selectedCollectionIds.isNotEmpty)
                            ? _deleteSelectedItems
                            : null,
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
                // 2. Action Menu (Inline Search + New Filter Chips)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: TextField(
                                  controller: _controller,
                                  style: const TextStyle(fontSize: 16),
                                  decoration: InputDecoration(
                                    hintText: "Paste TikTok link...",
                                    hintStyle: TextStyle(color: Colors.grey.shade500),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                    prefixIcon: Icon(Icons.link_rounded, color: Colors.grey.shade600),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _controller.text.isEmpty ? Icons.paste_rounded : Icons.arrow_forward_rounded,
                                        color: Colors.black,
                                      ),
                                      onPressed: _handleSmartPasteOrSubmit,
                                    ),
                                  ),
                                  onSubmitted: (_) => _processUrl(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: _showCollectionDialog,
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: const Icon(
                                  Icons.create_new_folder_outlined,
                                  color: Colors.black,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Filter Chips
                        Row(
                          children: [
                            _buildFilterChip('All'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Movies'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Collections'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // 3. Content (Unified Grid)
                if (_gridItems.isNotEmpty) ...[
                  SliverPadding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.55, // Adjusted for text below image
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = _gridItems[index];

                          if (item is Collection) {
                            return CollectionCard(
                              collection: item,
                              isSelectionMode: _isSelectionMode,
                              isSelected: item.id != null && _selectedCollectionIds.contains(item.id),
                              onSelectionToggle: () {
                                if (item.id != null) {
                                  _toggleCollectionSelection(item.id!);
                                }
                              },
                              onUpdate: _refreshData,
                            );
                          } else if (item is Movie) {
                            return MovieCard(
                              movie: item,
                              isSelectionMode: _isSelectionMode,
                              isSelected: item.id != null && _selectedMovieIds.contains(item.id),
                              onSelectionToggle: () {
                                if (item.id != null) {
                                  _toggleMovieSelection(item.id!);
                                }
                              },
                              onDelete: () => _deleteMovie(item),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        childCount: _gridItems.length,
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

  Widget _buildFilterChip(String label) {
    final bool isSelected = _currentFilter == label;
    return InkWell(
      onTap: () => _setFilter(label),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
