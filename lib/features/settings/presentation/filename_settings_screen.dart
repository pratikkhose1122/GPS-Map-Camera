import 'package:flutter/material.dart';
import 'package:geomapcam/core/providers/settings_provider.dart';
import 'package:geomapcam/features/settings/data/settings_service.dart';
import 'package:geomapcam/features/storage/domain/models/filename_configuration.dart';
import 'package:geomapcam/features/storage/utils/filename_generator.dart';
import 'package:geomapcam/features/capture/domain/capture_metadata.dart';
import 'package:geomapcam/features/overlay/domain/overlay_snapshot.dart';
import 'package:geomapcam/features/overlay/domain/models/overlay_template.dart';
import 'package:geomapcam/features/location/data/location_service.dart';

class FilenameSettingsScreen extends StatefulWidget {
  const FilenameSettingsScreen({super.key});

  @override
  State<FilenameSettingsScreen> createState() => _FilenameSettingsScreenState();
}

class _FilenameSettingsScreenState extends State<FilenameSettingsScreen> {
  // Metadata to generate a realistic preview
  late CaptureMetadata _previewMetadata;

  @override
  void initState() {
    super.initState();
    final locService = LocationService.instance;
    final loc = locService.locationData;
    final addr = locService.addressData;
    _previewMetadata = CaptureMetadata(
      snapshot: OverlaySnapshot(
        timestamp: DateTime.now(),
        latitude: loc?.latitude ?? 19.0760,
        longitude: loc?.longitude ?? 72.8777,
        altitude: loc?.altitude ?? 0.0,
        accuracy: loc?.accuracy ?? 5.0,
        address: addr?.formattedAddress ?? 'Current Location Preview',
      ),
      template: OverlayTemplate.advance,
      plusCode: '7JVW+52X',
      timezone: 'GMT +05:30',
      note: 'MyNote',
      customFields: [],
      sequenceNumber: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Color(0xFF1E293B),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'File Name',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: ListenableBuilder(
        listenable: SettingsProvider.of(context),
        builder: (context, _) {
          final settings = SettingsProvider.of(context);
          final config = settings.filenameConfiguration;

          // Generate realistic preview
          final metadataWithSettings = _previewMetadata.copyWith(
            filenameConfiguration: config,
            customName1: settings.customName1,
            customName2: settings.customName2,
            customName3: settings.customName3,
          );
          final previewName = FilenameGenerator.generateBaseName(
            metadataWithSettings,
          );

          // Prepare the ordered list of ALL components for the ReorderableListView
          // It must contain all possible components. The ones in config.components are selected,
          // the rest are appended at the end unselected.
          final allComponents = List<FilenameComponent>.from(config.components);
          for (final comp in FilenameComponent.values) {
            if (!allComponents.contains(comp)) {
              allComponents.add(comp);
            }
          }

          return Column(
            children: [
              _buildPreviewBox(previewName),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 40),
                  buildDefaultDragHandles: false, // We'll use our own handle
                  itemCount: allComponents.length,
                  onReorder: (oldIndex, newIndex) {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final item = allComponents.removeAt(oldIndex);
                    allComponents.insert(newIndex, item);

                    // We only save the components that are actually selected
                    final newSelected = allComponents
                        .where((c) => config.components.contains(c))
                        .toList();
                    settings.setFilenameConfiguration(
                      FilenameConfiguration(components: newSelected),
                    );
                  },
                  itemBuilder: (context, index) {
                    final comp = allComponents[index];
                    final isSelected = config.components.contains(comp);
                    return _FilenameComponentRow(
                      key: ValueKey(comp),
                      component: comp,
                      isSelected: isSelected,
                      settings: settings,
                      index: index,
                      onToggle: () {
                        final newSelected = List<FilenameComponent>.from(
                          config.components,
                        );
                        if (isSelected) {
                          newSelected.remove(comp);
                        } else {
                          // Insert at the current visible position in the allComponents list to preserve order
                          // Wait, it's easier to just rebuild the selected list by filtering allComponents
                          newSelected.add(comp);
                        }

                        // Final sort of selected items based on allComponents order
                        final finalSelected = allComponents
                            .where((c) => newSelected.contains(c))
                            .toList();
                        settings.setFilenameConfiguration(
                          FilenameConfiguration(components: finalSelected),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPreviewBox(String previewName) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(
            4,
          ), // slightly rounded box like screenshot
        ),
        child: Text(
          '$previewName.jpg',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _FilenameComponentRow extends StatelessWidget {
  final FilenameComponent component;
  final bool isSelected;
  final SettingsService settings;
  final int index;
  final VoidCallback onToggle;

  const _FilenameComponentRow({
    super.key,
    required this.component,
    required this.isSelected,
    required this.settings,
    required this.index,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final hasOptions = _hasOptions(component);

    return Container(
      decoration: const BoxDecoration(color: Colors.white),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? const Color(0xFFFFC107)
                      : const Color(0xFF94A3B8), // Yellow check, grey empty
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getComponentName(component),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            if (hasOptions)
              IconButton(
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFF64748B),
                ),
                onPressed: () {
                  _showOptions(context);
                },
              ),
            const SizedBox(width: 8),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.menu, // drag handle icon
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasOptions(FilenameComponent comp) {
    return comp == FilenameComponent.customName1 ||
        comp == FilenameComponent.customName2 ||
        comp == FilenameComponent.customName3;
  }

  String _getComponentName(FilenameComponent comp) {
    switch (comp) {
      case FilenameComponent.date:
        return 'Date';
      case FilenameComponent.time:
        return 'Time';
      case FilenameComponent.sequence:
        return 'Sequence Number';
      case FilenameComponent.customName1:
        return 'Custom Name 1';
      case FilenameComponent.customName2:
        return 'Custom Name 2';
      case FilenameComponent.customName3:
        return 'Custom Name 3';
      case FilenameComponent.address:
        return 'Full Address';
      case FilenameComponent.latitude:
        return 'Latitude';
      case FilenameComponent.longitude:
        return 'Longitude';
      case FilenameComponent.plusCode:
        return 'Plus Code';
      case FilenameComponent.timeZone:
        return 'Time Zone';
      case FilenameComponent.note:
        return 'Note';
    }
  }

  void _showOptions(BuildContext context) {
    // Show a dialog to let user edit Custom Name 1, 2, or 3
    if (component == FilenameComponent.customName1 ||
        component == FilenameComponent.customName2 ||
        component == FilenameComponent.customName3) {
      String currentVal = '';
      if (component == FilenameComponent.customName1) {
        currentVal = settings.customName1 ?? '';
      }
      if (component == FilenameComponent.customName2) {
        currentVal = settings.customName2 ?? '';
      }
      if (component == FilenameComponent.customName3) {
        currentVal = settings.customName3 ?? '';
      }

      final controller = TextEditingController(text: currentVal);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Edit ${_getComponentName(component)}'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (component == FilenameComponent.customName1) {
                  settings.setCustomName1(controller.text);
                }
                if (component == FilenameComponent.customName2) {
                  settings.setCustomName2(controller.text);
                }
                if (component == FilenameComponent.customName3) {
                  settings.setCustomName3(controller.text);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } else {
      // For other fields like Date & Time, Sequence Number, etc, we could show options here.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Options for ${_getComponentName(component)} not yet fully implemented.',
          ),
        ),
      );
    }
  }
}
