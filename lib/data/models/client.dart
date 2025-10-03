/// A model representing an application client/user.
class Client {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? address; // optional
  final String? clientUrl; // optional avatar/profile picture
  final String role;
  final DateTime createdAt;

  Client({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.address,
    this.clientUrl,
    required this.role,
    required this.createdAt,
  });

  /// Factory constructor to create a [Client] from a JSON map.
  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'No Name',
      email: json['email'] as String? ?? 'No Email',
      phone: json['phone'] as String? ?? 'No Phone',
      address: json['address'] as String?,
      clientUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'client',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Converts this [Client] instance into a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'profileImageUrl': clientUrl,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Optional: helper to copy and modify fields immutably.
  Client copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? profileImageUrl,
    String? role,
    DateTime? createdAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      clientUrl: profileImageUrl ?? this.clientUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Helper to display a friendly join date string
  String get joinedDateFormatted =>
      "${createdAt.day}-${createdAt.month}-${createdAt.year}";
}
