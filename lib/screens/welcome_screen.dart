import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Logo boyutunu clamp ile sınırla
    final logoSize = size.width * 0.4;
    final constrainedLogoSize = logoSize.clamp(100.0, 200.0);

    Widget buildCustomButton({
      required IconData icon,
      required String text,
      required VoidCallback onTap,
      double? width,
    }) {
      final buttonWidth = width ?? (size.width * 0.85).clamp(200.0, 500.0);

      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: buttonWidth,
          margin: const EdgeInsets.symmetric(vertical: 14),
          child: CustomPaint(
            painter: GradientBorderPainter(
              borderRadius: 18,
              strokeWidth: 2,
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, size: 32, color: const Color(0xFF1976D2)),
                  Expanded(
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 28, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: kIsWeb ? size.width * 0.05 : 0,
              vertical: 20,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: constrainedLogoSize,
                  height: constrainedLogoSize,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: const Icon(
                    Icons.book,
                    size: 100,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 28),

                // Başlık
                const Text(
                  'Cumhuriyet Kitaplık Uygulaması',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 18),

                const Text(
                  'Hoş Geldiniz!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 60),

                // Butonlar
                buildCustomButton(
                  icon: Icons.admin_panel_settings,
                  text: 'Admin Girişi',
                  onTap: () {
                    Navigator.pushNamed(context, '/admin_login');
                  },
                ),
                buildCustomButton(
                  icon: Icons.family_restroom,
                  text: 'Veli Girişi',
                  onTap: () {
                    Navigator.pushNamed(context, '/parent_login');
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom Painter ile gradient border
class GradientBorderPainter extends CustomPainter {
  final double borderRadius;
  final double strokeWidth;
  final Gradient gradient;

  GradientBorderPainter({
    required this.borderRadius,
    required this.strokeWidth,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
