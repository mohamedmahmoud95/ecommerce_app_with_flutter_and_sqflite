import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/database_helper.dart';

class OrderFormScreen extends StatefulWidget {
  final Order? order;

  const OrderFormScreen({super.key, this.order});

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _dbHelper = DatabaseHelper();
  bool _isLoading = false;
  List<Product> _products = [];
  List<Map<String, dynamic>> _selectedProducts = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    if (widget.order != null) {
      _formKey.currentState?.patchValue({
        'userId': widget.order!.userId,
        'date': widget.order!.date,
        'grandTotal': widget.order!.grandTotal,
        'status': widget.order!.status,
        'paymentMethod': widget.order!.paymentMethod,
      });
    }
  }

  Future<void> _loadProducts() async {
    final products = await _dbHelper.query('Products');
    setState(() {
      _products = products.map((product) => Product.fromMap(product)).toList();
    });
  }

  Future<void> _saveOrder() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final formData = _formKey.currentState!.value;
        final order = Order(
          orderId: widget.order?.orderId,
          userId: formData['userId'],
          date: formData['date'] ?? DateTime.now().toIso8601String(),
          grandTotal: formData['grandTotal'],
          status: formData['status'],
          paymentMethod: formData['paymentMethod'],
        );

        if (widget.order == null) {
          final orderId = await _dbHelper.insert('Orders', order.toMap());
          for (final product in _selectedProducts) {
            await _dbHelper.insert('OrderProducts', {
              'OrderID': orderId,
              'ProductID': product['productId'],
              'Quantity': product['quantity'],
            });
          }
        } else {
          await _dbHelper.update('Orders', order.toMap(), 'OrderID = ?', [
            order.orderId,
          ]);
          // Update order products if needed
        }
        if (mounted) {
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

  void _addProduct() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Product'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FormBuilderDropdown<int>(
                  name: 'productId',
                  decoration: const InputDecoration(labelText: 'Product'),
                  items:
                      _products
                          .map(
                            (product) => DropdownMenuItem(
                              value: product.productId,
                              child: Text(
                                '${product.name} - \$${product.price}',
                              ),
                            ),
                          )
                          .toList(),
                  validator: FormBuilderValidators.required(),
                ),
                const SizedBox(height: 16),
                FormBuilderTextField(
                  name: 'quantity',
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.integer(),
                    (value) {
                      if (value != null && int.parse(value) <= 0) {
                        return 'Quantity must be greater than 0';
                      }
                      return null;
                    },
                  ]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (_formKey.currentState?.saveAndValidate() ?? false) {
                    final formData = _formKey.currentState!.value;
                    setState(() {
                      _selectedProducts.add({
                        'productId': formData['productId'],
                        'quantity': int.parse(formData['quantity']),
                      });
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.order == null ? 'Add Order' : 'Edit Order'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            children: [
              FormBuilderTextField(
                name: 'userId',
                decoration: const InputDecoration(labelText: 'User ID'),
                keyboardType: TextInputType.number,
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 16),
              FormBuilderDateTimePicker(
                name: 'date',
                decoration: const InputDecoration(labelText: 'Date'),
                inputType: InputType.date,
                initialValue: DateTime.now(),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'grandTotal',
                decoration: const InputDecoration(labelText: 'Grand Total'),
                keyboardType: TextInputType.number,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.numeric(),
                  (value) {
                    if (value != null && double.parse(value) <= 0) {
                      return 'Total must be greater than 0';
                    }
                    return null;
                  },
                ]),
              ),
              const SizedBox(height: 16),
              FormBuilderDropdown<String>(
                name: 'status',
                decoration: const InputDecoration(labelText: 'Status'),
                initialValue: 'Pending',
                items:
                    ['Pending', 'Shipped', 'Delivered']
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ),
                        )
                        .toList(),
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'paymentMethod',
                decoration: const InputDecoration(labelText: 'Payment Method'),
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _addProduct,
                child: const Text('Add Product'),
              ),
              const SizedBox(height: 16),
              if (_selectedProducts.isNotEmpty)
                Column(
                  children:
                      _selectedProducts.map((product) {
                        final productData = _products.firstWhere(
                          (p) => p.productId == product['productId'],
                        );
                        return ListTile(
                          title: Text(productData.name),
                          subtitle: Text(
                            'Quantity: ${product['quantity']} - Total: \$${(productData.price * product['quantity']).toStringAsFixed(2)}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _selectedProducts.remove(product);
                              });
                            },
                          ),
                        );
                      }).toList(),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveOrder,
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : Text(
                          widget.order == null ? 'Add Order' : 'Update Order',
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
