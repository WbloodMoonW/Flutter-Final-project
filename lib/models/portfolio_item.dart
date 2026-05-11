class PortfolioItem {
  String title;
  String description;
  DateTime? completionDate;
  String? imageUrl;

  PortfolioItem({
    required this.title,
    required this.description,
    this.completionDate,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'completedAt': completionDate?.toIso8601String(),
    'images': imageUrl != null ? [imageUrl] : [],
  };

  factory PortfolioItem.fromMap(Map<String, dynamic> map) {
    return PortfolioItem(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      completionDate: map['completedAt'] != null ? DateTime.tryParse(map['completedAt']) : null,
      imageUrl: (map['images'] is List && (map['images'] as List).isNotEmpty) ? map['images'][0] : (map['imageUrl']),
    );
  }
}
