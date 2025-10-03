class Post {
  final String serviceId;
  final String vendorId;
  final String vendorName;
  final String title;
  final String description;
  final String price;
  final List<String> services; // if it's like category/type
  final String duration;
  final List<String>? images; // store image URLs

  Post({
    required this.serviceId,
    required this.vendorId,
    required this.vendorName,
    required this.title,
    required this.description,
    required this.price,
    required this.services,
    required this.duration,
    this.images,
  });

  /// Create a Service from JSON
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      serviceId: json['service_id'] ?? '',
      vendorId: json['vendor_id'] ?? '',
      vendorName: json['vendor_name'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] ?? '',
      services: List<String>.from(json['services'] ?? []),
      duration: json['duration'] ?? '',
      images: List<String>.from(json['images'] ?? []),
    );
  }

  /// Convert Service to JSON
  Map<String, dynamic> toJson() {
    return {
      'service_id': serviceId,
      'vendor_id': vendorId,
      'title': title,
      'vendor_name': vendorName,
      'description': description,
      'price': price,
      'services': services,
      'duration': duration,
      'images': images,
    };
  }

  /// Copy with modifications
  Post copyWith({
    String? serviceId,
    String? vendorId,
    String? vendorName,
    String? title,
    String? description,
    String? price,
    List<String>? services,
    String? duration,
    List<String>? images,
  }) {
    return Post(
      serviceId: serviceId ?? this.serviceId,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      services: services ?? this.services,
      duration: duration ?? this.duration,
      images: images ?? this.images,
    );
  }
}
