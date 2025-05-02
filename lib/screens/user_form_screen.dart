import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../models/user.dart';
import '../services/database_helper.dart';

class UserFormScreen extends StatefulWidget {
  final User? user;

  const UserFormScreen({super.key, this.user});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _dbHelper = DatabaseHelper();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _formKey.currentState?.patchValue({
        'name': widget.user!.name,
        'email': widget.user!.email,
        'password': widget.user!.password,
        'gender': widget.user!.gender,
        'dateOfBirth': widget.user!.dateOfBirth,
        'userType': widget.user!.userType,
      });
    }
  }

  Future<void> _saveUser() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final formData = _formKey.currentState!.value;
        final user = User(
          userId: widget.user?.userId,
          name: formData['name'],
          email: formData['email'],
          password: formData['password'],
          gender: formData['gender'],
          dateOfBirth: formData['dateOfBirth'],
          dateJoined:
              widget.user?.dateJoined ?? DateTime.now().toIso8601String(),
          userType: formData['userType'],
        );

        if (widget.user == null) {
          await _dbHelper.insert('Users', user.toMap());
        } else {
          await _dbHelper.update('Users', user.toMap(), 'User_ID = ?', [
            user.userId,
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
        title: Text(widget.user == null ? 'Add User' : 'Edit User'),
      ),
      body: Padding(
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
                name: 'email',
                decoration: const InputDecoration(labelText: 'Email'),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.email(),
                ]),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'password',
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 16),
              FormBuilderDropdown<String>(
                name: 'gender',
                decoration: const InputDecoration(labelText: 'Gender'),
                items:
                    ['Male', 'Female', 'Other']
                        .map(
                          (gender) => DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 16),
              FormBuilderDateTimePicker(
                name: 'dateOfBirth',
                decoration: const InputDecoration(labelText: 'Date of Birth'),
                inputType: InputType.date,
              ),
              const SizedBox(height: 16),
              FormBuilderDropdown<String>(
                name: 'userType',
                decoration: const InputDecoration(labelText: 'User Type'),
                initialValue: 'Customer',
                items:
                    ['Customer', 'Admin']
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveUser,
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : Text(
                          widget.user == null ? 'Add User' : 'Update User',
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
