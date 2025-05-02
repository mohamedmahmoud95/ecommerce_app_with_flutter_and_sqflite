import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/database_helper.dart';
import 'order_form_screen.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Order> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final orders = await _dbHelper.query('Orders');
    setState(() {
      _orders = orders.map((order) => Order.fromMap(order)).toList();
    });
  }

  Future<void> _deleteOrder(int orderId) async {
    await _dbHelper.delete('Orders', 'OrderID = ?', [orderId]);
    _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderFormScreen(),
                ),
              );
              _loadOrders();
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          return ListTile(
            title: Text('Order #${order.orderId}'),
            subtitle: Text(
              'Date: ${order.date}\nTotal: \$${order.grandTotal.toStringAsFixed(2)}\nStatus: ${order.status}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderFormScreen(order: order),
                      ),
                    );
                    _loadOrders();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Delete Order'),
                            content: Text(
                              'Are you sure you want to delete Order #${order.orderId}?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  _deleteOrder(order.orderId!);
                                  Navigator.pop(context);
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
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
