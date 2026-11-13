import 'package:flutter/material.dart';

import 'apply_job_colors.dart';

class ApplyJobAvatar extends StatelessWidget {
  final double radius;
  final String name;
  final ImageProvider? imageProvider;

  const ApplyJobAvatar({
    super.key,
    required this.radius,
    required this.name,
    this.imageProvider,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initialsOf(name);
    final backgroundColor = applyGold.withValues(alpha: 0.2);

    if (imageProvider == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: Text(
          initials,
          style: TextStyle(
            fontSize: radius * 0.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF8B5E3C),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: ClipOval(
        child: Image(
          image: imageProvider!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Text(
            initials,
            style: TextStyle(
              fontSize: radius * 0.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8B5E3C),
            ),
          ),
        ),
      ),
    );
  }

  String _initialsOf(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';

    return trimmed
        .split(' ')
        .take(2)
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join();
  }
}
