import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../models/product.dart';
import '../services/database_helper.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _cartItems = [];
  double _total = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);
    try {
      // For demo purposes, we'll use user ID 1
      final cart = await _dbHelper.query(
        'Carts',
        where: 'User_ID = ?',
        whereArgs: [1],
      );
      if (cart.isNotEmpty) {
        final cartId = cart.first['CartID'];
        final cartProducts = await _dbHelper.query(
          'CartProducts',
          where: 'CartID = ?',
          whereArgs: [cartId],
        );
        final products = await _dbHelper.query('Products');

        setState(() {
          _cartItems =
              cartProducts.map((cp) {
                final product = products.firstWhere(
                  (p) => p['ProductID'] == cp['ProductID'],
                );
                return {
                  'cartProductId': cp['CartID'],
                  'productId': cp['ProductID'],
                  'quantity': cp['Quantity'],
                  'product': Product.fromMap(product),
                };
              }).toList();
          _calculateTotal();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateTotal() {
    _total = _cartItems.fold(0.0, (sum, item) {
      final product = item['product'] as Product;
      return sum + (product.price * item['quantity']);
    });
  }

  Future<void> _updateQuantity(
    int cartId,
    int productId,
    int newQuantity,
  ) async {
    if (newQuantity > 0) {
      await _dbHelper.update(
        'CartProducts',
        {'Quantity': newQuantity},
        'CartID = ? AND ProductID = ?',
        [cartId, productId],
      );
    } else {
      await _dbHelper.delete('CartProducts', 'CartID = ? AND ProductID = ?', [
        cartId,
        productId,
      ]);
    }
    _loadCart();
  }

  Future<void> _removeItem(int cartId, int productId) async {
    await _dbHelper.delete('CartProducts', 'CartID = ? AND ProductID = ?', [
      cartId,
      productId,
    ]);
    _loadCart();
  }

  Future<void> _checkout() async {
    if (_cartItems.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      // For demo purposes, we'll use user ID 1
      final order = {
        'User_ID': 1,
        'Date': DateTime.now().toIso8601String(),
        'GrandTotal': _total,
        'Status': 'Pending',
        'PaymentMethod': 'Credit Card',
      };

      final orderId = await _dbHelper.insert('Orders', order);

      for (final item in _cartItems) {
        await _dbHelper.insert('OrderProducts', {
          'OrderID': orderId,
          'ProductID': item['productId'],
          'Quantity': item['quantity'],
        });
      }

      // Clear the cart
      final cart = await _dbHelper.query(
        'Carts',
        where: 'User_ID = ?',
        whereArgs: [1],
      );
      if (cart.isNotEmpty) {
        await _dbHelper.delete('CartProducts', 'CartID = ?', [
          cart.first['CartID'],
        ]);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!')),
        );
        _loadCart();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _cartItems.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your cart is empty',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add some products to your cart',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        final product = item['product'] as Product;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.image,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '\$${product.price.toStringAsFixed(2)}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall?.copyWith(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove),
                                            onPressed:
                                                () => _updateQuantity(
                                                  item['cartProductId'],
                                                  item['productId'],
                                                  item['quantity'] - 1,
                                                ),
                                          ),
                                          Text(
                                            '${item['quantity']}',
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.titleMedium,
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add),
                                            onPressed:
                                                () => _updateQuantity(
                                                  item['cartProductId'],
                                                  item['productId'],
                                                  item['quantity'] + 1,
                                                ),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            color: Colors.red,
                                            onPressed:
                                                () => _removeItem(
                                                  item['cartProductId'],
                                                  item['productId'],
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, -1),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${_total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _checkout,
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text('Checkout'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
