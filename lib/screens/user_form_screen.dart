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
        'password': widget.user!.password,
        'email': widget.user!.email,
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

        // Validate email format
        if (!RegExp(
          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
        ).hasMatch(formData['email'])) {
          throw 'Please enter a valid email address';
        }

        // Validate password strength
        if (formData['password'].length < 6) {
          throw 'Password must be at least 6 characters long';
        }

        final user = User(
          id: widget.user?.id,
          name: formData['name'],
          password: formData['password'],
          email: formData['email'],
          gender: formData['gender'],
          dateOfBirth: formData['dateOfBirth'] as DateTime?,
          dateJoined: widget.user?.dateJoined ?? DateTime.now(),
          userType: formData['userType'],
        );

        if (widget.user == null) {
          await _dbHelper.insert('Users', user.toMap());
        } else {
          await _dbHelper.update('Users', user.toMap(), 'User_ID = ?', [
            user.id,
          ]);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'User ${widget.user == null ? 'added' : 'updated'} successfully',
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
        title: Text(widget.user == null ? 'Add User' : 'Edit User'),
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
                name: 'password',
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.minLength(6),
                ]),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'email',
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.email(),
                ]),
              ),
              const SizedBox(height: 16),
              FormBuilderDropdown(
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
                initialValue: widget.user?.dateOfBirth,
                inputType: InputType.date,
              ),
              const SizedBox(height: 16),
              FormBuilderDropdown(
                name: 'userType',
                decoration: const InputDecoration(labelText: 'User Type'),
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
