import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'dart:convert';
import '../models/movie.dart';

class TMDBService {
  final String _accessToken = dotenv.env['TMDB_ACCESS_TOKEN'] ?? '';

  Future<Movie?> searchMovie(String query) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse(
          'https://api.themoviedb.org/3/search/multi?query=${Uri.encodeComponent(query)}&include_adult=false&language=es-ES&page=1');

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
    // Since we don't store ID yet, we re-search to get details.
    // Ideally we should store ID in DB. For now, this helper searches by title.
    return searchMovie(title);
  }

  Movie _movieFromTMDBJson(Map<String, dynamic> json) {
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

    return Movie(
      title: title,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
      overview: overview,
      voteAverage: voteAverage,
      releaseDate: releaseDate,
    );
  }
}
