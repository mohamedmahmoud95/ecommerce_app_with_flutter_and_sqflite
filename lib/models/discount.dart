class Discount {
  final int? id;
  final String code;
  final double percentage;
  final DateTime expirationDate;
  final int? productId;
  final String? category;
  final double? minOrderAmount;
  final int? maxUses;
  final int usesCount;
  final bool isActive;

  Discount({
    this.id,
    required this.code,
    required this.percentage,
    required this.expirationDate,
    this.productId,
    this.category,
    this.minOrderAmount,
    this.maxUses,
    this.usesCount = 0,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'DiscountID': id,
      'Code': code,
      'Percentage': percentage,
      'ExpirationDate': expirationDate.toIso8601String(),
      'ProductID': productId,
      'Category': category,
      'MinOrderAmount': minOrderAmount,
      'MaxUses': maxUses,
      'UsesCount': usesCount,
      'IsActive': isActive ? 1 : 0,
    };
  }

  factory Discount.fromMap(Map<String, dynamic> map) {
    return Discount(
      id: map['DiscountID'],
      code: map['Code'],
      percentage: map['Percentage'] as double,
      expirationDate: DateTime.parse(map['ExpirationDate']),
      productId: map['ProductID'],
      category: map['Category'],
      minOrderAmount: map['MinOrderAmount'] as double?,
      maxUses: map['MaxUses'],
      usesCount: map['UsesCount'] ?? 0,
      isActive: map['IsActive'] == 1,
    );
  }
}
