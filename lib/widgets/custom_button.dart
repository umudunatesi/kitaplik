import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final double? iconSize; // opsiyonel, web/android için geçersizse default
  final double? fontSize;

  const CustomButton({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    this.onPressed,
    this.iconSize,
    this.fontSize,
  });

  bool get _isDesktopOrWeb {
    if (kIsWeb) return true;
    return (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux);
  }

  @override
  Widget build(BuildContext context) {
    final small = _isDesktopOrWeb;

    return ElevatedButton(
      onPressed: onPressed ?? () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          vertical: small ? 10 : 16,
          horizontal: small ? 12 : 20,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: iconSize ?? (small ? 24 : 48),
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize ?? (small ? 14 : 16),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
