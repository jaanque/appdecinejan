import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/movie.dart';

class MovieService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Movie>> getMovies() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('user_movies')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      return data.map((json) => Movie.fromSupabase(json)).toList();
    } catch (e) {
      // Handle error or rethrow
      return [];
    }
  }

  Future<void> saveMovie(String title, String posterUrl) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final movie = Movie(title: title, posterUrl: posterUrl);

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
