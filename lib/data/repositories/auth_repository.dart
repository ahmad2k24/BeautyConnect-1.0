// lib/repositories/auth_repository.dart
import 'dart:io';
import 'package:beauty_connect/core/core.dart';
import 'package:beauty_connect/data/data.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

class AuthRepository {
  final SupabaseClient _client = SupabaseConfig.client;
  static const String bucketName =
      'client_avatars'; // Bucket for client avatars

  /// Create account
  /// [imageFile] is a File from ImagePicker
  Future<void> createAccount({
    required String fullName,
    required String email,
    required String phone,
    required String address,
    required String password,
    required File imageFile,
  }) async {
    String filePath = '';
    try {
      // 1️⃣ Sign up the user using Supabase Auth
      final authResponse = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw AuthException('Failed to create user account');
      }

      final userId = authResponse.user!.id;

      // 2️⃣ Upload avatar image to Supabase Storage using userId in path
      filePath = '$userId/${userId}_${imageFile.path.split('/').last}';
      try {
        await _client.storage.from(bucketName).upload(filePath, imageFile);
      } catch (e, st) {
        throw NetworkException(
          'Failed to upload profile image',
          stackTrace: st,
        );
      }

      // Get public URL of the uploaded image
      final imageUrl = _client.storage.from(bucketName).getPublicUrl(filePath);

      // 3️⃣ Insert user details into 'clients' table
      try {
        await _client.from('clients').insert({
          'id': userId,
          'name': fullName,
          'email': email,
          'phone': phone,
          'address': address,
          'avatar_url': imageUrl,
        });
      } on PostgrestException catch (e) {
        // Delete uploaded image if DB insert fails
        await _client.storage.from(bucketName).remove([filePath]);
        throw UnknownException('Failed to save client data: ${e.message}');
      }
    } on NetworkException {
      rethrow;
    } on AuthException {
      rethrow;
    } on UnknownException {
      rethrow;
    } catch (e, st) {
      // Cleanup uploaded image on any other unexpected error
      if (filePath.isNotEmpty) {
        try {
          await _client.storage.from(bucketName).remove([filePath]);
        } catch (_) {}
      }
      throw UnknownException(
        'An unexpected error occurred: $e',
        stackTrace: st,
      );
    }
  }

  /// Login user with email & password
  Future<void> login({required String email, required String password}) async {
    try {
      // 1️⃣ Sign in using Supabase Auth
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw AuthException('Invalid email or password');
      }

      final userId = response.user!.id;

      // 2️⃣ Check if user exists in clients table
      final clientData = await _client
          .from('clients')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (clientData == null) {
        throw AuthException('No client record found for this user');
      }

      // ✅ User logged in successfully and exists in clients table
    } on PostgrestException catch (e) {
      throw UnknownException('Database error: ${e.message}');
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      throw UnknownException('Unexpected error: $e', stackTrace: st);
    }
  }

  //fetch client details

  Future<Client?> fetchClientData(String clientId) async {
    try {
      final response = await Supabase.instance.client
          .from('clients')
          .select()
          .eq('id', clientId)
          .single();

      return Client.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching client data: $e');
    }
    return null;
  }

  //edit client details
  Future<void> updateProfile({
    required String clientId,
    String? fullName,
    String? phone,
    String? address,
    File? imageFile, // optional: only update if user picked a new image
  }) async {
    String filePath = '';
    try {
      String? imageUrl;

      // ---------- 1️⃣ UPLOAD NEW AVATAR IF PROVIDED ----------
      if (imageFile != null) {
        // Use a consistent path to overwrite existing avatar
        filePath = '$clientId/${clientId}_${imageFile.path.split('/').last}';

        try {
          await _client.storage
              .from(bucketName)
              .update(
                filePath,
                imageFile,
                fileOptions: const FileOptions(upsert: true),
              );
        } catch (e, st) {
          throw NetworkException(
            'Failed to upload profile image',
            stackTrace: st,
          );
        }

        // Get public URL
        imageUrl = _client.storage.from(bucketName).getPublicUrl(filePath);
      }

      // ---------- 2️⃣ UPDATE CLIENT DATA ----------
      final updates = <String, dynamic>{};
      if (fullName != null) updates['name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (address != null) updates['address'] = address;
      if (imageUrl != null) updates['avatar_url'] = imageUrl;

      if (updates.isEmpty) return; // nothing to update

      try {
        await _client.from('clients').update(updates).eq('id', clientId);
      } on PostgrestException catch (e) {
        // Delete uploaded image if DB update fails
        if (imageFile != null) {
          await _client.storage.from(bucketName).remove([filePath]);
        }
        throw UnknownException('Failed to update client data: ${e.message}');
      }
    } on NetworkException {
      rethrow;
    } on UnknownException {
      rethrow;
    } catch (e, st) {
      // Cleanup uploaded image on any unexpected error
      if (filePath.isNotEmpty) {
        try {
          await _client.storage.from(bucketName).remove([filePath]);
        } catch (_) {}
      }
      throw UnknownException(
        'An unexpected error occurred: $e',
        stackTrace: st,
      );
    }
  }

  //sign out

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException {
      rethrow;
    } on NetworkException catch (e, st) {
      throw NetworkException('Network error during sign out', stackTrace: st);
    } catch (e, st) {
      throw UnknownException(
        'An unexpected error occurred during sign out: $e',
        stackTrace: st,
      );
    }
  }

  //update user role

  /// Updates the role of the current user to 'client' or 'vendor'
  Future<void> updateUserRole(String newRole) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('No logged-in user found.');
    }

    final response = await _client
        .from('clients')
        .update({'role': newRole})
        .eq('id', userId);

    if (response.error != null) {
      throw Exception('Failed to update role: ${response.error!.message}');
    }

    print('Role updated successfully to $newRole');
  }

  Future<bool> createVendorAccount({
    required Vendor vendor,
    required File imageFile,
  }) async {
    String filePath = '';
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw AuthException('No logged-in user found.');
      }

      // 2️⃣ Upload avatar image to Supabase Storage using userId in path
      filePath = '$userId/${userId}_${imageFile.path.split('/').last}';
      try {
        await _client.storage
            .from('vendor_avatars')
            .upload(filePath, imageFile);
      } catch (e, st) {
        throw NetworkException(
          'Failed to upload profile image',
          stackTrace: st,
        );
      }

      // Get public URL of the uploaded image
      final imageUrl = _client.storage
          .from('vendor_avatars')
          .getPublicUrl(filePath);

      // 3️⃣ Insert user details into 'vendors' table
      try {
        await _client.from('vendors').insert({
          'id': userId,
          'name': vendor.name,
          'information': vendor.information,
          'email': vendor.email,
          'phone': vendor.phone,
          'address': vendor.address,
          'website': vendor.website,
          'country': vendor.country,
          'experience': vendor.experience,
          'opening_time': vendor.openingTime,
          'closing_time': vendor.closingTime,
          'services': vendor.services,
          'vendor_url': imageUrl,
        });

        return true;
      } on PostgrestException catch (e) {
        // Delete uploaded image if DB insert fails
        await _client.storage.from('vendor_avatars').remove([filePath]);
        throw UnknownException('Failed to save client data: ${e.message}');
      }
    } on NetworkException {
      rethrow;
    } on AuthException {
      rethrow;
    } on UnknownException {
      rethrow;
    } catch (e, st) {
      // Cleanup uploaded image on any other unexpected error
      if (filePath.isNotEmpty) {
        try {
          await _client.storage.from('vendor_avatars').remove([filePath]);
        } catch (_) {}
      }
      throw UnknownException(
        'An unexpected error occurred: $e',
        stackTrace: st,
      );
    }
  }

  //fetch vendor details

  // Fetch a single vendor by ID
  Future<Vendor?> fetchVendorById(String? vendorId) async {
    try {
      final response = await _client
          .from('vendors')
          .select()
          .eq('id', vendorId!)
          .single();

      return Vendor.fromJson(response);
    } catch (e) {
      debugPrint('Exception while fetching vendor: $e');
      return null;
    }
  }

  // create or update vendor details
  Future<bool> editVendorAccount({
    required Vendor vendor,
    File? imageFile, // make optional ✅
  }) async {
    String filePath = '';
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw AuthException('No logged-in user found.');
      }

      String? imageUrl = vendor.vendorUrl;

      // 1️⃣ Upload avatar image if provided
      if (imageFile != null) {
        filePath = '$userId/${userId}_${imageFile.path.split('/').last}';
        try {
          await _client.storage
              .from('vendor_avatars')
              .upload(
                filePath,
                imageFile,
                fileOptions: const FileOptions(upsert: true), // allow overwrite
              );
        } catch (e, st) {
          throw NetworkException(
            'Failed to upload profile image',
            stackTrace: st,
          );
        }

        imageUrl = _client.storage
            .from('vendor_avatars')
            .getPublicUrl(filePath);
      }

      // 2️⃣ Upsert vendor row (insert if not exists, update otherwise)
      try {
        await _client.from('vendors').upsert({
          'id': userId, // use userId as primary key
          'name': vendor.name,
          'information': vendor.information,
          'email': vendor.email,
          'phone': vendor.phone,
          'address': vendor.address,
          'website': vendor.website,
          'country': vendor.country,
          'experience': vendor.experience,
          'opening_time': vendor.openingTime,
          'closing_time': vendor.closingTime,
          'services': vendor.services,
          'vendor_url': imageUrl ?? vendor.vendorUrl,
        });

        return true;
      } on PostgrestException catch (e) {
        // cleanup uploaded image if DB save fails
        if (filePath.isNotEmpty) {
          await _client.storage.from('vendor_avatars').remove([filePath]);
        }
        throw UnknownException('Failed to save vendor data: ${e.message}');
      }
    } on NetworkException {
      rethrow;
    } on AuthException {
      rethrow;
    } on UnknownException {
      rethrow;
    } catch (e, st) {
      // cleanup uploaded image on any other unexpected error
      if (filePath.isNotEmpty) {
        try {
          await _client.storage.from('vendor_avatars').remove([filePath]);
        } catch (_) {}
      }
      throw UnknownException(
        'An unexpected error occurred: $e',
        stackTrace: st,
      );
    }
  }
}
