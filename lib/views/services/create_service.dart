import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:beauty_connect/data/data.dart'; // contains Service model & ServiceRepository
import 'package:beauty_connect/core/core.dart'; // SupabaseConfig, etc.

class CreateServiceScreen extends StatefulWidget {
  const CreateServiceScreen({super.key});

  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _vendorNameController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController(); // <- updated for picker
  final _customServiceController = TextEditingController();

  // Image & service state
  final List<File> _images = [];
  final List<String> _selectedServices = [];
  final List<String> _prebuiltServices = [
    'Make-up',
    'Hair Cutting',
    'Facial',
    'Manicure',
    'Pedicure',
  ];

  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  void _showSnack(String msg, {Color? color}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _pickImages(FormFieldState<List<File>>? state) async {
    if (_images.length >= 7) {
      _showSnack('You can select a maximum of 7 images.');
      return;
    }
    final picked = await _picker.pickMultiImage();
    if (picked.isEmpty) return;

    final remaining = 7 - _images.length;
    final limited = picked.length > remaining
        ? picked.sublist(0, remaining)
        : picked;

    setState(() {
      _images.addAll(limited.map((x) => File(x.path)));
    });
    state?.didChange(_images);

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

  /// Time Picker for duration – now formats as “X h Y min”
  Future<void> _pickDuration() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 0, minute: 30),
      helpText: 'Select Service Duration',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final int hours = picked.hour;
      final int minutes = picked.minute;

      // ✅ Build a user-friendly label: “1 h 30 min”, “45 min”, etc.
      String label = '';
      if (hours > 0) label += '$hours h';
      if (minutes > 0) {
        if (label.isNotEmpty) label += ' ';
        label += '$minutes min';
      }
      if (label.isEmpty) label = '0 min'; // fallback

      // Persist the display string (e.g., “1 h 30 min”)
      _durationController.text = label;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final service = Post(
        serviceId: DateTime.now().millisecondsSinceEpoch.toString(),
        vendorId: SupabaseConfig.client.auth.currentUser!.id,
        vendorName: _vendorNameController.text.trim(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: _priceController.text.trim(),
        duration: _durationController.text.trim(), // already HH:mm
        services: _selectedServices,
      );

      final repo = ServiceRepository();
      await repo.createPost(service: service, images: _images);

      if (!mounted) return;
      _showSnack(' Service created successfully', color: Colors.green);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showSnack('❌ Failed to create service: $e', color: Colors.red);
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

  // ✅ New subscription state
  bool _hasActiveSubscription = false;
  bool _loadingSubscription = true;

  @override
  void initState() {
    super.initState();
    checkSubscriptionStatus();
  }

  /// Check if user has an active subscription
  Future<void> checkSubscriptionStatus() async {
    setState(() => _loadingSubscription = true);

    try {
      final userId = SupabaseConfig.client.auth.currentUser!.id;

      final response = await SupabaseConfig.client
          .from('subscriptions')
          .select('subscription_expiry, status')
          .eq('user_id', userId)
          .order('subscription_expiry', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        _hasActiveSubscription = false;
      } else {
        final expiryDate = DateTime.parse(
          response['subscription_expiry'],
        ).toUtc();
        final now = DateTime.now().toUtc();
        final rawStatus = (response['status'] ?? '').toString().toLowerCase();

        _hasActiveSubscription =
            rawStatus == 'active' && expiryDate.isAfter(now);
      }
    } catch (e) {
      _hasActiveSubscription = false;
      print('Error checking subscription: $e');
    }

    if (mounted) {
      setState(() => _loadingSubscription = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: const Text(
          'Create Service',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loadingSubscription
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (!_hasActiveSubscription)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade400),
                      ),
                      child: const Text(
                        '⚠️ Please buy a subscription plan first to create a service.',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---------- Images ----------
                        Text(
                          'Upload Images (max 7)',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.pinkAccent,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        FormField<List<File>>(
                          initialValue: _images,
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Please select at least one image'
                              : null,
                          builder: (state) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final img in _images)
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
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.file(
                                              img,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.cancel,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            setState(() => _images.remove(img));
                                            state.didChange(_images);
                                          },
                                        ),
                                      ],
                                    ),
                                  if (_images.length < 7)
                                    GestureDetector(
                                      onTap: () => _pickImages(state),
                                      child: Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: Colors.pink[50],
                                          border: Border.all(
                                            color: Colors.pinkAccent,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.add_a_photo,
                                          color: Colors.pinkAccent,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (state.hasError)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    state.errorText ?? '',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 24,
                        ), // ---------- Vendor Name ----------
                        TextFormField(
                          controller: _vendorNameController,
                          decoration: const InputDecoration(
                            labelText: 'Vendor Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Enter vendor name'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // ---------- Title ----------
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Service Title',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Enter title' : null,
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
                          validator: (v) => v == null || v.isEmpty
                              ? 'Enter description'
                              : null,
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
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Enter price' : null,
                        ),
                        const SizedBox(height: 16),

                        // ---------- Duration (Time Picker) ----------
                        GestureDetector(
                          onTap: _pickDuration,
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: _durationController,
                              decoration: const InputDecoration(
                                labelText: 'Duration (HH:mm)',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(
                                  Icons.access_time,
                                  color: Colors.pinkAccent,
                                ),
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Please pick service duration'
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ---------- Services ----------
                        Text(
                          'Select or Add Services',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.pinkAccent,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        FormField<List<String>>(
                          validator: (_) => _selectedServices.isEmpty
                              ? 'Please select at least one service'
                              : null,
                          builder: (state) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                children: [
                                  for (final s in _prebuiltServices)
                                    _serviceTile(s),
                                  for (final s in _selectedServices.where(
                                    (s) => !_prebuiltServices.contains(s),
                                  ))
                                    _serviceTile(s),
                                ],
                              ),
                              if (state.hasError)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    state.errorText ?? '',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                            ],
                          ),
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
                            onPressed:
                                (!_hasActiveSubscription || _isSubmitting)
                                ? null
                                : _submitForm,
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
                                    'Create Service',
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
                ],
              ),
            ),
    );
  }
}
