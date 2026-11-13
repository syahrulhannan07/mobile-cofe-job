import 'package:flutter/material.dart';

import 'apply_job_colors.dart';

class ApplyJobHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const ApplyJobHeader({
    super.key,
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: applyDarkBrown,
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: applyDarkBrown,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
