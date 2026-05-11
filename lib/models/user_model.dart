class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role;
  final String? profileImage;
  final bool isVerified;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    this.profileImage,
    this.isVerified = false,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory User.fromJson(Map<String, dynamic> json) {
    String fName = json['firstName']?.toString() ?? '';
    String lName = json['lastName']?.toString() ?? '';
    
    if (fName.isEmpty && lName.isEmpty && json['name'] != null) {
      final parts = json['name'].toString().split(' ');
      if (parts.isNotEmpty) fName = parts[0];
      if (parts.length > 1) lName = parts.sublist(1).join(' ');
    } else if (fName.isEmpty && lName.isEmpty && json['fullName'] != null) {
      final parts = json['fullName'].toString().split(' ');
      if (parts.isNotEmpty) fName = parts[0];
      if (parts.length > 1) lName = parts.sublist(1).join(' ');
    }

    String extractId(dynamic val) {
      if (val == null) return '';
      if (val is String) return val;
      if (val is Map) return val['\$oid']?.toString() ?? val['_id']?.toString() ?? val['id']?.toString() ?? '';
      return val.toString();
    }

    return User(
      id: extractId(json['_id'] ?? json['id']),
      firstName: fName,
      lastName: lName,
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'customer',
      profileImage: json['profileImage']?.toString(),
      isVerified: json['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'role': role,
      'profileImage': profileImage,
      'isVerified': isVerified,
    };
  }
}
