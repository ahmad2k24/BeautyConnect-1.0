import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:beauty_connect/data/data.dart'; // contains Service model & ServiceRepository

class EditServiceScreen extends StatefulWidget {
  final Post service; // 👈 incoming service to edit

  const EditServiceScreen({super.key, required this.service});

  @override
  State<EditServiceScreen> createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends State<EditServiceScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _vendorNameController;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _durationController;
  final _customServiceController = TextEditingController();

  // Image & service state
  final List<File> _newImages = []; // new images picked
  late List<String> _existingImages; // existing image URLs
  late List<String> _selectedServices;

  final List<String> _prebuiltServices = [
    'Make-up',
    'Hair Cutting',
    'Facial',
    'Manicure',
    'Pedicure',
  ];

  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final s = widget.service;

    _vendorNameController = TextEditingController(text: s.vendorName);
    _titleController = TextEditingController(text: s.title);
    _descriptionController = TextEditingController(text: s.description);
    _priceController = TextEditingController(text: s.price);
    _durationController = TextEditingController(text: s.duration);

    _selectedServices = List<String>.from(s.services);
    _existingImages = List<String>.from(s.images ?? []);
  }

  void _showSnack(String msg, {Color? color}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _pickImages(FormFieldState<List<File>>? state) async {
    if (_newImages.length + _existingImages.length >= 7) {
      _showSnack('You can select a maximum of 7 images.');
      return;
    }
    final picked = await _picker.pickMultiImage();
    if (picked.isEmpty) return;

    final remaining = 7 - (_newImages.length + _existingImages.length);
    final limited = picked.length > remaining
        ? picked.sublist(0, remaining)
        : picked;

    setState(() {
      _newImages.addAll(limited.map((x) => File(x.path)));
    });
    state?.didChange(_newImages);

    if (picked.length > remaining) {
      _showSnack('Only $remaining more image(s) allowed. Extra ignored.');
    }
  }

  void _toggleService(String s) {
    setState(() {
      _selectedServices.contains(s)
          ? _selectedServices.remove(s)
          : _selectedServices.add(s);
    });
  }

  void _addCustomService() {
    final txt = _customServiceController.text.trim();
    if (txt.isNotEmpty && !_selectedServices.contains(txt)) {
      setState(() {
        _selectedServices.add(txt);
        _customServiceController.clear();
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final updated = widget.service.copyWith(
        vendorName: _vendorNameController.text.trim(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: _priceController.text.trim(),
        duration: _durationController.text.trim(),
        services: _selectedServices,
        images: _existingImages, // only those not removed
      );

      final repo = ServiceRepository();
      await repo.editPost(
        service: updated,
        newImages: _newImages,
        keepImages: _existingImages, // pass the ones user kept
      );

      if (!mounted) return;
      _showSnack('Service updated successfully', color: Colors.green);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to update service: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _serviceTile(String s) {
    final selected = _selectedServices.contains(s);
    return GestureDetector(
      onTap: () => _toggleService(s),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.pinkAccent : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.pink : Colors.grey.shade400,
            width: 1,
          ),
        ),
        child: Text(
          s,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: const Text(
          'Edit Service',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- Images ----------
              Text(
                'Service Images (max 7)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.pinkAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Existing images (URLs)
                  for (final img in _existingImages)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.pinkAccent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(img, fit: BoxFit.cover),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () {
                            setState(() => _existingImages.remove(img));
                          },
                        ),
                      ],
                    ),
                  // New picked images (Files)
                  for (final img in _newImages)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.pinkAccent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(img, fit: BoxFit.cover),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () {
                            setState(() => _newImages.remove(img));
                          },
                        ),
                      ],
                    ),
                  if (_existingImages.length + _newImages.length < 7)
                    GestureDetector(
                      onTap: () => _pickImages(null),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.pink[50],
                          border: Border.all(
                            color: Colors.pinkAccent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add_a_photo,
                          color: Colors.pinkAccent,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // ---------- Vendor Name ----------
              TextFormField(
                controller: _vendorNameController,
                decoration: const InputDecoration(
                  labelText: 'Vendor Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter vendor name' : null,
              ),
              const SizedBox(height: 16),

              // ---------- Title ----------
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Service Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 16),

              // ---------- Description ----------
              TextFormField(
                controller: _descriptionController,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 16),

              // ---------- Price ----------
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter price' : null,
              ),
              const SizedBox(height: 16),

              // ---------- Duration ----------
              TextFormField(
                controller: _durationController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.access_time, color: Colors.pinkAccent),
                ),
                onTap: () async {
                  // optional: implement picker like before
                },
              ),
              const SizedBox(height: 24),

              // ---------- Services ----------
              Text(
                'Select or Add Services',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.pinkAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                children: [
                  for (final s in _prebuiltServices) _serviceTile(s),
                  for (final s in _selectedServices.where(
                    (s) => !_prebuiltServices.contains(s),
                  ))
                    _serviceTile(s),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customServiceController,
                      decoration: const InputDecoration(
                        hintText: 'Add custom service',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    onPressed: _addCustomService,
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ---------- Submit ----------
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isSubmitting ? null : _submitForm,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Update Service',
                          style: TextStyle(
                            fontSize: 18,
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
}
