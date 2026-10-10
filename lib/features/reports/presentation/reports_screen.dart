import 'package:flutter/material.dart';
import 'package:geomapcam/features/reports/presentation/photo_report_screen.dart';
import 'package:geomapcam/features/reports/presentation/before_after_report_screen.dart';
import 'package:geomapcam/core/localization/app_localizations.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('Reports'),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ReportCard(
            title: context.tr('Photo Report'),
            description:
                'Turn captured photos into branded reports with your company details, project info, and GPS data.',
            iconWidget: _buildPhotoReportIcon(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PhotoReportScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
          _ReportCard(
            title: context.tr('Before / After'),
            description:
                'Document changes with side-by-side photos, descriptions, and location.',
            iconWidget: _buildBeforeAfterIcon(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BeforeAfterReportScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoReportIcon() {
    return _DocumentCanvas(
      child: Padding(
        padding: const EdgeInsets.only(top: 24, left: 8, right: 8, bottom: 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _line(),
                      const SizedBox(height: 4),
                      _line(),
                      const SizedBox(height: 4),
                      _line(),
                      const SizedBox(height: 4),
                      _line(),
                      const SizedBox(height: 4),
                      _line(),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4DB6AC), Color(0xFF00796B)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: const Icon(
                      Icons.landscape,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _line(),
                      const SizedBox(height: 4),
                      _line(),
                      const SizedBox(height: 4),
                      _line(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeforeAfterIcon() {
    return _DocumentCanvas(
      child: Padding(
        padding: const EdgeInsets.only(top: 20, left: 8, right: 8, bottom: 8),
        child: Column(
          children: [
            _line(width: 40),
            const SizedBox(height: 4),
            _line(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(height: 6, color: const Color(0xFF90CAF9)),
                      Container(
                        height: 24,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.home,
                          size: 16,
                          color: Colors.black26,
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(Icons.arrow_forward, size: 8, color: Colors.blue),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Container(height: 6, color: const Color(0xFF2196F3)),
                      Container(
                        height: 24,
                        color: Colors.amber[100],
                        child: const Icon(
                          Icons.home,
                          size: 16,
                          color: Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _line(),
                      const SizedBox(height: 4),
                      _line(),
                      const SizedBox(height: 4),
                      _line(),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _checkLine(),
                      const SizedBox(height: 4),
                      _checkLine(),
                      const SizedBox(height: 4),
                      _checkLine(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _line({double? width}) {
    return Container(
      width: width ?? double.infinity,
      height: 2,
      color: Colors.grey[300],
    );
  }

  Widget _checkLine() {
    return Row(
      children: [
        const Icon(Icons.check, size: 6, color: Colors.blue),
        const SizedBox(width: 2),
        Expanded(child: _line()),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String description;
  final Widget iconWidget;
  final VoidCallback onTap;

  const _ReportCard({
    required this.title,
    required this.description,
    required this.iconWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2C3E50) : const Color(0xFFF4F6F9);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final descColor = isDark ? Colors.grey[400] : const Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: descColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.arrow_forward_ios, color: textColor, size: 16),
          ],
        ),
      ),
    );
  }
}

class _DocumentCanvas extends StatelessWidget {
  final Widget child;

  const _DocumentCanvas({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 104,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Content
          Positioned.fill(child: child),

          // Folded corner effect (Top Right)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(-1, 1),
                  ),
                ],
              ),
            ),
          ),
          // To make the fold look real, we cover the top right corner of the document
          // with a triangle matching the background color of the card.
          Positioned(
            top: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(20, 20),
              painter: _CornerHiderPainter(color: const Color(0xFFF4F6F9)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerHiderPainter extends CustomPainter {
  final Color color;
  _CornerHiderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
