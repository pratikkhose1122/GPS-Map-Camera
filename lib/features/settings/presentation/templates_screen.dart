import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_location_code/open_location_code.dart' as olc;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:geomapcam/core/providers/settings_provider.dart';
import 'package:geomapcam/core/providers/locations_provider.dart';
import 'package:geomapcam/features/location/data/location_service.dart';
import 'package:geomapcam/features/overlay/domain/models/overlay_template.dart';
import 'package:geomapcam/features/overlay/domain/overlay_snapshot.dart';

class TemplatesScreen extends StatelessWidget {
  final OverlaySnapshot? snapshot;

  const TemplatesScreen({super.key, this.snapshot});

  static String _getCountryFlag(String? countryName) {
    if (countryName == null || countryName.isEmpty) return '';
    final lower = countryName.toLowerCase().trim();
    if (lower == 'india' || lower == 'in') return '🇮🇳';
    if (lower == 'united states' || lower == 'usa' || lower == 'us') return '🇺🇸';
    if (lower == 'united kingdom' || lower == 'uk' || lower == 'gb') return '🇬🇧';
    if (lower == 'canada' || lower == 'ca') return '🇨🇦';
    if (lower == 'australia' || lower == 'au') return '🇦🇺';
    if (lower == 'germany' || lower == 'de') return '🇩🇪';
    if (lower == 'france' || lower == 'fr') return '🇫🇷';
    if (lower == 'japan' || lower == 'jp') return '🇯🇵';
    if (lower == 'brazil' || lower == 'br') return '🇧🇷';
    return '📍';
  }

  @override
  Widget build(BuildContext context) {
    final settingsService = SettingsProvider.of(context);
    final locationsService = LocationsProvider.of(context);
    final locationService = LocationService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Template')),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          settingsService,
          locationsService,
          locationService,
        ]),
        builder: (context, _) {
          final isLive = locationsService.isLiveMode;
          final savedLoc = locationsService.selectedLocation;

          double? lat;
          double? lng;
          String? fullAddress;
          String? locality;
          String? adminArea;
          String? country;

          if (!isLive && savedLoc != null) {
            lat = savedLoc.latitude;
            lng = savedLoc.longitude;
            fullAddress = savedLoc.address;
            locality = savedLoc.name;
          } else if (snapshot != null &&
              snapshot!.latitude != null &&
              snapshot!.latitude != 0.0) {
            lat = snapshot!.latitude;
            lng = snapshot!.longitude;
            fullAddress = snapshot!.address;
            locality = locationService.addressData?.locality;
            adminArea = locationService.addressData?.administrativeArea;
            country = locationService.addressData?.country;
          } else if (locationService.locationData != null) {
            lat = locationService.locationData!.latitude;
            lng = locationService.locationData!.longitude;
            fullAddress = locationService.addressData?.formattedAddress;
            locality = locationService.addressData?.locality;
            adminArea = locationService.addressData?.administrativeArea;
            country = locationService.addressData?.country;
          }

          // Build dynamic location title (e.g., "Kalyan, Maharashtra, India 🇮🇳")
          final titleParts = <String>[];
          if (locality != null && locality.isNotEmpty) titleParts.add(locality);
          if (adminArea != null && adminArea.isNotEmpty) titleParts.add(adminArea);
          if (country != null && country.isNotEmpty) titleParts.add(country);

          String locationTitle;
          if (titleParts.isNotEmpty) {
            final flag = _getCountryFlag(country);
            locationTitle = '${titleParts.join(', ')}${flag.isNotEmpty ? ' $flag' : ''}';
          } else if (fullAddress != null && fullAddress.isNotEmpty) {
            final parts = fullAddress.split(',').map((e) => e.trim()).toList();
            if (parts.length >= 2) {
              locationTitle = parts.take(2).join(', ');
            } else {
              locationTitle = fullAddress;
            }
          } else if (lat != null && lng != null) {
            locationTitle =
                'Lat ${lat.toStringAsFixed(4)}°, Long ${lng.toStringAsFixed(4)}°';
          } else {
            locationTitle = 'Acquiring location...';
          }

          // Build dynamic coordinates
          final coordStr = (lat != null && lng != null)
              ? 'Lat ${lat.toStringAsFixed(6)}° Long ${lng.toStringAsFixed(6)}°'
              : 'GPS Coordinates Unavailable';

          // Encode Plus Code dynamically
          String? plusCode;
          if (!isLive && savedLoc != null && savedLoc.plusCode != null) {
            plusCode = savedLoc.plusCode;
          } else if (lat != null && lng != null) {
            try {
              plusCode = olc.PlusCode.encode(olc.LatLng(lat, lng)).toString();
            } catch (_) {
              plusCode = null;
            }
          }

          // Build address details line
          String addressLine;
          if (fullAddress != null && fullAddress.isNotEmpty) {
            if (plusCode != null && !fullAddress.contains(plusCode)) {
              addressLine = '$plusCode, $fullAddress';
            } else {
              addressLine = fullAddress;
            }
          } else if (plusCode != null) {
            addressLine = plusCode;
          } else if (lat != null && lng != null) {
            addressLine =
                'GPS: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
          } else {
            addressLine = 'Locating address...';
          }

          // Real-time Date & Time
          final now = DateTime.now();
          final timeStr = DateFormat('hh:mm a').format(now);
          final dateStr = DateFormat('dd MMMM yyyy').format(now);
          final dayStr = DateFormat('EEEE').format(now);
          final fullDateStr =
              DateFormat('EEEE, dd/MM/yyyy hh:mm a').format(now);
          final offset = now.timeZoneOffset;
          final sign = offset.isNegative ? '-' : '+';
          final hours = offset.inHours.abs().toString().padLeft(2, '0');
          final minutes =
              (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
          final gmtStr = 'GMT $sign$hours:$minutes';
          final dateTimeFullStr = '$fullDateStr $gmtStr';

          // Dynamic QR data
          final qrData = (lat != null && lng != null)
              ? '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}\n${fullAddress ?? locationTitle}'
              : 'Location Unavailable';

          return ListView.separated(
            padding: const EdgeInsets.only(top: 16, bottom: 80),
            itemCount: OverlayTemplate.values.length,
            separatorBuilder: (context, index) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              final template = OverlayTemplate.values[index];
              final isSelected =
                  settingsService.selectedTemplate.id == template.id;

              return _TemplatePreviewCard(
                template: template,
                isSelected: isSelected,
                locationTitle: locationTitle,
                addressLine: addressLine,
                coordStr: coordStr,
                dateTimeFullStr: dateTimeFullStr,
                timeStr: timeStr,
                dateStr: dateStr,
                dayStr: dayStr,
                qrData: qrData,
                onTap: () => settingsService.setTemplate(template),
              );
            },
          );
        },
      ),
      // Floating action button with select symbol (checkmark) to confirm and exit
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context, settingsService.selectedTemplate);
        },
        backgroundColor: const Color(0xFFFFC107), // Yellow accent
        foregroundColor: Colors.white,
        tooltip: 'Select Template',
        child: const Icon(Icons.check, size: 28), // Select / checkmark symbol
      ),
    );
  }
}

class _TemplatePreviewCard extends StatelessWidget {
  final OverlayTemplate template;
  final bool isSelected;
  final String locationTitle;
  final String addressLine;
  final String coordStr;
  final String dateTimeFullStr;
  final String timeStr;
  final String dateStr;
  final String dayStr;
  final String qrData;
  final VoidCallback onTap;

  const _TemplatePreviewCard({
    required this.template,
    required this.isSelected,
    required this.locationTitle,
    required this.addressLine,
    required this.coordStr,
    required this.dateTimeFullStr,
    required this.timeStr,
    required this.dateStr,
    required this.dayStr,
    required this.qrData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerColor = isSelected
        ? theme.colorScheme.primary
        : (theme.brightness == Brightness.dark
              ? Colors.white70
              : const Color(0xFF2C3E50));

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 4.0),
            child: Row(
              children: [
                Text(
                  '${template.name} Template',
                  style: TextStyle(
                    color: headerColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.check_circle,
                    size: 15,
                    color: theme.colorScheme.primary,
                  ),
                ],
                if (template == OverlayTemplate.scanLocation)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'New',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Stack(
            children: [
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 100),
                color: const Color(0xFF5B5D5F), // Dark grey container
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_hasMap(template))
                        Stack(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Image.asset(
                                'assets/images/map_preview.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                            if (template == OverlayTemplate.reporting)
                              Positioned(
                                top: 4,
                                left: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Check In',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      if (template == OverlayTemplate.navigationCompass)
                        Container(
                          width: 120,
                          color: const Color(0xFF4B4D4F),
                          child: const Center(
                            child: Icon(
                              Icons.explore_outlined,
                              size: 64,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (template == OverlayTemplate.dateTime) ...[
                                _buildDateTimeHeader(),
                                const SizedBox(height: 4),
                                Text(
                                  locationTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '$addressLine\n$coordStr',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ] else ...[
                                _buildStandardContent(),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (template == OverlayTemplate.scanLocation)
                        Container(
                          width: 80,
                          margin: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: 64.0,
                            ),
                          ),
                        ),
                      if (template == OverlayTemplate.navigationCompass)
                        Container(
                          width: 80,
                          margin: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            'assets/images/map_preview.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (isSelected)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    color: theme.colorScheme.primary, // Orange indicator stripe
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  bool _hasMap(OverlayTemplate template) {
    return template == OverlayTemplate.advance ||
        template == OverlayTemplate.classic ||
        template == OverlayTemplate.scanLocation ||
        template == OverlayTemplate.reporting;
  }

  Widget _buildDateTimeHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          timeStr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(width: 2, height: 28, color: const Color(0xFFFFC107)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dateStr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              dayStr,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStandardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          locationTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          '$addressLine\n$coordStr\n$dateTimeFullStr',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            height: 1.25,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
