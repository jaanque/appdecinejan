import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'dart:convert';
import '../models/movie.dart';
import '../models/cast_member.dart';

class TMDBService {
  final String _accessToken = dotenv.env['TMDB_ACCESS_TOKEN'] ?? '';

  Future<Movie?> searchMovie(String query) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse(
          'https://api.themoviedb.org/3/search/multi?query=${Uri.encodeComponent(query)}&include_adult=false&language=en-US&page=1');

      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_accessToken');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final json = jsonDecode(responseBody);
        final results = json['results'] as List;

        if (results.isNotEmpty) {
          // Prefer items with a poster path
          var bestResult = results.firstWhere(
            (r) => r['poster_path'] != null,
            orElse: () => results.first,
          );

          return _movieFromTMDBJson(bestResult);
        }
      }
    } catch (e) {
      debugPrint('Error searching TMDB: $e');
    } finally {
      client.close();
    }
    return null;
  }

  Future<Movie?> getMovieDetails(String title) async {
    // 1. Search for the movie to get the ID and basic info
    final basicMovie = await searchMovie(title);
    if (basicMovie == null || basicMovie.tmdbId == null) return basicMovie;

    // 2. Fetch full details using the ID
    return await _fetchFullDetails(basicMovie);
  }

  Future<Movie?> _fetchFullDetails(Movie movie) async {
    final client = HttpClient();
    try {
      final type = movie.mediaType == 'tv' ? 'tv' : 'movie';
      // Append credits to get cast info in one go
      final uri = Uri.parse(
          'https://api.themoviedb.org/3/$type/${movie.tmdbId}?language=en-US&append_to_response=credits');

      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_accessToken');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final json = jsonDecode(responseBody);

        // Parse extra details
        final int? runtime = json['runtime'] ?? (json['episode_run_time'] as List?)?.firstOrNull;
        final List<String> genres = (json['genres'] as List?)
            ?.map((g) => g['name'] as String)
            .toList() ?? [];
        final String? tagline = json['tagline'];

        final String? status = json['status'];
        final int? budget = json['budget'];
        final int? revenue = json['revenue'];

        List<CastMember> cast = [];
        if (json['credits'] != null && json['credits']['cast'] != null) {
          final castList = json['credits']['cast'] as List;
          // Take top 10 actors
          cast = castList.take(10).map((c) {
            final String? path = c['profile_path'];
            return CastMember(
              name: c['name'] ?? 'Unknown',
              character: c['character'] ?? 'Unknown',
              profileUrl: path != null ? 'https://image.tmdb.org/t/p/w185$path' : null,
            );
          }).toList();
        }

        return movie.copyWith(
          runtime: runtime,
          genres: genres,
          tagline: tagline,
          overview: json['overview'] ?? movie.overview,
          voteAverage: (json['vote_average'] as num?)?.toDouble() ?? movie.voteAverage,
          releaseDate: json['release_date'] ?? json['first_air_date'] ?? movie.releaseDate,
          status: status,
          budget: budget,
          revenue: revenue,
          cast: cast,
        );
      }
    } catch (e) {
      debugPrint('Error fetching full movie details: $e');
    } finally {
      client.close();
    }
    return movie;
  }

  Movie _movieFromTMDBJson(Map<String, dynamic> json) {
    final int? id = json['id'];
    final String title = json['title'] ?? json['name'] ?? 'Unknown Title';
    final String? posterPath = json['poster_path'];
    final String posterUrl = posterPath != null
        ? 'https://image.tmdb.org/t/p/w500$posterPath'
        : 'https://via.placeholder.com/500x750?text=No+Image';

    final String? backdropPath = json['backdrop_path'];
    final String? backdropUrl = backdropPath != null
        ? 'https://image.tmdb.org/t/p/w780$backdropPath'
        : null;

    final String overview = json['overview'] ?? '';
    final double voteAverage = (json['vote_average'] as num?)?.toDouble() ?? 0.0;
    final String releaseDate = json['release_date'] ?? json['first_air_date'] ?? '';
    final String mediaType = json['media_type'] ?? 'movie';

    return Movie(
      tmdbId: id,
      title: title,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
      overview: overview,
      voteAverage: voteAverage,
      releaseDate: releaseDate,
      mediaType: mediaType,
    );
  }
}
