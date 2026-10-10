import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class BeforeAfterReportScreen extends StatefulWidget {
  const BeforeAfterReportScreen({super.key});

  @override
  State<BeforeAfterReportScreen> createState() =>
      _BeforeAfterReportScreenState();
}

class _BeforeAfterReportScreenState extends State<BeforeAfterReportScreen> {
  final ImagePicker _picker = ImagePicker();

  // A list of comparisons. Each has a before and an after file.
  final List<_ComparisonGroup> _groups = [_ComparisonGroup()];

  Future<void> _pickPhoto(int groupIndex, bool isBefore) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isBefore) {
          _groups[groupIndex].before = File(image.path);
        } else {
          _groups[groupIndex].after = File(image.path);
        }
      });
    }
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
          'Before / After',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF1E293B)),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Faded map background
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/map_preview.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          Column(
            children: [
              // Date / Time in top right
              Padding(
                padding: const EdgeInsets.only(
                  right: 16.0,
                  top: 8.0,
                  bottom: 8.0,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    DateFormat(
                      'EEEE, MM/dd/yyyy\nhh:mm a',
                    ).format(DateTime.now()),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),

              // Yellow Banner
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFFFC107), width: 2),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Before / After Report',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const Text(
                      'Add Summary (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 24),

                    ...List.generate(
                      _groups.length,
                      (index) => _buildComparisonGroup(index),
                    ),

                    const SizedBox(height: 16),

                    // Add Comparison Group Button
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _groups.add(_ComparisonGroup());
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white54,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: const Text(
                            '+ Add Comparison Group',
                            style: TextStyle(
                              color: Colors.black45,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 100), // spacing for bottom bar
                  ],
                ),
              ),
            ],
          ),

          // Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBottomAction(Icons.save_alt, 'Save Photo', Colors.blue),
                  _buildBottomAction(
                    Icons.picture_as_pdf,
                    'Save PDF',
                    Colors.red,
                  ),
                  _buildBottomAction(Icons.share, 'Share', Colors.deepPurple),
                  _buildBottomAction(Icons.chat, 'WhatsApp', Colors.green),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonGroup(int index) {
    final group = _groups[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comparison ${index + 1}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const Divider(color: Colors.black26),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPhotoBox(
                group.before,
                true,
                () => _pickPhoto(index, true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPhotoBox(
                group.after,
                false,
                () => _pickPhoto(index, false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildPhotoBox(File? file, bool isBefore, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 2,
                style: BorderStyle.solid,
              ), // In Flutter dashed border requires a package or custom painter, solid is close enough
            ),
            child: Stack(
              children: [
                if (file != null)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(file, fit: BoxFit.cover),
                    ),
                  )
                else
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle, color: Colors.black26, size: 32),
                        SizedBox(height: 8),
                        Text(
                          'Tap to add',
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isBefore
                          ? const Color(0xFFE53935)
                          : const Color(0xFF43A047),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isBefore ? 'Before' : 'After',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add description (optional)',
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildBottomAction(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}

class _ComparisonGroup {
  File? before;
  File? after;
}
