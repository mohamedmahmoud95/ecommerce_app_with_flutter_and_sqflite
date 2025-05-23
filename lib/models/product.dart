class Product {
  final int? id;
  final String name;
  final String? description;
  final double price;
  final int amount;
  final String category;
  final String? size;
  final String? color;
  final int? supplierId;

  Product({
    this.id,
    required this.name,
    this.description,
    required this.price,
    required this.amount,
    required this.category,
    this.size,
    this.color,
    this.supplierId,
  });

  Map<String, dynamic> toMap() {
    return {
      'ProductID': id,
      'Name': name,
      'Description': description,
      'Price': price,
      'Amount': amount,
      'Category': category,
      'Size': size,
      'Color': color,
      'SupplierID': supplierId,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['ProductID'],
      name: map['Name'],
      description: map['Description'],
      price: map['Price'],
      amount: map['Amount'],
      category: map['Category'],
      size: map['Size'],
      color: map['Color'],
      supplierId: map['SupplierID'],
    );
  }
}
