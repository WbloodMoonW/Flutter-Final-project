import 'user_model.dart';

class Order {
  final String id;
  final User? customer;
  final String? workerId;
  final String? serviceId;
  final String? serviceTitle;
  final double price;
  final String status;
  final DateTime? scheduledFor;
  final String? address;
  final DateTime createdAt;

  Order({
    required this.id,
    this.customer,
    this.workerId,
    this.serviceId,
    this.serviceTitle,
    required this.price,
    required this.status,
    this.scheduledFor,
    this.address,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    String extractId(dynamic val) {
      if (val == null) return '';
      if (val is String) return val;
      if (val is Map) return val['\$oid']?.toString() ?? val['_id']?.toString() ?? val['id']?.toString() ?? '';
      return val.toString();
    }

    String? extractAddress(Map<String, dynamic> json) {
      final addr = json['address'] ?? json['location'];
      if (addr == null) return null;
      if (addr is String) return addr;
      if (addr is Map) {
        return addr['address']?.toString() ?? addr['label']?.toString() ?? addr['fullAddress']?.toString();
      }
      return addr.toString();
    }

    String extractTitle(Map<String, dynamic> json) {
      if (json['serviceTitle'] != null && json['serviceTitle'].toString().isNotEmpty) return json['serviceTitle'].toString();
      if (json['service'] is Map) {
        return json['service']['name']?.toString() ?? json['service']['title']?.toString() ?? 'Service';
      }
      if (json['category'] is Map) {
        return json['category']['name']?.toString() ?? json['category']['title']?.toString() ?? 'Service';
      }
      if (json['serviceId'] is Map) {
        return json['serviceId']['name']?.toString() ?? json['serviceId']['title']?.toString() ?? 'Service';
      }
      return 'Service';
    }

    double extractPrice(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is Map) {
        if (val.containsKey('\$numberInt')) return double.tryParse(val['\$numberInt'].toString()) ?? 0.0;
        if (val.containsKey('\$numberDouble')) return double.tryParse(val['\$numberDouble'].toString()) ?? 0.0;
      }
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return Order(
      id: extractId(json['_id'] ?? json['id']),
      customer: json['customer'] != null ? User.fromJson(json['customer']) : null,
      workerId: extractId(json['workerId'] ?? json['worker']),
      serviceId: extractId(json['serviceId'] ?? json['service']),
      serviceTitle: extractTitle(json),
      price: extractPrice(
        json['price'] ?? 
        json['totalPrice'] ?? 
        json['amount'] ?? 
        json['cost'] ?? 
        (json['service'] is Map ? json['service']['price'] : null) ??
        (json['serviceId'] is Map ? json['serviceId']['price'] : null)
      ),
      status: json['status']?.toString() ?? 'pending',
      scheduledFor: json['scheduledFor'] != null 
          ? (json['scheduledFor'] is Map 
              ? DateTime.fromMillisecondsSinceEpoch(int.tryParse(json['scheduledFor']['\$date']?.toString() ?? '0') ?? 0)
              : DateTime.tryParse(json['scheduledFor'].toString()))
          : null,
      address: extractAddress(json),
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] is Map 
              ? DateTime.fromMillisecondsSinceEpoch(int.tryParse(json['createdAt']['\$date']?.toString() ?? '0') ?? 0)
              : DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
