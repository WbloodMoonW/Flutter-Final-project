class ProviderApplication {
  final String id;
  final String categoryId;
  final String bio;
  final String status; // 'pending', 'approved', 'rejected'
  final String? rejectionReason;
  final DateTime createdAt;

  ProviderApplication({
    required this.id,
    required this.categoryId,
    required this.bio,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
  });

  factory ProviderApplication.fromJson(Map<String, dynamic> json) {
    return ProviderApplication(
      id: json['_id'] ?? json['id'] ?? '',
      categoryId: json['categoryId'] ?? '',
      bio: json['bio'] ?? '',
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejectionReason'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
