import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class PhotoReportScreen extends StatefulWidget {
  const PhotoReportScreen({super.key});

  @override
  State<PhotoReportScreen> createState() => _PhotoReportScreenState();
}

class _PhotoReportScreenState extends State<PhotoReportScreen> {
  final List<File> _selectedPhotos = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickPhotos() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedPhotos.addAll(images.map((x) => File(x.path)));
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
          'Photo Report',
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
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Colors.transparent,
                      Color(0xFFFFC107),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Text(
                    'Work report',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Photo Area
              Expanded(
                child: _selectedPhotos.isEmpty
                    ? Center(
                        child: TextButton.icon(
                          onPressed: _pickPhotos,
                          icon: const Icon(
                            Icons.add_photo_alternate,
                            size: 32,
                            color: Colors.black54,
                          ),
                          label: const Text(
                            'Tap to add photos',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _selectedPhotos.length,
                        itemBuilder: (context, index) {
                          return _buildPhotoItem(_selectedPhotos[index], index);
                        },
                      ),
              ),

              // Bottom Action Bar
              if (_selectedPhotos.isNotEmpty)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBottomAction(
                        Icons.save_alt,
                        'Save Photo',
                        Colors.blue,
                      ),
                      _buildBottomAction(
                        Icons.picture_as_pdf,
                        'Save PDF',
                        Colors.red,
                      ),
                      _buildBottomAction(
                        Icons.share,
                        'Share',
                        Colors.deepPurple,
                      ),
                      _buildBottomAction(Icons.chat, 'WhatsApp', Colors.green),
                    ],
                  ),
                ),
            ],
          ),

          // Floating Action Button
          Positioned(
            bottom: _selectedPhotos.isNotEmpty ? 100 : 32,
            right: 24,
            child: FloatingActionButton(
              onPressed: _pickPhotos,
              backgroundColor: const Color(0xFFFFC107),
              child: const Icon(Icons.add, color: Colors.black, size: 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoItem(File file, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.file(
                  file,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPhotos.removeAt(index);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat(
                    'EEEE, MM/dd/yyyy hh:mm a',
                  ).format(file.lastModifiedSync()),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Open in Google Maps',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
