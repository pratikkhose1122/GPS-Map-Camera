// Domain model for overlay templates
enum MapPosition { bottomRight, topRight, hidden }

enum MetadataGrouping { spread, compact, stacked }

enum BackgroundTreatment { gradient, solidBox, none }

class TemplateTypography {
  final double addressSize;
  final double coordsSize;
  final double timeSize;

  const TemplateTypography({
    required this.addressSize,
    required this.coordsSize,
    required this.timeSize,
  });
}

class OverlayTemplate {
  final String id;
  final String name;
  final TemplateTypography typography;
  final MapPosition mapPosition;
  final MetadataGrouping grouping;
  final BackgroundTreatment background;
  final bool showMap;
  final bool showAddress;
  final bool showCoordinates;
  final bool showDateTime;
  final bool showAltitudeAndAccuracy;
  final bool showHeading;
  final bool
  showCompass; // Specifically for a visual compass or prominent heading
  final bool showPlusCode;
  final bool showTimezone;
  final bool showNote;
  final bool showCustomFields;

  const OverlayTemplate({
    required this.id,
    required this.name,
    required this.typography,
    required this.mapPosition,
    required this.grouping,
    required this.background,
    required this.showMap,
    this.showAddress = true,
    this.showCoordinates = true,
    this.showDateTime = true,
    required this.showAltitudeAndAccuracy,
    this.showHeading = true,
    this.showCompass = false,
    this.showPlusCode = true,
    this.showTimezone = true,
    this.showNote = true,
    this.showCustomFields = true,
  });

  static const OverlayTemplate classic = OverlayTemplate(
    id: 'classic',
    name: 'Classic',
    typography: TemplateTypography(
      addressSize: 36,
      coordsSize: 28,
      timeSize: 28,
    ),
    mapPosition: MapPosition.bottomRight,
    grouping: MetadataGrouping.spread,
    background: BackgroundTreatment.gradient,
    showMap: true,
    showAltitudeAndAccuracy: true,
  );

  static const OverlayTemplate dateTime = OverlayTemplate(
    id: 'datetime',
    name: 'DateTime',
    typography: TemplateTypography(
      addressSize: 32,
      coordsSize: 24,
      timeSize: 36,
    ),
    mapPosition: MapPosition.hidden,
    grouping: MetadataGrouping.stacked,
    background: BackgroundTreatment.solidBox,
    showMap: false,
    showAltitudeAndAccuracy: true,
  );

  static const OverlayTemplate advance = OverlayTemplate(
    id: 'advance',
    name: 'Advance',
    typography: TemplateTypography(
      addressSize: 34,
      coordsSize: 26,
      timeSize: 26,
    ),
    mapPosition: MapPosition.bottomRight,
    grouping: MetadataGrouping.stacked,
    background: BackgroundTreatment.solidBox,
    showMap: true,
    showAltitudeAndAccuracy: true,
  );

  static const OverlayTemplate navigationCompass = OverlayTemplate(
    id: 'navigation_compass',
    name: 'Navigation Compass',
    typography: TemplateTypography(
      addressSize: 32,
      coordsSize: 30,
      timeSize: 26,
    ),
    mapPosition: MapPosition.hidden,
    grouping: MetadataGrouping.stacked,
    background: BackgroundTreatment.gradient,
    showMap: false,
    showAltitudeAndAccuracy: true,
    showCompass: true,
    showPlusCode: false,
    showNote: false,
    showCustomFields: false,
  );

  static const OverlayTemplate reporting = OverlayTemplate(
    id: 'reporting',
    name: 'Reporting',
    typography: TemplateTypography(
      addressSize: 36,
      coordsSize: 28,
      timeSize: 28,
    ),
    mapPosition: MapPosition.topRight,
    grouping: MetadataGrouping.spread,
    background: BackgroundTreatment.solidBox,
    showMap: true,
    showAltitudeAndAccuracy: true,
  );

  static const OverlayTemplate scanLocation = OverlayTemplate(
    id: 'scan_location',
    name: 'Scan Location',
    typography: TemplateTypography(
      addressSize: 34,
      coordsSize: 26,
      timeSize: 26,
    ),
    mapPosition: MapPosition.hidden,
    grouping: MetadataGrouping.stacked,
    background: BackgroundTreatment.gradient,
    showMap: true,
    showAltitudeAndAccuracy: false,
    showHeading: false,
    showCustomFields: false,
  );

  static const List<OverlayTemplate> values = [
    advance,
    dateTime,
    scanLocation,
    classic,
    reporting,
    navigationCompass,
  ];

  static OverlayTemplate fromId(String id) {
    return values.firstWhere((t) => t.id == id, orElse: () => classic);
  }
}
