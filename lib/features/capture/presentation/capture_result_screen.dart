import 'package:flutter/material.dart';
import 'dart:io';
import 'package:geomapcam/features/capture/domain/capture_result.dart';
import 'package:geomapcam/features/capture/data/photo_share_service.dart';
import 'package:geomapcam/features/gallery/data/photo_repository.dart';
import 'package:geomapcam/features/gallery/domain/models/photo_item.dart';
import 'package:geomapcam/app/router/app_router.dart';

class CaptureResultScreen extends StatelessWidget {
  final CaptureResult result;

  const CaptureResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Photo Ready'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back to Camera',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () => _deletePhoto(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: Image.file(
                File(result.filePath),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSecondaryButton(
                    context: context,
                    icon: Icons.share,
                    label: 'Share',
                    onPressed: () => _sharePhoto(context),
                  ),
                  _buildSecondaryButton(
                    context: context,
                    icon: Icons.camera_alt,
                    label: 'Retake',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  _buildSecondaryButton(
                    context: context,
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed(AppRouter.gallery);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colorScheme.onSurface, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sharePhoto(BuildContext context) async {
    try {
      await PhotoShareService.sharePhoto(result.filePath);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deletePhoto(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this photo?'),
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

    if (shouldDelete == true) {
      try {
        final repo = PhotoRepository();
        final stat = await File(result.filePath).stat();
        final filename = result.filePath.split(Platform.pathSeparator).last;

        final photoItem = PhotoItem(
          filePath: result.filePath,
          filename: filename,
          createdAt: stat.modified,
          fileSize: stat.size,
        );

        await repo.deletePhotos([photoItem]);

        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete photo'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
