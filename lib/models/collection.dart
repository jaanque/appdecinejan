class Collection {
  final int? id;
  final String name;
  final DateTime? createdAt;
  final List<String> previewPosters;
  final String? shareCode;
  final bool isShared;

  Collection({
    this.id,
    required this.name,
    this.createdAt,
    this.previewPosters = const [],
    this.shareCode,
    this.isShared = false,
  });

  factory Collection.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    List<String> posters = [];
    if (json['collection_movies'] != null && (json['collection_movies'] is List)) {
      final moviesData = json['collection_movies'] as List;
      for (var item in moviesData) {
        if (item is Map &&
            item['user_movies'] != null &&
            item['user_movies'] is Map &&
            item['user_movies']['poster_url'] != null) {
          posters.add(item['user_movies']['poster_url'].toString());
        }
      }
    }

    // Determine isShared safely
    bool shared = false;
    if (currentUserId != null && json['user_id'] != null) {
      final String ownerId = json['user_id'].toString();
      shared = ownerId != currentUserId;
    }

    return Collection(
      id: json['id'] as int?,
      name: json['name'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      previewPosters: List<String>.from(posters),
      shareCode: json['share_code'] as String?,
      isShared: shared,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'name': name,
    };
  }
}
