import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/movie.dart';

class AIService {
  final String _apiKey = dotenv.env['GROQ_API_KEY'] ?? '';

  Future<String?> identifyMovieFromTikTok(String tiktokUrl) async {
    // Logic extracted from HomeScreen, simplified
    // ... (This part is used in HomeScreen, I'll prioritize recommendation for now)
    // For now I'll just implement the recommendation part.
    return null;
  }

  Future<String?> getRecommendation(List<Movie> userMovies) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      final recentMovies = userMovies.take(5).map((m) => "${m.title} (${m.genres?.join(', ') ?? ''})").join(", ");
      final excludeList = userMovies.map((m) => m.title).join(", ");

      final prompt = '''
      Based on the following movies the user likes: $recentMovies.
      Recommend ONE single movie that they would likely enjoy.
      Do NOT recommend any of these movies: $excludeList.
      Respond ONLY with the official English title of the recommended movie.
      Do not include any punctuation, quotes, or extra text.
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

      final request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_apiKey');
      request.add(utf8.encode(jsonEncode(requestBody)));

      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final json = jsonDecode(responseBody);

        if (json['choices'] != null && (json['choices'] as List).isNotEmpty) {
          final content = json['choices'][0]['message']['content'];
          return content.toString().trim();
        }
      }
    } catch (e) {
      debugPrint('AI Recommendation Error: $e');
    } finally {
      client.close();
    }
    return null;
  }
}
