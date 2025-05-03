import 'package:flutter/material.dart';
import '../models/discount.dart';
import '../services/database_helper.dart';
import 'discount_form_screen.dart';

class DiscountListScreen extends StatefulWidget {
  const DiscountListScreen({super.key});

  @override
  State<DiscountListScreen> createState() => _DiscountListScreenState();
}

class _DiscountListScreenState extends State<DiscountListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Discount> _discounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiscounts();
  }

  Future<void> _loadDiscounts() async {
    setState(() => _isLoading = true);
    final discounts = await _dbHelper.getDiscounts();
    setState(() {
      _discounts = discounts;
      _isLoading = false;
    });
  }

  Future<void> _deleteDiscount(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Discount'),
            content: const Text(
              'Are you sure you want to delete this discount?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _dbHelper.deleteDiscount(id);
      _loadDiscounts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discounts')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _discounts.isEmpty
              ? const Center(child: Text('No discounts found'))
              : ListView.builder(
                itemCount: _discounts.length,
                itemBuilder: (context, index) {
                  final discount = _discounts[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(
                        'Code: ${discount.code}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${discount.percentage}% off'),
                          Text(
                            'Expires: ${discount.expirationDate.toString().split(' ')[0]}',
                          ),
                          if (discount.productId != null)
                            Text('Product ID: ${discount.productId}'),
                          if (discount.category != null)
                            Text('Category: ${discount.category}'),
                          if (discount.minOrderAmount != null)
                            Text('Min Order: \$${discount.minOrderAmount}'),
                          if (discount.maxUses != null)
                            Text(
                              'Uses: ${discount.usesCount}/${discount.maxUses}',
                            ),
                        ],
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
                                  builder:
                                      (context) => DiscountFormScreen(
                                        discount: discount,
                                      ),
                                ),
                              );
                              _loadDiscounts();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteDiscount(discount.id!),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DiscountFormScreen()),
          );
          _loadDiscounts();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
