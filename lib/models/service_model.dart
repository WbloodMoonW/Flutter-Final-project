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
      if (val is Map) {
        return val['_id']?.toString() ?? 
               val['id']?.toString() ?? 
               val['\$oid']?.toString() ?? 
               '';
      }
      return val.toString();
    }

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    bool parseBool(dynamic val) {
      if (val == null) return true;
      if (val is bool) return val;
      if (val is num) return val != 0;
      final str = val.toString().toLowerCase();
      if (str == 'true' || str == '1' || str == 'yes' || str == 'active') return true;
      if (str == 'false' || str == '0' || str == 'no' || str == 'inactive') return false;
      return true;
    }

    Map<String, double>? parsedPriceRange;
    try {
      final pr = map['priceRange'];
      if (pr != null && pr is Map) {
        parsedPriceRange = {};
        pr.forEach((k, v) {
          if (v != null) {
            parsedPriceRange![k.toString()] = parseDouble(v);
          }
        });
      }
    } catch (e) {
      // Safe fallback
    }

    List<String> parsedImages = [];
    try {
      final img = map['images'] ?? map['imageUrls'] ?? map['imageUrl'];
      if (img != null) {
        if (img is List) {
          parsedImages = img.map((e) => e.toString()).toList();
        } else if (img is String) {
          parsedImages = [img];
        }
      }
    } catch (e) {
      // Safe fallback
    }

    return WorkerService(
      id: extractId(map['_id'] ?? map['id'] ?? map['serviceId'] ?? map['serviceID']),
      name: map['name'] ?? map['title'] ?? '',
      categoryId: extractId(map['categoryId'] ?? map['categoryID'] ?? map['category']),
      workerId: extractId(map['workerID'] ?? map['workerId'] ?? map['worker']),
      description: map['description'] ?? '',
      price: parseDouble(map['price'] ?? map['cost'] ?? map['amount']),
      typeofService: map['typeOfService'] ?? map['typeofService'] ?? map['type'] ?? 'fixed',
      priceRange: parsedPriceRange,
      images: parsedImages,
      isActive: parseBool(map['active'] ?? map['isActive']),
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
