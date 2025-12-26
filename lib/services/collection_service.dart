import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/collection.dart';

class CollectionService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> createCollection(String name) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      await _client.from('collections').insert({
        'user_id': user.id,
        'name': name,
      }).select();
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      rethrow;
    } catch (e) {
      debugPrint('Error creating collection: $e');
      rethrow;
    }
  }

  Future<List<Collection>> getCollections() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _client
          .from('collections')
          .select('*, collection_movies(user_movies(poster_url))')
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => Collection.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      return [];
    } catch (e) {
      debugPrint('Error fetching collections: $e');
      return [];
    }
  }

  void _handlePostgrestError(PostgrestException e) {
    if (e.code == 'PGRST205' || e.message.contains('Could not find the table')) {
      debugPrint(
          'CRITICAL ERROR: Table "collections" not found in Supabase schema cache.\n'
          'SOLUTION: Run the following SQL command in your Supabase SQL Editor:\n'
          "NOTIFY pgrst, 'reload schema';");
    } else {
      debugPrint('Postgrest Error: ${e.message} (Code: ${e.code})');
    }
  }

  Future<void> deleteCollection(int id) async {
    try {
      await _client.from('collections').delete().eq('id', id);
    } catch (e) {
      debugPrint('Error deleting collection: $e');
      rethrow;
    }
  }

  Future<void> addMovieToCollection(int collectionId, int movieId) async {
    try {
      await _client.from('collection_movies').insert({
        'collection_id': collectionId,
        'movie_id': movieId,
      });
    } on PostgrestException catch (e) {
      // Ignore unique violation (already exists)
      if (e.code == '23505') return;
      debugPrint('Error adding movie to collection: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error adding movie to collection: $e');
      rethrow;
    }
  }
}
