class DeliveryAddress {
  final String id;
  final String fullName;
  final String streetAddress;
  final String city;
  final String postalCode;
  final String phoneNumber;
  final bool isDefault;

  const DeliveryAddress({
    required this.id,
    required this.fullName,
    required this.streetAddress,
    required this.city,
    required this.postalCode,
    required this.phoneNumber,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'street_address': streetAddress,
      'city': city,
      'postal_code': postalCode,
      'phone_number': phoneNumber,
      'is_default': isDefault ? 1 : 0,
    };
  }

  factory DeliveryAddress.fromMap(Map<String, dynamic> map) {
    return DeliveryAddress(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      streetAddress: map['street_address'] as String,
      city: map['city'] as String,
      postalCode: map['postal_code'] as String,
      phoneNumber: map['phone_number'] as String,
      isDefault: (map['is_default'] as int? ?? 0) == 1,
    );
  }

  DeliveryAddress copyWith({
    String? id,
    String? fullName,
    String? streetAddress,
    String? city,
    String? postalCode,
    String? phoneNumber,
    bool? isDefault,
  }) {
    return DeliveryAddress(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      streetAddress: streetAddress ?? this.streetAddress,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
