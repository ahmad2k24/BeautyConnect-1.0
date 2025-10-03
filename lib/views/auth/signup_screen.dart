import 'dart:io';

import 'package:beauty_connect/core/core.dart';
import 'package:beauty_connect/data/data.dart';
import 'package:beauty_connect/views/auth/login_screen.dart';
import 'package:beauty_connect/views/switcher/client_layout.dart';
import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:image_picker/image_picker.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  File? _pickedImage;
  String _countryCode = "+92"; // <-- Added definition for _countryCode
  bool _isLoading = false;

  final AuthRepository _authRepo = AuthRepository();

  // ---------- IMAGE PICKER BOTTOM SHEET ----------
  Future<void> _showImageSourceSheet() async {
    final Color primary = AppTheme.primaryPink;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // so we can use a custom container
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primary.withOpacity(0.95), primary.withOpacity(0.85)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white54,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Upload Profile Photo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildSheetButton(
                icon: Icons.photo_camera,
                label: 'Take a Photo',
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                    imageQuality: 85,
                  );
                  if (picked != null) {
                    setState(() => _pickedImage = File(picked.path));
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildSheetButton(
                icon: Icons.photo_library,
                label: 'Choose from Gallery',
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (picked != null) {
                    setState(() => _pickedImage = File(picked.path));
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for consistent button styling
  Widget _buildSheetButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        Feedback.forTap(context); // subtle haptic feedback
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 16),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ---------- PROFILE IMAGE PICKER ----------
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.lightPink,
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : null,
                      child: _pickedImage == null
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primaryPink,
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                        onPressed:
                            _showImageSourceSheet, // <-- trigger bottom sheet
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Enter your name" : null,
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Enter your email";
                    if (!RegExp(
                      r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return "Enter a valid email";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone with country picker
                Row(
                  children: [
                    // ----- Country Picker with Pink Border -----
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors
                                  .white10 // inner fill for dark mode
                            : AppTheme.lightPink, // inner fill for light mode
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade600
                              : AppTheme.lightPink, // your pink color
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),

                      child: CountryCodePicker(
                        onChanged: (code) {
                          setState(() => _countryCode = code.dialCode ?? "+92");
                        },
                        initialSelection: 'PK',
                        favorite: const ['+92', 'PK'],
                        showCountryOnly: false,
                        showFlag: true,
                        showDropDownButton: false,
                        backgroundColor: isDark
                            ? Colors
                                  .white10 // rich dark gray, near black
                            : Colors.grey.shade50, // soft white
                        textStyle: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                        dialogBackgroundColor: isDark
                            ? Colors
                                  .white10 // ensures the modal matches dark theme
                            : Colors.white,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // ----- Phone Number Field -----
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: "Phone Number",
                          prefixIcon: Icon(Icons.phone),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? "Enter phone"
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Address
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: "Address",
                    prefixIcon: Icon(Icons.home),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Enter address" : null,
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) =>
                      value == null || value.length < 6 ? "Min 6 chars" : null,
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return "Passwords do not match";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Terms & Conditions
                // Terms & Conditions – now with built-in validation
                FormField<bool>(
                  initialValue: _acceptTerms,
                  validator: (value) {
                    if (value != true) {
                      return 'You must accept the Terms & Conditions to proceed';
                    }
                    return null;
                  },
                  builder: (field) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _acceptTerms,
                              activeColor: AppTheme.primaryPink,
                              onChanged: (val) {
                                setState(() {
                                  _acceptTerms = val ?? false;
                                  field.didChange(val);
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                "I accept the Terms & Conditions",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        if (field.errorText != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Text(
                              field.errorText!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate() &&
                                _acceptTerms) {
                              if (_pickedImage == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Please select a profile image",
                                    ),
                                  ),
                                );
                                return;
                              }

                              setState(() => _isLoading = true);

                              try {
                                await _authRepo.createAccount(
                                  fullName: _nameController.text.trim(),
                                  email: _emailController.text.trim(),
                                  phone:
                                      '$_countryCode${_phoneController.text.trim()}',
                                  address: _addressController.text.trim(),
                                  password: _passwordController.text.trim(),
                                  imageFile: _pickedImage!,
                                );

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Signup successful"),
                                    ),
                                  );

                                  // 1️⃣ Clear all fields and reset state
                                  _formKey.currentState!.reset();
                                  _nameController.clear();
                                  _emailController.clear();
                                  _phoneController.clear();
                                  _addressController.clear();
                                  _passwordController.clear();
                                  _confirmPasswordController.clear();
                                  setState(() {
                                    _pickedImage = null;
                                    _acceptTerms = false;
                                  });

                                  // 2️⃣ Navigate to Client Home Screen and remove previous routes
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ClientLayout(),
                                    ),
                                    (route) =>
                                        false, // remove all previous routes
                                  );
                                }
                              } on NetworkException catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Network Error: ${e.message}",
                                    ),
                                  ),
                                );
                              } on AuthException catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Auth Error: ${e.message}"),
                                  ),
                                );
                              } on UnknownException catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Error: ${e.message}"),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Unexpected Error: $e"),
                                  ),
                                );
                              } finally {
                                if (mounted) setState(() => _isLoading = false);
                              }
                            } else if (!_acceptTerms) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please accept terms"),
                                ),
                              );
                            }
                          },

                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text("Sign Up"),
                  ),
                ),

                const SizedBox(height: 20),

                // Divider with "OR"
                Row(
                  children: const [
                    Expanded(child: Divider(thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text("OR"),
                    ),
                    Expanded(child: Divider(thickness: 1)),
                  ],
                ),
                const SizedBox(height: 20),

                // Social Buttons
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  icon: Image.asset("assets/icons/google.png", height: 24),
                  label: const Text("Continue with Google"),
                  onPressed: () {},
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  icon: Image.asset("assets/icons/apple.png", height: 24),
                  label: const Text("Continue with Apple"),
                  onPressed: () {},
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
