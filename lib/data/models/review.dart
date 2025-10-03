class Review {
  final String id;
  final String clientId;
  final String vendorId;
  final String postId;
  final String comment;
  final double rating;
  final DateTime? createdAt; // optional

  Review({
    required this.id,
    required this.clientId,
    required this.vendorId,
    required this.postId,
    required this.comment,
    required this.rating,
    this.createdAt,
  });

  // JSON serialization
  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      vendorId: json['vendor_id'] as String,
      postId: json['post_id'] as String,
      comment: json['comment'] as String,
      rating: (json['rating'] as num).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  // JSON deserialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'vendor_id': vendorId,
      'post_id': postId,
      'comment': comment,
      'rating': rating,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
