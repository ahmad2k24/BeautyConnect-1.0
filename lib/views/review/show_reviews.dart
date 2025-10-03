import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ShowReviewScreen extends StatefulWidget {
  const ShowReviewScreen({super.key});

  @override
  State<ShowReviewScreen> createState() => _ShowReviewScreenState();
}

class _ShowReviewScreenState extends State<ShowReviewScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    setState(() => _loading = true);
    debugPrint('Fetching reviews...');

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('User not logged in');
        setState(() => _loading = false);
        return;
      }

      debugPrint('Current User ID: $userId');

      // Fetch reviews for current user
      final List<dynamic> response = await _client
          .from('reviews')
          .select('id, rating, comment, created_at')
          .eq('client_id', userId)
          .order('created_at', ascending: false);

      debugPrint('Raw response: $response');

      // Convert to List<Map<String, dynamic>>
      _reviews = response.map((e) {
        debugPrint('Review item: $e');
        return Map<String, dynamic>.from(e as Map);
      }).toList();

      debugPrint('Total reviews fetched: ${_reviews.length}');

      setState(() => _loading = false);
    } catch (e, st) {
      setState(() => _loading = false);
      debugPrint('Error fetching reviews: $e');
      debugPrint('Stack trace: $st');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to fetch reviews')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reviews'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
          ? const Center(
              child: Text('No reviews found.', style: TextStyle(fontSize: 16)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _reviews.length,
              itemBuilder: (context, index) {
                final review = _reviews[index];
                final createdAt = review['created_at'] != null
                    ? DateTime.tryParse(review['created_at']) ?? DateTime.now()
                    : DateTime.now();
                final formattedDate = DateFormat(
                  'dd MMM yyyy',
                ).format(createdAt);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service ID: ${review['service_id']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Rating: '),
                            ...List.generate(
                              (review['rating'] ?? 0),
                              (_) => const Icon(
                                Icons.star,
                                color: Colors.orange,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          review['comment'] ?? '-',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Reviewed on: $formattedDate',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
