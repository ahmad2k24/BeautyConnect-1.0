import 'package:beauty_connect/data/data.dart'; // Review model
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Create a new review and return the created Review object
  Future<Review> createReview(Review review) async {
    try {
      final response = await _client
          .from('reviews')
          .insert({
            'id': review.id,
            'post_id': review.postId,
            'client_id': review.clientId,
            'vendor_id': review.vendorId,
            'comment': review.comment,
            'rating': review.rating,
          })
          .select()
          .maybeSingle(); // <- select() to return the inserted row

      if (response == null) {
        throw Exception('Failed to create review');
      }

      return Review.fromJson(response);
    } catch (e) {
      throw Exception('Error creating review: $e');
    }
  }

  /// Fetch reviews for a vendor
  Future<List<Review>> getVendorReviews(String vendorId) async {
    try {
      final response = await _client
          .from('reviews')
          .select()
          .eq('vendor_id', vendorId)
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      return data.map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error fetching reviews: $e');
    }
  }
}
