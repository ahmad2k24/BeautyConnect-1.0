import 'package:beauty_connect/data/data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> createBooking(Booking booking) async {
    await _client.from('bookings').insert(booking.toJson());
  }

  /// Stream of bookings for the currently logged-in user
  Stream<List<Booking>> streamUserBookings() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    return _client
        .from('bookings')
        .stream(primaryKey: ['id']) // make sure 'id' is primary key
        .eq('client_id', user.id)
        .order('created_at', ascending: false)
        .map((event) {
          // event is List<Map<String, dynamic>>
          return event.map((json) => Booking.fromJson(json)).toList();
        });
  }

  /// Stream of bookings for the currently logged-in Vendor
  Stream<List<Booking>> streamVendorBookings() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    return _client
        .from('bookings')
        .stream(primaryKey: ['id']) // make sure 'id' is primary key
        .eq('vendor_id', user.id)
        .order('created_at', ascending: false)
        .map((event) {
          // event is List<Map<String, dynamic>>
          return event.map((json) => Booking.fromJson(json)).toList();
        });
  }

  /// Update booking status by booking ID
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    await _client
        .from('bookings')
        .update({'status': newStatus})
        .eq('id', bookingId);
  }
}
