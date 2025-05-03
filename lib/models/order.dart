class Order {
  final int? id;
  final int userId;
  final DateTime date;
  final double grandTotal;
  final String status;
  final String paymentMethod;
  final List<OrderProduct>? orderProducts;

  Order({
    this.id,
    required this.userId,
    required this.date,
    required this.grandTotal,
    required this.status,
    required this.paymentMethod,
    this.orderProducts,
  });

  Map<String, dynamic> toMap() {
    return {
      'OrderID': id,
      'UserID': userId,
      'OrderDate': date.toIso8601String(),
      'TotalAmount': grandTotal,
      'Status': status,
      'PaymentMethod': paymentMethod,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['OrderID'],
      userId: map['UserID'],
      date: DateTime.parse(map['OrderDate']),
      grandTotal: map['TotalAmount'],
      status: map['Status'],
      paymentMethod: map['PaymentMethod'],
      orderProducts:
          map['OrderProducts'] != null
              ? (map['OrderProducts'] as List)
                  .map((p) => OrderProduct.fromMap(p))
                  .toList()
              : null,
    );
  }
}

class OrderProduct {
  final int orderId;
  final int productId;
  final int quantity;

  OrderProduct({
    required this.orderId,
    required this.productId,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {'OrderID': orderId, 'ProductID': productId, 'Quantity': quantity};
  }

  factory OrderProduct.fromMap(Map<String, dynamic> map) {
    return OrderProduct(
      orderId: map['OrderID'],
      productId: map['ProductID'],
      quantity: map['Quantity'],
    );
  }
}
