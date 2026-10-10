import 'package:flutter/material.dart';
import 'package:geomapcam/app/router/app_router.dart';
import 'package:geomapcam/features/gallery/data/photo_repository.dart';
import 'package:geomapcam/features/gallery/domain/models/photo_item.dart';

class GalleryScreen extends StatefulWidget {
  final PhotoRepository? repository;
  const GalleryScreen({super.key, this.repository});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen>
    with WidgetsBindingObserver {
  late final PhotoRepository _repository;
  late Future<List<PhotoItem>> _photosFuture;
  bool _isSelectionMode = false;
  final Set<String> _selectedFilePaths = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _repository = widget.repository ?? PhotoRepository();
    _loadPhotos();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPhotos();
    }
  }

  void _loadPhotos() {
    setState(() {
      _photosFuture = _repository.getPhotos();
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedFilePaths.clear();
      }
    });
  }

  void _togglePhotoSelection(PhotoItem photo) {
    setState(() {
      if (_selectedFilePaths.contains(photo.filePath)) {
        _selectedFilePaths.remove(photo.filePath);
        if (_selectedFilePaths.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedFilePaths.add(photo.filePath);
      }
    });
  }

  Future<void> _confirmDelete() async {
    final count = _selectedFilePaths.length;
    final message = count == 1 ? 'Delete this photo?' : 'Delete $count photos?';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      _deleteSelectedPhotos();
    }
  }

  Future<void> _deleteSelectedPhotos() async {
    final allPhotos = await _photosFuture;
    final photosToDelete = allPhotos
        .where((p) => _selectedFilePaths.contains(p.filePath))
        .toList();

    final deleteResult = await _repository.deletePhotos(photosToDelete);

    if (!deleteResult.isAllSuccess && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Deleted ${deleteResult.successfullyDeleted}, failed: ${deleteResult.failed}, missing: ${deleteResult.missing}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isSelectionMode = false;
      _selectedFilePaths.clear();
      _loadPhotos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _isSelectionMode
          ? AppBar(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              leading: IconButton(
                icon: Icon(
                  Icons.close,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: _toggleSelectionMode,
                tooltip: 'Cancel selection',
              ),
              title: Text(
                '${_selectedFilePaths.length} selected',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.delete, color: theme.colorScheme.error),
                  onPressed: _selectedFilePaths.isEmpty ? null : _confirmDelete,
                  tooltip: 'Delete selected photos',
                ),
              ],
            )
          : AppBar(title: const Text('Gallery')),
      body: FutureBuilder<List<PhotoItem>>(
        future: _photosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading photos',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            );
          }

          final photos = snapshot.data ?? [];

          if (photos.isEmpty) {
            return _buildEmptyState(context, theme);
          }

          return GridView.builder(
            padding: const EdgeInsets.all(2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return _buildThumbnail(photo);
            },
          );
        },
      ),
    );
  }

  Widget _buildThumbnail(PhotoItem photo) {
    final isSelected = _selectedFilePaths.contains(photo.filePath);

    return GestureDetector(
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
            _selectedFilePaths.add(photo.filePath);
          });
        }
      },
      onTap: () {
        if (_isSelectionMode) {
          _togglePhotoSelection(photo);
        } else {
          Navigator.pushNamed(
            context,
            AppRouter.photoViewer,
            arguments: photo,
          ).then((deletedFilePaths) {
            if (deletedFilePaths != null &&
                (deletedFilePaths as List).isNotEmpty) {
              _loadPhotos();
            }
          });
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            photo.file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[800],
                child: const Icon(Icons.broken_image, color: Colors.white54),
              );
            },
          ),
          if (_isSelectionMode)
            Container(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                  : Colors.black45,
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white70,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No photos yet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Capture your first GPS photo to see it here.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Go to Camera'),
          ),
        ],
      ),
    );
  }
}
