import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../models/product.dart';
import '../services/database_helper.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _dbHelper = DatabaseHelper();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _formKey.currentState?.patchValue({
        'name': widget.product!.name,
        'description': widget.product!.description,
        'price': widget.product!.price,
        'amount': widget.product!.amount,
        'category': widget.product!.category,
        'size': widget.product!.size,
        'color': widget.product!.color,
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final formData = _formKey.currentState!.value;
        final product = Product(
          productId: widget.product?.productId,
          name: formData['name'],
          description: formData['description'],
          price: formData['price'],
          amount: formData['amount'],
          category: formData['category'],
          size: formData['size'],
          color: formData['color'],
        );

        if (widget.product == null) {
          await _dbHelper.insert('Products', product.toMap());
        } else {
          await _dbHelper.update('Products', product.toMap(), 'ProductID = ?', [
            product.productId,
          ]);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            children: [
              FormBuilderTextField(
                name: 'name',
                decoration: const InputDecoration(labelText: 'Name'),
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'description',
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'price',
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.numeric(),
                  (value) {
                    if (value != null && double.parse(value) <= 0) {
                      return 'Price must be greater than 0';
                    }
                    return null;
                  },
                ]),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'amount',
                decoration: const InputDecoration(labelText: 'Amount in Stock'),
                keyboardType: TextInputType.number,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.integer(),
                  (value) {
                    if (value != null && int.parse(value) < 0) {
                      return 'Amount cannot be negative';
                    }
                    return null;
                  },
                ]),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'category',
                decoration: const InputDecoration(labelText: 'Category'),
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'size',
                decoration: const InputDecoration(labelText: 'Size'),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'color',
                decoration: const InputDecoration(labelText: 'Color'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : Text(
                          widget.product == null
                              ? 'Add Product'
                              : 'Update Product',
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
