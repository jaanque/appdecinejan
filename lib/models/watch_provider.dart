class WatchProvider {
  final int providerId;
  final String providerName;
  final String logoPath;
  final int displayPriority;

  WatchProvider({
    required this.providerId,
    required this.providerName,
    required this.logoPath,
    required this.displayPriority,
  });

  String get logoUrl => 'https://image.tmdb.org/t/p/w92$logoPath';

  factory WatchProvider.fromJson(Map<String, dynamic> json) {
    return WatchProvider(
      providerId: json['provider_id'] ?? 0,
      providerName: json['provider_name'] ?? '',
      logoPath: json['logo_path'] ?? '',
      displayPriority: json['display_priority'] ?? 0,
    );
  }
}
