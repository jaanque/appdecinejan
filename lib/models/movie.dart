class Movie {
  final String title;
  final String posterUrl;

  Movie({required this.title, required this.posterUrl});

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
}
