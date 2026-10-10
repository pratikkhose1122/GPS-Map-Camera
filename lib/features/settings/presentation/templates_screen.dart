import 'package:flutter/material.dart';
import 'package:geomapcam/core/providers/settings_provider.dart';
import 'package:geomapcam/features/overlay/domain/models/overlay_template.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Template')),
      body: ListenableBuilder(
        listenable: SettingsProvider.of(context),
        builder: (context, _) {
          final settingsService = SettingsProvider.of(context);
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
                onTap: () => settingsService.setTemplate(template),
              );
            },
          );
        },
      ),
      // Adding a floating edit button just like the reference screenshot
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open edit options or return to camera
          Navigator.pop(context);
        },
        backgroundColor: const Color(0xFFFFC107), // Yellow from screenshot
        foregroundColor: Colors.white,
        child: const Icon(Icons.edit),
      ),
    );
  }
}

class _TemplatePreviewCard extends StatelessWidget {
  final OverlayTemplate template;
  final bool isSelected;
  final VoidCallback onTap;

  const _TemplatePreviewCard({
    required this.template,
    required this.isSelected,
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
            padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
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
                color: const Color(
                  0xFF5B5D5F,
                ), // Dark grey mimicking the exact screenshot style
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
                                _buildSimulatedTextContent(),
                                const SizedBox(height: 4),
                                const Text(
                                  'Newasa, Maharashtra, India 🇮🇳',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  '9rvr+xwh, Newasa, Maharashtra 414105, India\nLat 19.392653° Long 74.843053°',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ] else ...[
                                _buildSimulatedTextContent(),
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
                              data:
                                  '19.392653, 74.843053\nNewasa, Maharashtra 414105, India',
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

  Widget _buildSimulatedTextContent() {
    if (template == OverlayTemplate.dateTime) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            '01:14 PM',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 2, height: 28, color: const Color(0xFFFFC107)),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '06 October 2026',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Tuesday',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      );
    }

    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Newasa, Maharashtra, India 🇮🇳',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4),
        Text(
          '9rvr+xwh, Newasa, Maharashtra 414105, India\nLat 19.392653° Long 74.843053°\nTuesday, 06/10/2026 01:14 PM GMT +05:30',
          style: TextStyle(color: Colors.white70, fontSize: 10),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
