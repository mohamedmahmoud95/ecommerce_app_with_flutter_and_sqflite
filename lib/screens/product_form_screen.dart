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
        'price': widget.product!.price.toString(),
        'amount': widget.product!.amount.toString(),
        'category': widget.product!.category,
        'size': widget.product!.size,
        'color': widget.product!.color,
        'supplierId': widget.product!.supplierId?.toString(),
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final formData = _formKey.currentState!.value;

        // Validate and convert numeric fields
        double price;
        int amount;
        int? supplierId;

        try {
          price = double.parse(formData['price']);
          if (price <= 0) throw FormatException('Price must be greater than 0');
        } catch (e) {
          throw 'Please enter a valid price greater than 0';
        }

        try {
          amount = int.parse(formData['amount']);
          if (amount < 0) throw FormatException('Amount cannot be negative');
        } catch (e) {
          throw 'Please enter a valid amount (non-negative number)';
        }

        if (formData['supplierId']?.isNotEmpty == true) {
          try {
            supplierId = int.parse(formData['supplierId']);
          } catch (e) {
            throw 'Please enter a valid supplier ID';
          }
        }

        final product = Product(
          id: widget.product?.id,
          name: formData['name'],
          description: formData['description'],
          price: price,
          amount: amount,
          category: formData['category'],
          size: formData['size'],
          color: formData['color'],
          supplierId: supplierId,
        );

        if (widget.product == null) {
          await _dbHelper.insert('Products', product.toMap());
        } else {
          await _dbHelper.update('Products', product.toMap(), 'ProductID = ?', [
            product.id,
          ]);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Product ${widget.product == null ? 'added' : 'updated'} successfully',
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
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          child: ListView(
            children: [
              FormBuilderTextField(
                name: 'name',
                decoration: const InputDecoration(labelText: 'Name'),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.minLength(2),
                ]),
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
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.numeric(),
                ]),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'amount',
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.numeric(),
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
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'supplierId',
                decoration: const InputDecoration(labelText: 'Supplier ID'),
                keyboardType: TextInputType.number,
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
