import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../services/database_helper.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _genderController = TextEditingController();
  final _dateOfBirthController = TextEditingController();

  // Address fields
  final _addressTypeController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _districtController = TextEditingController();
  final _streetController = TextEditingController();
  final _buildingNumberController = TextEditingController();
  final _apartmentNumberController = TextEditingController();
  final _postalCodeController = TextEditingController();

  bool _isDefaultAddress = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _genderController.dispose();
    _dateOfBirthController.dispose();
    _addressTypeController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _streetController.dispose();
    _buildingNumberController.dispose();
    _apartmentNumberController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        final dbHelper = DatabaseHelper();
        final db = await dbHelper.database;

        // Start a transaction
        await db.transaction((txn) async {
          // Insert user
          final userId = await txn.insert('Users', {
            'FirstName': _firstNameController.text,
            'MiddleName': _middleNameController.text,
            'LastName': _lastNameController.text,
            'Password': _passwordController.text,
            'Email': _emailController.text,
            'Gender': _genderController.text,
            'DateOfBirth': _dateOfBirthController.text,
            'DateJoined': DateTime.now().toIso8601String(),
            'UserType': 'Customer',
            'PhoneNumber': _phoneController.text,
          });

          // Insert address
          await txn.insert('Addresses', {
            'UserID': userId,
            'AddressType': _addressTypeController.text,
            'Country': _countryController.text,
            'City': _cityController.text,
            'Province': _provinceController.text,
            'District': _districtController.text,
            'Street': _streetController.text,
            'BuildingNumber': _buildingNumberController.text,
            'ApartmentNumber': _apartmentNumberController.text,
            'PostalCode': _postalCodeController.text,
            'IsDefault': _isDefaultAddress ? 1 : 0,
          });
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful!')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name Section
              const Text(
                'Personal Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _middleNameController,
                decoration: const InputDecoration(
                  labelText: 'Middle Name (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _genderController,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dateOfBirthController,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                ),
              ),

              // Address Section
              const SizedBox(height: 24),
              const Text(
                'Address Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressTypeController,
                decoration: const InputDecoration(
                  labelText: 'Address Type (Home/Work/Other)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'Country',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter country';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter city';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _provinceController,
                decoration: const InputDecoration(
                  labelText: 'Province/State',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter province/state';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _districtController,
                decoration: const InputDecoration(
                  labelText: 'District (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(
                  labelText: 'Street',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter street';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _buildingNumberController,
                decoration: const InputDecoration(
                  labelText: 'Building Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _apartmentNumberController,
                decoration: const InputDecoration(
                  labelText: 'Apartment Number (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _postalCodeController,
                decoration: const InputDecoration(
                  labelText: 'Postal Code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _isDefaultAddress,
                    onChanged: (value) {
                      setState(() {
                        _isDefaultAddress = value ?? false;
                      });
                    },
                  ),
                  const Text('Set as default address'),
                ],
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _register,
                child: const Text('Register'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
