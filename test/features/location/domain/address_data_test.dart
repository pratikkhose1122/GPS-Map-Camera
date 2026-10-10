import 'package:flutter_test/flutter_test.dart';
import 'package:geomapcam/features/location/domain/address_data.dart';

void main() {
  group('AddressData', () {
    test('creates with only required formattedAddress', () {
      const address = AddressData(
        formattedAddress: '123 Main St, City, Country',
      );

      expect(address.formattedAddress, '123 Main St, City, Country');
      expect(address.street, isNull);
      expect(address.locality, isNull);
      expect(address.administrativeArea, isNull);
      expect(address.country, isNull);
      expect(address.postalCode, isNull);
    });

    test('creates with all fields', () {
      const address = AddressData(
        formattedAddress: '123 Main St, City, State 12345, Country',
        street: 'Main St',
        locality: 'City',
        administrativeArea: 'State',
        country: 'Country',
        postalCode: '12345',
      );

      expect(
        address.formattedAddress,
        '123 Main St, City, State 12345, Country',
      );
      expect(address.street, 'Main St');
      expect(address.locality, 'City');
      expect(address.administrativeArea, 'State');
      expect(address.country, 'Country');
      expect(address.postalCode, '12345');
    });

    test('toString returns formatted address wrapper', () {
      const address = AddressData(formattedAddress: 'Unknown');
      expect(address.toString(), 'AddressData(formattedAddress: Unknown)');
    });
  });
}
