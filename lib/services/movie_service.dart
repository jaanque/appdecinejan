import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/movie.dart';

class MovieService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Movie>> getMovies() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Fetch movies and their collection associations using a left join.
      // We select 'collection_movies(id)' to check if a movie is part of any collection.
      final response = await _supabase
          .from('user_movies')
          .select('*, collection_movies(id)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;

      // Client-side filtering: Exclude movies that have associated collection entries.
      // Note: Supabase/PostgREST doesn't support a direct "WHERE id NOT IN (SELECT ...)"
      // or "filter by empty relation" easily in the JS/Dart client without RPCs or complex raw queries.
      // For the expected data volume of a personal movie list, this client-side filter is efficient enough.
      final uncollectedMovies = data.where((json) {
        final collections = json['collection_movies'] as List<dynamic>?;
        return collections == null || collections.isEmpty;
      }).toList();

      return uncollectedMovies.map((json) => Movie.fromSupabase(json)).toList();
    } catch (e) {
      // Handle error or rethrow
      return [];
    }
  }

  Future<void> saveMovie(Movie movie) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('user_movies').insert({
      ...movie.toSupabase(),
      'user_id': userId,
    });
  }

  Future<void> deleteMovie(int id) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase
        .from('user_movies')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }
}
