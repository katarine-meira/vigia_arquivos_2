import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

// Avatar
class UserAvatar extends StatelessWidget {
  final String initials;
  final double radius;

  const UserAvatar({super.key, required this.initials, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.textDark,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.6,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
