class CustomerReview {
  final String customerName;
  final DateTime date;
  final double rating; // 1-5
  final String comment;

  const CustomerReview({
    required this.customerName,
    required this.date,
    required this.rating,
    required this.comment,
  });

  factory CustomerReview.fromMap(Map<String, dynamic> map) {
    return CustomerReview(
      customerName: map['customerName'] ?? 'Anonymous',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
    );
  }
}
