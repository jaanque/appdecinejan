import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/movie.dart';
import '../services/movie_service.dart';
import '../services/tmdb_service.dart';
import 'movie_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final MovieService _movieService = MovieService();
  final TMDBService _tmdbService = TMDBService();
  String _result = '';
  String? _posterUrl;
  bool _isLoading = false;
  List<Movie> _searchHistory = [];

  // API Key provided by the user (Groq)
  final String _apiKey = dotenv.env['GROQ_API_KEY'] ?? '';

  // TMDB Access Token
  final String _tmdbAccessToken = dotenv.env['TMDB_ACCESS_TOKEN'] ?? '';

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    // Listen to Auth State Changes to reload data if user logs in
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
       _loadSearchHistory();
    });
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

  void _showOptionsDialog(Movie movie) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  _deleteMovie(movie);
                },
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Link",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                autofocus: true,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'https://www.tiktok.com/...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onSubmitted: (_) {
                  Navigator.of(context).pop();
                  _processUrl();
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _processUrl();
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
                  'Search',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 60, 16, 0),
                    child: Row(
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
                  ),
                ),
                // 2. Action Menu
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: Row(
                      children: [
                        _buildMenuButton(
                          icon: Icons.add,
                          label: 'New',
                          onTap: _showInputDialog,
                          isPrimary: true,
                        ),
                        const SizedBox(width: 12),
                        _buildMenuButton(
                          icon: Icons.collections_bookmark_outlined,
                          label: 'Collections',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Coming Soon')),
                            );
                          },
                          isPrimary: false,
                        ),
                      ],
                    ),
                  ),
                ),
                // 3. Content (Grid or Empty State)
                if (_searchHistory.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        "Collection",
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
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => MovieDetailScreen(movie: movie),
                                  ),
                                );
                              },
                              onLongPress: () {
                                _showOptionsDialog(movie);
                              },
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Hero(
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
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.8),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                      child: Text(
                                        movie.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
