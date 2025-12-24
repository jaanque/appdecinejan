class Collection {
  final int? id;
  final String name;
  final DateTime? createdAt;

  Collection({
    this.id,
    required this.name,
    this.createdAt,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'] as int?,
      name: json['name'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'name': name,
    };
  }
}
