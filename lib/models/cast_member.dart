class CastMember {
  final String name;
  final String character;
  final String? profileUrl;

  CastMember({
    required this.name,
    required this.character,
    this.profileUrl,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'character': character,
        'profileUrl': profileUrl,
      };

  factory CastMember.fromJson(Map<String, dynamic> json) {
    return CastMember(
      name: json['name'] as String,
      character: json['character'] as String,
      profileUrl: json['profileUrl'] as String?,
    );
  }
}
