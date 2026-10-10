/// Represents human-readable address information from reverse geocoding.
class AddressData {
  const AddressData({
    required this.formattedAddress,
    this.street,
    this.locality,
    this.administrativeArea,
    this.country,
    this.postalCode,
  });

  /// The full readable address (e.g., "1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA").
  final String formattedAddress;

  final String? street;
  final String? locality;
  final String? administrativeArea;
  final String? country;
  final String? postalCode;

  @override
  String toString() => 'AddressData(formattedAddress: $formattedAddress)';
}
