class Cart {
  final int? cartId;
  final int userId;
  final List<CartProduct>? cartProducts;

  Cart({this.cartId, required this.userId, this.cartProducts});

  Map<String, dynamic> toMap() {
    return {'CartID': cartId, 'User_ID': userId};
  }

  factory Cart.fromMap(Map<String, dynamic> map) {
    return Cart(cartId: map['CartID'], userId: map['User_ID']);
  }
}

class CartProduct {
  final int cartId;
  final int productId;
  final int quantity;

  CartProduct({
    required this.cartId,
    required this.productId,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {'CartID': cartId, 'ProductID': productId, 'Quantity': quantity};
  }

  factory CartProduct.fromMap(Map<String, dynamic> map) {
    return CartProduct(
      cartId: map['CartID'],
      productId: map['ProductID'],
      quantity: map['Quantity'],
    );
  }
}
