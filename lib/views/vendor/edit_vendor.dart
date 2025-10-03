import 'dart:io';

import 'package:beauty_connect/core/core.dart';
import 'package:beauty_connect/data/models/vendor.dart';
import 'package:beauty_connect/data/repositories/auth_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditVendorProfileScreen extends StatefulWidget {
  final Vendor vendor;

  const EditVendorProfileScreen({super.key, required this.vendor});

  @override
  State<EditVendorProfileScreen> createState() =>
      _EditVendorProfileScreenState();
}

class _EditVendorProfileScreenState extends State<EditVendorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  File? _avatarFile;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _infoController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _websiteController;
  late TextEditingController _countryController;
  late TextEditingController _experienceController;
  late TextEditingController _openingTimeController;
  late TextEditingController _closingTimeController;
  final TextEditingController _customServiceController =
      TextEditingController();

  // Services
  final List<String> _services = ["Haircut", "Shaving", "Facial", "Massage"];
  late List<String> _selectedServices;

  final AuthRepository _authRepository = AuthRepository();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.vendor.name);
    _infoController = TextEditingController(text: widget.vendor.information);
    _emailController = TextEditingController(text: widget.vendor.email);
    _phoneController = TextEditingController(text: widget.vendor.phone);
    _addressController = TextEditingController(text: widget.vendor.address);
    _websiteController = TextEditingController(text: widget.vendor.website);
    _countryController = TextEditingController(text: widget.vendor.country);
    _experienceController = TextEditingController(
      text: widget.vendor.experience,
    );
    _openingTimeController = TextEditingController(
      text: widget.vendor.openingTime,
    );
    _closingTimeController = TextEditingController(
      text: widget.vendor.closingTime,
    );

    _selectedServices = List<String>.from(widget.vendor.services);
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() => _avatarFile = File(pickedFile.path));
    }
  }

  void _addCustomService() {
    final service = _customServiceController.text.trim();
    if (service.isNotEmpty && !_selectedServices.contains(service)) {
      setState(() {
        _selectedServices.add(service);
        _customServiceController.clear();
      });
    }
  }

  bool _isLoading = false; // <-- add this

  Future<void> _updateVendorProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true); // show loader

      final updatedVendor = widget.vendor.copyWith(
        name: _nameController.text.trim(),
        information: _infoController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        website: _websiteController.text.trim(),
        country: _countryController.text.trim(),
        experience: _experienceController.text.trim(),
        openingTime: _openingTimeController.text.trim(),
        closingTime: _closingTimeController.text.trim(),
        services: _selectedServices,
      );

      try {
        await _authRepository.editVendorAccount(
          vendor: updatedVendor,
          imageFile: _avatarFile,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vendor profile updated successfully!")),
        );
        Navigator.pop(context, updatedVendor);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error updating vendor: $e")));
      } finally {
        if (mounted) setState(() => _isLoading = false); // ✅ stop loader
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryPink,
        title: const Text("Edit Vendor Profile"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              GestureDetector(
                onTap: _showImagePickerDialog,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: AppTheme.lightPink,
                  backgroundImage: _avatarFile != null
                      ? FileImage(_avatarFile!)
                      : (widget.vendor.vendorUrl != null &&
                            widget.vendor.vendorUrl!.isNotEmpty)
                      ? NetworkImage(widget.vendor.vendorUrl!) as ImageProvider
                      : null,
                  child:
                      (_avatarFile == null &&
                          (widget.vendor.vendorUrl == null ||
                              widget.vendor.vendorUrl!.isEmpty))
                      ? const Icon(
                          Icons.camera_alt,
                          size: 50,
                          color: Colors.white70,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // Form fields
              _buildTextField(_nameController, "Vendor Name", validator: true),
              _buildTextField(_infoController, "Information"),
              _buildTextField(
                _emailController,
                "Email",
                validator: true,
                email: true,
              ),
              _buildTextField(
                _phoneController,
                "Phone",
                validator: true,
                phone: true,
              ),
              _buildTextField(_addressController, "Address", validator: true),
              _buildTextField(_websiteController, "Website"),
              _buildTextField(_countryController, "Country"),
              _buildTextField(_experienceController, "Experience"),

              // Opening / Closing Time
              _buildTimePicker(_openingTimeController, "Opening Time"),
              _buildTimePicker(_closingTimeController, "Closing Time"),

              const SizedBox(height: 20),

              // Services
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Edit Services",
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._services.map((service) {
                    final isSelected = _selectedServices.contains(service);
                    return GestureDetector(
                      onTap: () => setState(
                        () => isSelected
                            ? _selectedServices.remove(service)
                            : _selectedServices.add(service),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryPink
                              : Colors.white10,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: AppTheme.primaryPink,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          service,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.primaryPink,
                          ),
                        ),
                      ),
                    );
                  }),
                  ..._selectedServices.where((s) => !_services.contains(s)).map(
                    (service) {
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedServices.remove(service)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPink,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Text(
                            service,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // Add custom service
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _customServiceController,
                      "Add Custom Service",
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: AppTheme.primaryPink,
                      size: 30,
                    ),
                    onPressed: _addCustomService,
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Update button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : _updateVendorProfile, // disable while loading
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Edit Vendor Profile",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool validator = false,
    bool readOnly = false,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    VoidCallback? onTap,
    bool email = false,
    bool phone = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboard,
        maxLines: maxLines,
        onTap: onTap,
        validator: (val) {
          if (!validator) return null;
          if (val == null || val.trim().isEmpty) return "Enter $label";
          if (email) {
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(val.trim())) return "Enter a valid email";
          }
          if (phone) {
            final phoneRegex = RegExp(r'^[0-9]{7,15}$');
            if (!phoneRegex.hasMatch(val.trim())) return "Enter a valid phone";
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker(TextEditingController controller, String label) {
    return _buildTextField(
      controller,
      label,
      validator: true,
      readOnly: true,
      onTap: () async {
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (pickedTime != null) {
          setState(() => controller.text = pickedTime.format(context));
        }
      },
    );
  }

  void _showImagePickerDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text("Select Image"),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
            child: const Text("Camera"),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
            child: const Text("Gallery"),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
      ),
    );
  }
}
