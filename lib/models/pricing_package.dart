class PricingPackage {
  String title;
  String? price; // null = custom price
  String description;
  List<String> features;

  PricingPackage({
    required this.title,
    this.price,
    required this.description,
    required this.features,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'price': price,
    'description': description,
    'features': features,
  };

  factory PricingPackage.fromMap(Map<String, dynamic> map) {
    return PricingPackage(
      title: map['title'] ?? '',
      price: map['price']?.toString(),
      description: map['description'] ?? '',
      features: List<String>.from(map['features'] ?? []),
    );
  }
}
