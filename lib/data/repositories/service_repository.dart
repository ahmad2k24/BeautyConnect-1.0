import 'dart:io';

import 'package:beauty_connect/core/core.dart';
import 'package:beauty_connect/data/data.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

class ServiceRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Creates a service entry:
  /// 1. Uploads all images to the `services` bucket
  /// 2. Inserts metadata into `services` table
  Future<void> createPost({
    required Post service,
    required List<File> images,
  }) async {
    if (images.isEmpty) {
      throw Exception("At least one image is required");
    }

    final imageUrls = <String>[];

    // Upload all images and collect public URLs
    for (final file in images) {
      p.extension(file.path);
      final uniqueName =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
      final storagePath = 'services/$uniqueName';

      await _client.storage.from('services').upload(storagePath, file);
      imageUrls.add(_client.storage.from('services').getPublicUrl(storagePath));
    }

    // Insert the service row — **v2 syntax**
    await _client.from('services').insert({
      'service_id': service.serviceId,
      'vendor_id': service.vendorId,
      'vendor_name': service.vendorName,
      'title': service.title,
      'description': service.description,
      'price': service.price,
      'duration': service.duration,
      'services': service.services,
      'images': imageUrls,
    });
  }

  /// Emits a live list of Service models belonging to the logged-in vendor.
  Stream<List<Post>> streamVendorPosts(final String userId) {
    return _client
        .from('services')
        .stream(primaryKey: ['id'])
        .eq('vendor_id', userId)
        .order('created_at', ascending: false)
        .map((rows) {
          try {
            return rows.map((r) => Post.fromJson(r)).toList();
          } catch (e, st) {
            // Log detailed parse issues so you see exactly what’s wrong
            print('Service parsing error: $e\n$st\nRaw rows: $rows');
            rethrow;
          }
        });
  }

  Future<void> deletePosts(String serviceId) async {
    await _client.from('services').delete().eq('service_id', serviceId);
  }

  /// Stream all services except the current user's services
  Stream<List<Post>> streamAllPosts(String currentUserId) {
    return _client
        .from('services')
        .stream(primaryKey: ['id']) // primary key column in your table
        .neq('vendor_id', currentUserId) // exclude current user's services
        .order('created_at', ascending: false) // optional sorting
        .map((rows) => rows.map((row) => Post.fromJson(row)).toList());
  }

  Future<void> editPost({
    required Post service,
    required List<File> newImages,
    required List<String> keepImages, // 👈 incoming kept old images
  }) async {
    final imageUrls = <String>[];

    // Upload new images
    if (newImages.isNotEmpty) {
      for (final file in newImages) {
        final uniqueName =
            '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
        final storagePath = 'services/$uniqueName';

        await _client.storage.from('services').upload(storagePath, file);
        imageUrls.add(
          _client.storage.from('services').getPublicUrl(storagePath),
        );
      }
    }

    // Final merged images = kept old + newly uploaded
    final mergedImages = [...keepImages, ...imageUrls];

    final updateData = {
      'vendor_name': service.vendorName,
      'title': service.title,
      'description': service.description,
      'price': service.price,
      'duration': service.duration,
      'services': service.services,
      'images': mergedImages,
    };

    try {
      await _client
          .from('services')
          .update(updateData)
          .eq('service_id', service.serviceId)
          .select()
          .single();
    } catch (e) {
      throw Exception('Failed to update service: $e');
    }
  }

  Future<Vendor?> fetchVendorProfile(String vendorId) async {
    try {
      final response = await _client
          .from('vendors') // 👈 change to 'profiles' if you store vendors there
          .select()
          .eq('id', vendorId)
          .maybeSingle();

      return response != null ? Vendor.fromJson(response) : null;
    } catch (e) {
      throw Exception("Error fetching vendor profile: $e");
    }
  }

  Future<Client?> fetchClientProfile(String clientId) async {
    try {
      final response = await _client
          .from('clients') // 👈 change to 'profiles' if you store vendors there
          .select()
          .eq('id', clientId)
          .maybeSingle();

      return response != null ? Client.fromJson(response) : null;
    } catch (e) {
      throw Exception("Error fetching client profile: $e");
    }
  }
}
