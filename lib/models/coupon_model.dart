class Coupon {
  final String id;
  final String code;
  final String type; // 'fixed' or 'percent'
  final double value;
  final DateTime? expiresAt;
  final bool isActive;

  Coupon({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    this.expiresAt,
    this.isActive = true,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    // Check various common keys for the discount type
    String dType = (json['discountType'] ?? json['type'] ?? 'percent').toString().toLowerCase();
    if (dType == 'fixed' || dType.contains('fixed')) dType = 'fixed';
    else dType = 'percent';

    double dValue = 0.0;
    // Check all possible keys for the discount value from both DB and API
    final rawValue = json['discountValue'] ?? json['value'] ?? json['percent'] ?? json['percentage'] ?? 0;
    if (rawValue is num) {
      dValue = rawValue.toDouble();
    } else if (rawValue is String) {
      dValue = double.tryParse(rawValue) ?? 0.0;
    }

    return Coupon(
      id: json['_id'] ?? json['id'] ?? '',
      code: json['code'] ?? '',
      type: dType,
      value: dValue,
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      isActive: json['status'] == 'active' || (json['isActive'] ?? true),
    );
  }
}
