class Vendor {
  final String name;
  final String information;
  final String email;
  final String phone;
  final String address;
  final String website;
  final String country;
  final String experience;
  final String openingTime;
  final String closingTime;
  final List<String> services;
  final String? vendorUrl;
  final DateTime? createdAt; // Added field

  Vendor({
    required this.name,
    required this.information,
    required this.email,
    required this.phone,
    required this.address,
    required this.website,
    required this.country,
    required this.experience,
    required this.openingTime,
    required this.closingTime,
    required this.services,
    this.vendorUrl,
    this.createdAt, // Add to constructor
  });

  Vendor copyWith({
    String? name,
    String? information,
    String? email,
    String? phone,
    String? address,
    String? website,
    String? country,
    String? experience,
    String? openingTime,
    String? closingTime,
    List<String>? services,
    String? vendorProfile,
    DateTime? createdAt, // Add copyWith
  }) {
    return Vendor(
      name: name ?? this.name,
      information: information ?? this.information,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      website: website ?? this.website,
      country: country ?? this.country,
      experience: experience ?? this.experience,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      services: services ?? List.from(this.services),
      vendorUrl: vendorProfile ?? this.vendorUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'information': information,
      'email': email,
      'phone': phone,
      'address': address,
      'website': website,
      'country': country,
      'experience': experience,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'services': services,
      'vendorProfile': vendorUrl,
      'createdAt': createdAt?.toIso8601String(), // Store as ISO string
    };
  }

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      name: json['name'] ?? '',
      information: json['information'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      website: json['website'] ?? '',
      country: json['country'] ?? '',
      experience: json['experience'] ?? '',
      openingTime: json['openingTime'] ?? '',
      closingTime: json['closingTime'] ?? '',
      services: json['services'] != null
          ? List<String>.from(json['services'])
          : [],
      vendorUrl: json['vendor_url'] ?? json['vendorProfile'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null, // Parse DateTime
    );
  }

  String get joinedDateFormatted => createdAt != null
      ? "${createdAt!.day}-${createdAt!.month}-${createdAt!.year}"
      : "N/A";
}
