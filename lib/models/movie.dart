class Movie {
  final int? id; // Supabase ID
  final String title;
  final String posterUrl;

  // Extended details
  final String? backdropUrl;
  final String? overview;
  final double? voteAverage;
  final String? releaseDate;

  Movie({
    this.id,
    required this.title,
    required this.posterUrl,
    this.backdropUrl,
    this.overview,
    this.voteAverage,
    this.releaseDate,
  });

  // Local Storage (SharedPreferences)
  Map<String, dynamic> toJson() => {
        'title': title,
        'posterUrl': posterUrl,
        'backdropUrl': backdropUrl,
        'overview': overview,
        'voteAverage': voteAverage,
        'releaseDate': releaseDate,
      };

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      title: json['title'] as String,
      posterUrl: json['posterUrl'] as String,
      backdropUrl: json['backdropUrl'] as String?,
      overview: json['overview'] as String?,
      voteAverage: (json['voteAverage'] as num?)?.toDouble(),
      releaseDate: json['releaseDate'] as String?,
    );
  }

  // Supabase
  // Note: We are currently only storing title and poster_url in the DB schema.
  // Extended details will be lost on DB load unless we update schema.
  // For now, we will handle this gracefully.
  Map<String, dynamic> toSupabase() => {
        'title': title,
        'poster_url': posterUrl,
        // 'backdrop_url': backdropUrl, // Needs schema update
        // 'overview': overview,       // Needs schema update
        // 'vote_average': voteAverage,// Needs schema update
        // 'release_date': releaseDate,// Needs schema update
      };

  factory Movie.fromSupabase(Map<String, dynamic> map) {
    return Movie(
      id: map['id'] as int?,
      title: map['title'] as String,
      posterUrl: map['poster_url'] as String,
      // Extended fields will be null when loaded from DB until schema is updated
    );
  }

  Movie copyWith({
    int? id,
    String? title,
    String? posterUrl,
    String? backdropUrl,
    String? overview,
    double? voteAverage,
    String? releaseDate,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      overview: overview ?? this.overview,
      voteAverage: voteAverage ?? this.voteAverage,
      releaseDate: releaseDate ?? this.releaseDate,
    );
  }
}
