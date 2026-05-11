class Category {
  final String id;
  final String name;
  final String? icon;

  Category({
    required this.id,
    required this.name,
    this.icon,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    String extractId(dynamic val) {
      if (val == null) return '';
      if (val is String) return val;
      if (val is Map) return val['\$oid']?.toString() ?? val['_id']?.toString() ?? val['id']?.toString() ?? '';
      return val.toString();
    }

    return Category(
      id: extractId(json['_id'] ?? json['id']),
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
    };
  }
}
