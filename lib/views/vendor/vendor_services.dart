import 'dart:developer';

import 'package:beauty_connect/core/core.dart'; // AppTheme.primaryPink etc.
import 'package:beauty_connect/data/data.dart'; // Service + ServiceRepository
import 'package:beauty_connect/views/views.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class VendorServices extends StatelessWidget {
  VendorServices({super.key});

  final ServiceRepository _serviceRepo = ServiceRepository();
  final String userId = SupabaseConfig.client.auth.currentUser!.id;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Services'),
        backgroundColor: AppTheme.primaryPink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: StreamBuilder<List<Post>>(
          stream: _serviceRepo.streamVendorPosts(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              log('Error fetching services: ${snapshot.error}');
              return const Center(child: Text('Error fetching services'));
            }

            final services = snapshot.data ?? [];
            if (services.isEmpty) {
              return const Center(child: Text('No services found'));
            }

            return ListView.separated(
              itemCount: services.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, i) =>
                  _ServiceCard(service: services[i], repo: _serviceRepo),
            );
          },
        ),
      ),
    );
  }
}

class _ServiceCard extends StatefulWidget {
  final Post service;
  final ServiceRepository repo;
  const _ServiceCard({required this.service, required this.repo});

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  int _currentImage = 0;

  @override
  Widget build(BuildContext context) {
    final images = List<String>.from(widget.service.images ?? []);

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Image slider ---
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                PageView.builder(
                  itemCount: images.length,
                  onPageChanged: (index) =>
                      setState(() => _currentImage = index),
                  itemBuilder: (context, i) => Image.network(
                    images[i],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(child: Icon(Icons.broken_image)),
                    ),
                  ),
                ),
                if (images.isNotEmpty)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentImage + 1}/${images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // --- Service details ---
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.service.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryPink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.service.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      // ✅ Add Euro sign
                      '€ ${widget.service.price}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      widget.service.duration,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // --- Buttons ---
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditServiceScreen(service: widget.service),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Delete'),
                        onPressed: () => _confirmDelete(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Show Cupertino bottom sheet and delete if confirmed
  void _confirmDelete(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Delete Service'),
        message: const Text(
          'Do you really want to delete this service? This action cannot be undone.',
        ),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx); // close sheet first
              try {
                await widget.repo.deletePosts(widget.service.serviceId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Service deleted')),
                );
              } catch (e, st) {
                log('Delete error: $e', stackTrace: st);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete service')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}
