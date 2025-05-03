import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../models/discount.dart';
import '../services/database_helper.dart';

class DiscountFormScreen extends StatefulWidget {
  final Discount? discount;

  const DiscountFormScreen({super.key, this.discount});

  @override
  State<DiscountFormScreen> createState() => _DiscountFormScreenState();
}

class _DiscountFormScreenState extends State<DiscountFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _dbHelper = DatabaseHelper();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.discount != null) {
      _formKey.currentState?.patchValue({
        'code': widget.discount!.code,
        'percentage': widget.discount!.percentage,
        'expirationDate': widget.discount!.expirationDate,
        'productId': widget.discount!.productId,
        'category': widget.discount!.category,
        'minOrderAmount': widget.discount!.minOrderAmount,
        'maxUses': widget.discount!.maxUses,
      });
    }
  }

  Future<void> _saveDiscount() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isLoading = true);
      final formData = _formKey.currentState!.value;

      final discount = Discount(
        id: widget.discount?.id,
        code: formData['code'],
        percentage: formData['percentage'] ?? 10,
        expirationDate: formData['expirationDate'],
        productId: formData['productId'],
        category: formData['category'],
        minOrderAmount: formData['minOrderAmount'],
        maxUses: formData['maxUses'],
      );

      try {
        if (widget.discount == null) {
          await _dbHelper.insertDiscount(discount);
        } else {
          await _dbHelper.updateDiscount(discount);
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
        title: Text(widget.discount == null ? 'Add Discount' : 'Edit Discount'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          child: ListView(
            children: [
              FormBuilderTextField(
                name: 'code',
                decoration: const InputDecoration(
                  labelText: 'Discount Code',
                  hintText: 'Enter discount code',
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.minLength(3),
                ]),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'percentage',
                decoration: const InputDecoration(
                  labelText: 'Discount Percentage',
                  hintText: 'Enter percentage (e.g., 10)',
                ),
                keyboardType: TextInputType.number,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.numeric(),
                  FormBuilderValidators.min(0),
                  FormBuilderValidators.max(100),
                ]),
              ),
              const SizedBox(height: 16),
              FormBuilderDateTimePicker(
                name: 'expirationDate',
                decoration: const InputDecoration(labelText: 'Expiration Date'),
                initialValue:
                    widget.discount?.expirationDate ??
                    DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'productId',
                decoration: const InputDecoration(
                  labelText: 'Product ID (Optional)',
                  hintText: 'Enter product ID for specific product discount',
                ),
                keyboardType: TextInputType.number,
                validator: FormBuilderValidators.numeric(),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'category',
                decoration: const InputDecoration(
                  labelText: 'Category (Optional)',
                  hintText: 'Enter category for category-wide discount',
                ),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'minOrderAmount',
                decoration: const InputDecoration(
                  labelText: 'Minimum Order Amount (Optional)',
                  hintText: 'Enter minimum order amount',
                ),
                keyboardType: TextInputType.number,
                validator: FormBuilderValidators.numeric(),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'maxUses',
                decoration: const InputDecoration(
                  labelText: 'Maximum Uses (Optional)',
                  hintText:
                      'Enter maximum number of times discount can be used',
                ),
                keyboardType: TextInputType.number,
                validator: FormBuilderValidators.numeric(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveDiscount,
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : Text(
                          widget.discount == null
                              ? 'Add Discount'
                              : 'Update Discount',
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
