import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/movie.dart';
import '../services/movie_service.dart';
import 'movie_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final MovieService _movieService = MovieService();
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error guardando en la nube")));
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
Analiza el siguiente JSON de metadatos de un vídeo de TikTok: $jsonString. Tu objetivo es identificar de qué película o serie de televisión se trata basándote en el título, descripción y contexto del autor. Responde únicamente con el nombre de la película o serie. RECUERDA. RESPONDE UNICAMENTE CON EL NOMBRE QUE TIENE LA PELICULA EN EEUU Y NINGUNA LETRA MAS. Si no puedes identificarla con seguridad, responde 'No identificada'.
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
        // 3. Fetch Poster from TMDB
        posterPath = await _fetchPosterFromTMDB(client, movieName);

        // Save to history
        if (posterPath != null) {
          final newMovie = Movie(title: movieName, posterUrl: posterPath);
          await _saveSearchHistory(newMovie);
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

  Future<String?> _fetchPosterFromTMDB(HttpClient client, String query) async {
    try {
      debugPrint('Searching TMDB for: $query');
      // Use search/multi to find movies or TV shows
      final tmdbUri = Uri.parse(
          'https://api.themoviedb.org/3/search/multi?query=${Uri.encodeComponent(query)}&include_adult=false&language=en-US&page=1');

      final request = await client.getUrl(tmdbUri);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_tmdbAccessToken');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      debugPrint('TMDB Response Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(responseBody);
        debugPrint('TMDB Results count: ${(json['results'] as List?)?.length}');

        if (json['results'] != null && (json['results'] as List).isNotEmpty) {
          // Filter results to prefer movies or tv shows with posters
          final results = json['results'] as List;

          // Try to find the first result with a poster path
          var bestResult = results.firstWhere(
            (r) => r['poster_path'] != null,
            orElse: () => null,
          );

          if (bestResult != null) {
            final posterPath = bestResult['poster_path'];
            final url = 'https://image.tmdb.org/t/p/w500$posterPath';
            debugPrint('Found poster URL: $url');
            return url;
          } else {
             debugPrint('No result had a poster_path.');
          }
        } else {
          debugPrint('TMDB returned no results for query.');
        }
      } else {
         debugPrint('TMDB Error Body: $responseBody');
      }
    } catch (e) {
      debugPrint('Error fetching TMDB poster: $e');
    }
    return null;
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
                  'Buscar',
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
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: Colors.black87),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
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
          else if (_searchHistory.isNotEmpty)
            // Grid of Saved Movies
            CustomScrollView(
              slivers: [
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: Row(
                      children: [
                        _buildMenuButton(
                          icon: Icons.add,
                          label: 'Nuevo',
                          onTap: _showInputDialog,
                        ),
                        const SizedBox(width: 12),
                        _buildMenuButton(
                          icon: Icons.collections_bookmark_outlined,
                          label: 'Colecciones',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Próximamente')),
                            );
                          },
                        ),
                      ],
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
              ],
            )
          else
            // Empty State
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  const SizedBox(height: 60), // Top margin
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                  Expanded(
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
                          "¿Viste una peli en TikTok?",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Descubre el nombre al instante.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _showInputDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Identificar Película',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Result Modal / Overlay if result is present?
          // Actually, if we add to grid, we might just scroll to top or show a dialog.
          // The current logic was replacing the whole screen.
          // Let's create a temporary overlay or dialog for the Result if it's new.
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
                          "Toca para cerrar",
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
