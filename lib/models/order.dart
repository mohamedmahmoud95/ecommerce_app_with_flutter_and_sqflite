class Order {
  final int? orderId;
  final int userId;
  final String date;
  final double grandTotal;
  final String status;
  final String paymentMethod;
  final List<OrderProduct>? orderProducts;

  Order({
    this.orderId,
    required this.userId,
    required this.date,
    required this.grandTotal,
    required this.status,
    required this.paymentMethod,
    this.orderProducts,
  });

  Map<String, dynamic> toMap() {
    return {
      'OrderID': orderId,
      'User_ID': userId,
      'Date': date,
      'GrandTotal': grandTotal,
      'Status': status,
      'PaymentMethod': paymentMethod,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      orderId: map['OrderID'],
      userId: map['User_ID'],
      date: map['Date'],
      grandTotal: map['GrandTotal'],
      status: map['Status'],
      paymentMethod: map['PaymentMethod'],
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
