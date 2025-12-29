import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/collection.dart';
import '../models/movie.dart';

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
      return data.map((json) => Collection.fromJson(json, currentUserId: user.id)).toList();
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      return [];
    } catch (e) {
      debugPrint('Error fetching collections: $e');
      return [];
    }
  }

  Future<List<Movie>> getMoviesInCollection(int collectionId) async {
     try {
      // Query collection_movies to get the movies for this collection
      final response = await _client
          .from('collection_movies')
          .select('user_movies(*)')
          .eq('collection_id', collectionId);

      final List<dynamic> data = response as List<dynamic>;

      return data.map((json) {
        // The structure is { user_movies: { ...movie_data... } }
        final movieData = json['user_movies'] as Map<String, dynamic>;
        return Movie.fromSupabase(movieData);
      }).toList();

    } catch (e) {
      debugPrint('Error fetching movies for collection $collectionId: $e');
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

  Future<void> renameCollection(int id, String newName) async {
    try {
      await _client.from('collections').update({'name': newName}).eq('id', id);
    } catch (e) {
      debugPrint('Error renaming collection: $e');
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

  Future<void> removeMovieFromCollection(int collectionId, int movieId) async {
    try {
      await _client
          .from('collection_movies')
          .delete()
          .eq('collection_id', collectionId)
          .eq('movie_id', movieId);
    } catch (e) {
      debugPrint('Error removing movie from collection: $e');
      rethrow;
    }
  }

  Future<String> shareCollection(int collectionId, {String? password}) async {
    // Generate unique code XXX-XXX
    final code = _generateShareCode();

    try {
      await _client.from('collections').update({
        'share_code': code,
        'share_password': password, // Ideally hashed, but storing plain as requested for MVP "password match"
      }).eq('id', collectionId);
      return code;
    } catch (e) {
      debugPrint('Error sharing collection: $e');
      rethrow;
    }
  }

  String _generateShareCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    return '${getRandomString(3)}-${getRandomString(3)}';
  }

  Future<void> joinCollection(String code, {String? password}) async {
    try {
      await _client.rpc('join_collection', params: {
        'p_share_code': code,
        'p_password': password,
      });
    } catch (e) {
      debugPrint('Error joining collection: $e');
      rethrow;
    }
  }

  Future<void> leaveCollection(int collectionId) async {
     try {
       final user = _client.auth.currentUser;
       if (user == null) return;

      await _client
          .from('collection_access')
          .delete()
          .eq('collection_id', collectionId)
          .eq('user_id', user.id);
    } catch (e) {
      debugPrint('Error leaving collection: $e');
      rethrow;
    }
  }
}
