import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/database_helper.dart';

class UserOrdersScreen extends StatefulWidget {
  final int userId;

  const UserOrdersScreen({super.key, required this.userId});

  @override
  State<UserOrdersScreen> createState() => _UserOrdersScreenState();
}

class _UserOrdersScreenState extends State<UserOrdersScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _dbHelper.query(
        'Orders',
        where: 'UserID = ?',
        whereArgs: [widget.userId],
      );
      setState(() {
        _orders = orders.map((order) => Order.fromMap(order)).toList();
        _orders.sort(
          (a, b) => b.date.compareTo(a.date),
        ); // Sort by date, newest first
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getOrderProducts(int orderId) async {
    final orderProducts = await _dbHelper.query(
      'OrderProducts',
      where: 'OrderID = ?',
      whereArgs: [orderId],
    );
    final products = await _dbHelper.query('Products');

    return orderProducts.map((op) {
      final product = products.firstWhere(
        (p) => p['ProductID'] == op['ProductID'],
      );
      return {'product': Product.fromMap(product), 'quantity': op['Quantity']};
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _orders.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No orders yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your orders will appear here',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: ExpansionTile(
                      title: Text('Order #${order.id}'),
                      subtitle: Text(
                        'Date: ${order.date.toString().split(' ')[0]}\nTotal: \$${order.grandTotal.toStringAsFixed(2)}\nStatus: ${order.status}',
                      ),
                      children: [
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _getOrderProducts(order.id!),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const ListTile(
                                title: Text('No products found'),
                              );
                            }
                            return Column(
                              children:
                                  snapshot.data!.map((item) {
                                    final product = item['product'] as Product;
                                    return ListTile(
                                      leading: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.image,
                                          size: 30,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                      title: Text(product.name),
                                      subtitle: Text(
                                        'Quantity: ${item['quantity']}\nPrice: \$${product.price.toStringAsFixed(2)}',
                                      ),
                                      trailing: Text(
                                        '\$${(product.price * item['quantity']).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
