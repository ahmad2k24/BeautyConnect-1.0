import 'dart:io';

import 'package:beauty_connect/data/data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:beauty_connect/core/core.dart';

class EditClientProfile extends StatefulWidget {
  final Client client;
  const EditClientProfile({super.key, required this.client});

  @override
  State<EditClientProfile> createState() => _EditClientProfileState();
}

class _EditClientProfileState extends State<EditClientProfile> {
  final _formKey = GlobalKey<FormState>();
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _pickedImage = File(image.path);
      });
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: AppTheme.primaryPink,
              ),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppTheme.primaryPink,
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _applyChanges() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await AuthRepository().updateProfile(
          clientId: widget.client.id,
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          imageFile: _pickedImage, // can be null
        );

        Navigator.pop(context); // remove loading indicator

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );

        // Optionally, you can pop the screen or refresh the parent widget
        Navigator.pop(context, true); // pass true to indicate profile updated
      } catch (e) {
        Navigator.pop(context); // remove loading indicator
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _nameController.text = widget.client.name;
    _phoneController.text = widget.client.phone;
    _addressController.text = widget.client.address!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryPink,
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ---------- CIRCLE AVATAR ----------
              GestureDetector(
                onTap: _showImagePickerOptions,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: AppTheme.lightPink,
                  backgroundImage: _pickedImage != null
                      ? FileImage(_pickedImage!)
                      : NetworkImage(widget.client.clientUrl!) as ImageProvider,
                  child: _pickedImage == null
                      ? const Icon(
                          CupertinoIcons.camera_fill,
                          size: 40,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              // ---------- FULL NAME ----------
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: AppTheme.primaryPink,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter full name' : null,
              ),
              const SizedBox(height: 16),

              // ---------- PHONE ----------
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: AppTheme.primaryPink,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter phone number'
                    : null,
              ),
              const SizedBox(height: 16),

              // ---------- ADDRESS ----------
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: AppTheme.primaryPink,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter address' : null,
              ),
              const SizedBox(height: 32),

              // ---------- APPLY BUTTON ----------
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _applyChanges,
                  child: const Text(
                    'Apply Changes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
