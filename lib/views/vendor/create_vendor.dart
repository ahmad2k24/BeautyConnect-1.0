import 'dart:io';

import 'package:beauty_connect/data/data.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:beauty_connect/core/core.dart';

class CreateVendorProfileScreen extends StatefulWidget {
  const CreateVendorProfileScreen({super.key});

  @override
  State<CreateVendorProfileScreen> createState() =>
      _CreateVendorProfileScreenState();
}

class _CreateVendorProfileScreenState extends State<CreateVendorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  File? _avatarFile;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _infoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _openingTimeController = TextEditingController();
  final TextEditingController _closingTimeController = TextEditingController();
  final TextEditingController _customServiceController =
      TextEditingController();

  // Services
  final List<String> _services = ["Haircut", "Shaving", "Facial", "Massage"];
  final List<String> _selectedServices = [];
  final AuthRepository _authRepository = AuthRepository();
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

  void _createVendorProfile(File? avatarFile) async {
    if (_formKey.currentState!.validate()) {
      final vendor = Vendor(
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
        vendorUrl: '', // store local path or upload URL
      );

      final success = await _authRepository.createVendorAccount(
        vendor: vendor,
        imageFile: avatarFile!,
      );

      if (success) {
        // Clear all form fields
        _nameController.clear();
        _infoController.clear();
        _emailController.clear();
        _phoneController.clear();
        _addressController.clear();
        _websiteController.clear();
        _countryController.clear();
        _experienceController.clear();
        _openingTimeController.clear();
        _closingTimeController.clear();
        _customServiceController.clear();
        _selectedServices.clear();
        setState(() {
          _avatarFile = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vendor profile created successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create vendor profile.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryPink,
        title: const Text("Create Vendor Profile"),
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
                      : null,
                  child: _avatarFile == null
                      ? const Icon(
                          Icons.camera_alt,
                          size: 50,
                          color: Colors.white70,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // Form Fields with Validation
              _buildTextField(_nameController, "Vendor Name", validator: true),
              _buildTextField(_infoController, "Information"),
              _buildTextField(
                _emailController,
                "Email",
                validator: true,
                keyboard: TextInputType.emailAddress,
                email: true,
              ),
              _buildTextField(
                _phoneController,
                "Phone",
                validator: true,
                keyboard: TextInputType.phone,
                phone: true,
              ),
              _buildTextField(_addressController, "Address", validator: true),
              _buildTextField(_websiteController, "Website"),
              _buildCountryField(),
              _buildTextField(_experienceController, "Experience"),

              // Opening Time
              _buildTextField(
                _openingTimeController,
                "Opening Time",
                validator: true,
                readOnly: true,
                onTap: () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _openingTimeController.text = pickedTime.format(context);
                    });
                  }
                },
              ),

              // Closing Time
              _buildTextField(
                _closingTimeController,
                "Closing Time",
                validator: true,
                readOnly: true,
                onTap: () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _closingTimeController.text = pickedTime.format(context);
                    });
                  }
                },
              ),

              const SizedBox(height: 20),

              // Services
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Select Services",
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

              // Custom service input
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

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _createVendorProfile(_avatarFile),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Create Vendor Profile",
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

  _buildCountryField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: _countryController,
        readOnly: true,
        decoration: InputDecoration(
          labelText: "Country (ISO Code)",
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (val) {
          if (val == null || val.trim().isEmpty) return "Select Country";
          return null;
        },
        onTap: () {
          showCountryPicker(
            context: context,
            showPhoneCode:
                false, // we only want ISO, not phone code (can be true if needed)
            onSelect: (Country country) {
              setState(() {
                _countryController.text = country.countryCode;
                // ⬅️ This ensures we save "PK", "US", "IN", etc.
              });
            },
          );
        },
      ),
    );
  }
}
