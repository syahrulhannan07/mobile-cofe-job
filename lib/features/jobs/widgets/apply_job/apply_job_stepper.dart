import 'package:flutter/material.dart';

import 'apply_job_colors.dart';

class ApplyJobStepper extends StatelessWidget {
  final int currentStep;

  const ApplyJobStepper({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepIndicator(1, 'Dokumen'),
          _stepLine(1),
          _stepIndicator(2, 'Tanya'),
          _stepLine(2),
          _stepIndicator(3, 'Profil'),
          _stepLine(3),
          _stepIndicator(4, 'Review'),
          _stepLine(4),
          _stepIndicator(5, 'Wajah'),
        ],
      ),
    );
  }

  Widget _stepIndicator(int step, String label) {
    final isActive = currentStep == step;
    final isCompleted = currentStep > step;

    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isActive || isCompleted
                ? applyGold
                : const Color(0xFFE8E4DF),
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: applyGold.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: isCompleted
                ? const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 18,
                  )
                : Text(
                    '$step',
                    style: TextStyle(
                      color: isActive
                          ? Colors.white
                          : const Color(0xFFADA9A4),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? applyGold : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(int step) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Container(
          height: 2,
          color: currentStep > step
              ? applyGold
              : const Color(0xFFE0E0E0),
        ),
      ),
    );
  }
}
