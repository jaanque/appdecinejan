class Movie {
  final int? id; // Supabase ID
  final int? tmdbId; // TMDB ID
  final String title;
  final String posterUrl;

  // Extended details
  final String? backdropUrl;
  final String? overview;
  final double? voteAverage;
  final String? releaseDate;
  final String? mediaType; // 'movie' or 'tv'
  final int? runtime; // in minutes
  final List<String>? genres;
  final String? tagline;

  Movie({
    this.id,
    this.tmdbId,
    required this.title,
    required this.posterUrl,
    this.backdropUrl,
    this.overview,
    this.voteAverage,
    this.releaseDate,
    this.mediaType,
    this.runtime,
    this.genres,
    this.tagline,
  });

  // Local Storage (SharedPreferences)
  Map<String, dynamic> toJson() => {
        'tmdbId': tmdbId,
        'title': title,
        'posterUrl': posterUrl,
        'backdropUrl': backdropUrl,
        'overview': overview,
        'voteAverage': voteAverage,
        'releaseDate': releaseDate,
        'mediaType': mediaType,
        'runtime': runtime,
        'genres': genres,
        'tagline': tagline,
      };

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      tmdbId: json['tmdbId'] as int?,
      title: json['title'] as String,
      posterUrl: json['posterUrl'] as String,
      backdropUrl: json['backdropUrl'] as String?,
      overview: json['overview'] as String?,
      voteAverage: (json['voteAverage'] as num?)?.toDouble(),
      releaseDate: json['releaseDate'] as String?,
      mediaType: json['mediaType'] as String?,
      runtime: json['runtime'] as int?,
      genres: (json['genres'] as List?)?.map((e) => e as String).toList(),
      tagline: json['tagline'] as String?,
    );
  }

  // Supabase
  Map<String, dynamic> toSupabase() => {
        'title': title,
        'poster_url': posterUrl,
      };

  factory Movie.fromSupabase(Map<String, dynamic> map) {
    return Movie(
      id: map['id'] as int?,
      title: map['title'] as String,
      posterUrl: map['poster_url'] as String,
    );
  }

  Movie copyWith({
    int? id,
    int? tmdbId,
    String? title,
    String? posterUrl,
    String? backdropUrl,
    String? overview,
    double? voteAverage,
    String? releaseDate,
    String? mediaType,
    int? runtime,
    List<String>? genres,
    String? tagline,
  }) {
    return Movie(
      id: id ?? this.id,
      tmdbId: tmdbId ?? this.tmdbId,
      title: title ?? this.title,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      overview: overview ?? this.overview,
      voteAverage: voteAverage ?? this.voteAverage,
      releaseDate: releaseDate ?? this.releaseDate,
      mediaType: mediaType ?? this.mediaType,
      runtime: runtime ?? this.runtime,
      genres: genres ?? this.genres,
      tagline: tagline ?? this.tagline,
    );
  }
}
