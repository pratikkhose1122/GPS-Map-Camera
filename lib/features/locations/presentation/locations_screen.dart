import 'package:flutter/material.dart';
import 'package:geomapcam/core/providers/locations_provider.dart';
import 'package:geomapcam/features/locations/domain/models/saved_location.dart';
import 'package:geomapcam/features/locations/data/locations_service.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocationsProvider.of(context),
      builder: (context, _) {
        final locationsService = LocationsProvider.of(context);
        final locations = locationsService.locations;
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Saved Locations'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: locations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No saved locations yet.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Return to Camera'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: locations.length,
                  itemBuilder: (context, index) {
                    final loc = locations[index];
                    final isSelected =
                        locationsService.selectedLocation?.id == loc.id;

                    return Column(
                      children: [
                        ListTile(
                          tileColor: isSelected
                              ? theme.colorScheme.primary.withValues(
                                  alpha: 0.05,
                                )
                              : null,
                          leading: Icon(
                            Icons.place,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          title: Text(
                            loc.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (loc.address != null)
                                Text(
                                  loc.address!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Text(
                                '${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (loc.plusCode != null)
                                Text(
                                  'Plus Code: ${loc.plusCode}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              if (loc.note != null && loc.note!.isNotEmpty)
                                Text(
                                  'Note: ${loc.note}',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () => _editLocation(
                                  context,
                                  locationsService,
                                  loc,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: theme.colorScheme.error,
                                ),
                                onPressed: () => _confirmDelete(
                                  context,
                                  locationsService,
                                  loc,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            locationsService.selectLocation(loc);
                            Navigator.pop(context);
                          },
                        ),
                        const Divider(height: 1),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    LocationsService service,
    SavedLocation loc,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Location?'),
        content: Text('Are you sure you want to delete "${loc.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await service.deleteLocation(loc.id);
    }
  }

  void _editLocation(
    BuildContext context,
    LocationsService service,
    SavedLocation loc,
  ) {
    final nameController = TextEditingController(text: loc.name);
    final noteController = TextEditingController(text: loc.note);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Location Name'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Note (Optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final updated = loc.copyWith(
                  name: name,
                  note: noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim(),
                  updatedAt: DateTime.now(),
                );
                service.updateLocation(updated);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
