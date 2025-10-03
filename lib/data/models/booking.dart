class Booking {
  final String? id;
  final String clientId;
  final String vendorId;
  final String service;
  final String description;
  final String price;
  final String duration;
  final String status;
  final DateTime? createdAt; // Optional created_at field

  Booking({
    this.id,
    required this.clientId,
    required this.vendorId,
    required this.service,
    required this.description,
    required this.price,
    required this.duration,
    required this.status,
    this.createdAt,
  });

  // ------------------ JSON Serialization ------------------
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String?,
      clientId: json['client_id'] as String,
      vendorId: json['vendor_id'] as String,
      service: json['service'] as String,
      description: json['description'] as String? ?? '',
      price: json['price'].toString(),
      duration: json['duration'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'vendor_id': vendorId,
      'service': service,
      'description': description,
      'price': price,
      'duration': duration,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
