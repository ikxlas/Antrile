class BusinessProfile {
  final String id;
  final String name;
  final String category;
  final String address;
  final String? logoUrl;
  final double rating;

  BusinessProfile({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    this.logoUrl,
    this.rating = 0.0,
  });

  factory BusinessProfile.fromMap(Map<String, dynamic> map, String id) {
    return BusinessProfile(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      address: map['address'] ?? '',
      logoUrl: map['logoUrl'],
      rating: (map['rating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'address': address,
      'logoUrl': logoUrl,
      'rating': rating,
    };
  }
}
