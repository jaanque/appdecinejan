class Movie {
  final int? id; // Supabase ID
  final String title;
  final String posterUrl;

  Movie({this.id, required this.title, required this.posterUrl});

  // Local Storage (SharedPreferences)
  Map<String, dynamic> toJson() => {
        'title': title,
        'posterUrl': posterUrl,
      };

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      title: json['title'] as String,
      posterUrl: json['posterUrl'] as String,
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
}
