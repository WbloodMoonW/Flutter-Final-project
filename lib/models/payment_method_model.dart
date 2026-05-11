class PaymentMethod {
  final String id;
  final String cardNumber; // Masked from backend
  final String holder;
  final int expMonth;
  final int expYear;
  final bool isDefault;

  PaymentMethod({
    required this.id,
    required this.cardNumber,
    required this.holder,
    required this.expMonth,
    required this.expYear,
    this.isDefault = false,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['_id'] ?? json['id'] ?? '',
      cardNumber: json['cardNumber'] ?? '**** **** **** ****',
      holder: json['holder'] ?? '',
      expMonth: json['expMonth'] ?? 1,
      expYear: json['expYear'] ?? 2026,
      isDefault: json['isDefault'] ?? false,
    );
  }
}
