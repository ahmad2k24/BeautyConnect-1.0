import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:uuid/uuid.dart';
import 'package:beauty_connect/data/data.dart'; // Import your Review model and repository

class WriteReviewScreen extends StatefulWidget {
  final String clientId;
  final String vendorId;
  final String postId;

  const WriteReviewScreen({
    super.key,
    required this.clientId,
    required this.vendorId,
    required this.postId,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final TextEditingController _commentController = TextEditingController();
  double _rating = 0.0;
  bool _isSubmitting = false;

  final ReviewRepository reviewRepo =
      ReviewRepository(); // Implement your repository

  final BookingRepository bookingRepo = BookingRepository();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Write a Review"),
        backgroundColor: isDark ? Colors.black : Colors.pinkAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Comment TextField
              Text(
                "Your Comment",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "Write your experience here...",
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Rating Stars
              Text(
                "Your Rating",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              RatingBar.builder(
                initialRating: 0,
                minRating: 0,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 36,
                unratedColor: isDark
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
                itemBuilder: (context, _) =>
                    Icon(Icons.star, color: Colors.pinkAccent),
                onRatingUpdate: (rating) {
                  setState(() {
                    _rating = rating;
                  });
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Submit Review",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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

  Future<void> _submitReview() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty || _rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide a comment and rating.")),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final review = Review(
        id: const Uuid().v4(), // generate unique ID
        postId: widget.postId,
        clientId: widget.clientId,
        vendorId: widget.vendorId,
        comment: comment,
        rating: _rating,
        createdAt: DateTime.now(),
      );

      await reviewRepo.createReview(review); // implement your DB insert method
      await bookingRepo.updateBookingStatus(widget.postId, 'Reviewed');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Review submitted successfully!")),
      );

      Navigator.pop(context); // go back after submission
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to submit review: $e")));
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}
