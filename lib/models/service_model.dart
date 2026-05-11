class WorkerService {
  String? id;
  String name;
  String categoryId;
  String? workerId;
  String description;
  double price;
  String typeofService; // 'fixed', 'hourly', 'range'
  Map<String, double>? priceRange; // { 'min': 0, 'max': 0 }
  List<String> images;
  bool isActive;

  WorkerService({
    this.id,
    required this.name,
    required this.categoryId,
    this.workerId,
    required this.description,
    required this.price,
    required this.typeofService,
    this.priceRange,
    this.images = const [],
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'categoryId': categoryId,
    if (workerId != null) 'workerID': workerId,
    'description': description,
    'price': price,
    'typeOfService': typeofService,
    if (priceRange != null) 'priceRange': {
      'min': priceRange!['min'],
      'max': priceRange!['max'],
    },
    'images': images,
    'active': isActive,
  };

  factory WorkerService.fromMap(Map<String, dynamic> map) {
    String extractId(dynamic val) {
      if (val == null) return '';
      if (val is String) return val;
      if (val is Map) return val['\$oid']?.toString() ?? val['_id']?.toString() ?? val['id']?.toString() ?? '';
      return val.toString();
    }

    return WorkerService(
      id: extractId(map['_id'] ?? map['id']),
      name: map['name'] ?? map['title'] ?? '',
      categoryId: extractId(map['categoryId'] ?? map['category']),
      workerId: extractId(map['workerID'] ?? map['workerId']),
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      typeofService: map['typeOfService'] ?? map['typeofService'] ?? 'fixed',
      priceRange: map['priceRange'] != null ? Map<String, double>.from(map['priceRange'].map((k, v) => MapEntry(k, v.toDouble()))) : null,
      images: List<String>.from(map['images'] ?? []),
      isActive: map['active'] ?? map['isActive'] ?? true,
    );
  }

  String get title => name;

  WorkerService copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? workerId,
    String? description,
    double? price,
    String? typeofService,
    Map<String, double>? priceRange,
    List<String>? images,
    bool? isActive,
  }) {
    return WorkerService(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      workerId: workerId ?? this.workerId,
      description: description ?? this.description,
      price: price ?? this.price,
      typeofService: typeofService ?? this.typeofService,
      priceRange: priceRange ?? this.priceRange,
      images: images ?? this.images,
      isActive: isActive ?? this.isActive,
    );
  }
}
