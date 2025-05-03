import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/database_helper.dart';

class CartScreen extends StatefulWidget {
  final int userId;

  const CartScreen({super.key, required this.userId});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _cartItems = [];
  double _totalAmount = 0;
  double _discountAmount = 0;
  String? _discountCode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    setState(() => _isLoading = true);
    final items = await _dbHelper.getCartItems(widget.userId);
    setState(() {
      _cartItems = items;
      _calculateTotal();
      _isLoading = false;
    });
  }

  void _calculateTotal() {
    double total = 0;
    for (final item in _cartItems) {
      total += item['Price'] * item['Quantity'];
    }
    setState(() {
      _totalAmount = total;
      _discountAmount = 0;
    });
  }

  Future<void> _applyDiscount(String code) async {
    if (code.isEmpty) return;

    final isValid = await _dbHelper.validateDiscount(
      code,
      null, // productId
      null, // category
      _totalAmount,
    );

    if (!isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid or expired discount code')),
        );
      }
      return;
    }

    final discount = await _dbHelper.getDiscountByCode(code);
    if (discount != null) {
      setState(() {
        _discountCode = code;
        _discountAmount = _totalAmount * (discount.percentage / 100);
      });
    }
  }

  Future<void> _checkout() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Your cart is empty')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Order'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Amount: \$${_totalAmount.toStringAsFixed(2)}'),
                if (_discountAmount > 0)
                  Text(
                    'Discount: -\$${_discountAmount.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.green),
                  ),
                Text(
                  'Final Amount: \$${(_totalAmount - _discountAmount).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final orderId = await _dbHelper.insertOrder(
          widget.userId,
          _totalAmount - _discountAmount,
          _discountCode,
          _discountAmount,
        );

        for (final item in _cartItems) {
          await _dbHelper.insertOrderProduct(
            orderId,
            item['ProductID'],
            item['Quantity'],
            item['Price'] as double,
          );
        }

        await _dbHelper.clearCart(widget.userId);
        if (_discountCode != null) {
          await _dbHelper.incrementDiscountUses(_discountCode!);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order placed successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _cartItems.isEmpty
              ? const Center(child: Text('Your cart is empty'))
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  item['ImageURL']?.isNotEmpty == true
                                      ? NetworkImage(item['ImageURL'])
                                      : null,
                              child:
                                  item['ImageURL']?.isEmpty != false
                                      ? const Icon(Icons.shopping_bag)
                                      : null,
                            ),
                            title: Text(item['Name']),
                            subtitle: Text(
                              '\$${item['Price']} x ${item['Quantity']}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () async {
                                    if (item['Quantity'] > 1) {
                                      await _dbHelper.updateCartItemQuantity(
                                        widget.userId,
                                        item['ProductID'],
                                        item['Quantity'] - 1,
                                      );
                                      _loadCartItems();
                                    }
                                  },
                                ),
                                Text(item['Quantity'].toString()),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () async {
                                    await _dbHelper.updateCartItemQuantity(
                                      widget.userId,
                                      item['ProductID'],
                                      item['Quantity'] + 1,
                                    );
                                    _loadCartItems();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    await _dbHelper.removeFromCart(
                                      widget.userId,
                                      item['ProductID'],
                                    );
                                    _loadCartItems();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Discount Code',
                                  hintText: 'Enter discount code',
                                ),
                                onSubmitted: _applyDiscount,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: () {
                                final code = _discountCode;
                                if (code != null) {
                                  _applyDiscount(code);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Total: \$${_totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_discountAmount > 0) ...[
                          Text(
                            'Discount: -\$${_discountAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Final Amount: \$${(_totalAmount - _discountAmount).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _checkout,
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator()
                                  : const Text('Checkout'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
