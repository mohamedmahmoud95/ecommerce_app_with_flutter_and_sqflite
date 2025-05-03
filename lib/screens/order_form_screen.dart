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
  List<Map<String, dynamic>> _orderProducts = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    if (widget.order != null) {
      _formKey.currentState?.patchValue({
        'userId': widget.order!.userId.toString(),
        'date': widget.order!.date,
        'status': widget.order!.status,
        'paymentMethod': widget.order!.paymentMethod,
      });
      _loadOrderProducts();
    }
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _dbHelper.query('Products');
      setState(() {
        _products = products.map((p) => Product.fromMap(p)).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadOrderProducts() async {
    if (widget.order == null) return;
    try {
      final orderProducts = await _dbHelper.query(
        'OrderProducts',
        where: 'OrderID = ?',
        whereArgs: [widget.order!.id],
      );
      setState(() {
        _orderProducts =
            orderProducts
                .map(
                  (p) => {
                    'ProductID': p['ProductID'],
                    'Quantity': p['Quantity'],
                  },
                )
                .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading order products: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addProduct() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Product'),
            content: FormBuilder(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FormBuilderDropdown(
                    name: 'productId',
                    decoration: const InputDecoration(labelText: 'Product'),
                    items:
                        _products
                            .map(
                              (p) => DropdownMenuItem(
                                value: p.id,
                                child: Text('${p.name} - \$${p.price}'),
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
                      FormBuilderValidators.numeric(),
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
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (FormBuilder.of(context)?.saveAndValidate() ?? false) {
                    final formData = FormBuilder.of(context)!.value;
                    setState(() {
                      _orderProducts.add({
                        'ProductID': formData['productId'],
                        'Quantity': int.parse(formData['quantity']),
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

  Future<void> _saveOrder() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final formData = _formKey.currentState!.value;

        // Validate and convert numeric fields
        int userId;
        DateTime date;

        try {
          userId = int.parse(formData['userId']);
        } catch (e) {
          throw 'Please enter a valid user ID';
        }

        date = formData['date'] as DateTime;

        if (_orderProducts.isEmpty) {
          throw 'Please add at least one product to the order';
        }

        final order = Order(
          id: widget.order?.id,
          userId: userId,
          date: date,
          grandTotal: 0.0, // Will be calculated by trigger
          status: formData['status'],
          paymentMethod: formData['paymentMethod'],
        );

        if (widget.order == null) {
          final orderId = await _dbHelper.insert('Orders', order.toMap());
          for (var product in _orderProducts) {
            await _dbHelper.insert('OrderProducts', {
              'OrderID': orderId,
              'ProductID': product['ProductID'],
              'Quantity': product['Quantity'],
            });
          }
        } else {
          await _dbHelper.update('Orders', order.toMap(), 'OrderID = ?', [
            order.id,
          ]);
          await _dbHelper.delete('OrderProducts', 'OrderID = ?', [order.id]);
          for (var product in _orderProducts) {
            await _dbHelper.insert('OrderProducts', {
              'OrderID': order.id,
              'ProductID': product['ProductID'],
              'Quantity': product['Quantity'],
            });
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Order ${widget.order == null ? 'added' : 'updated'} successfully',
              ),
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
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
      appBar: AppBar(
        title: Text(widget.order == null ? 'Add Order' : 'Edit Order'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          child: ListView(
            children: [
              FormBuilderTextField(
                name: 'userId',
                decoration: const InputDecoration(labelText: 'User ID'),
                keyboardType: TextInputType.number,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.numeric(),
                ]),
              ),
              const SizedBox(height: 16),
              FormBuilderDateTimePicker(
                name: 'date',
                decoration: const InputDecoration(labelText: 'Date'),
                initialValue: widget.order?.date ?? DateTime.now(),
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 16),
              FormBuilderDropdown(
                name: 'status',
                decoration: const InputDecoration(labelText: 'Status'),
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
              FormBuilderDropdown(
                name: 'paymentMethod',
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items:
                    ['Credit Card', 'PayPal', 'Bank Transfer']
                        .map(
                          (method) => DropdownMenuItem(
                            value: method,
                            child: Text(method),
                          ),
                        )
                        .toList(),
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 24),
              const Text('Products:', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              ..._orderProducts.map((product) {
                final productName =
                    _products
                        .firstWhere((p) => p.id == product['ProductID'])
                        .name;
                return ListTile(
                  title: Text(productName),
                  subtitle: Text('Quantity: ${product['Quantity']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _orderProducts.remove(product);
                      });
                    },
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addProduct,
                child: const Text('Add Product'),
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
