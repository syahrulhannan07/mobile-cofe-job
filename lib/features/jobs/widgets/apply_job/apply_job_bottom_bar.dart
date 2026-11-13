import 'package:flutter/material.dart';

import 'apply_job_colors.dart';

class ApplyJobBottomBar extends StatelessWidget {
  final int currentStep;
  final bool faceVerified;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const ApplyJobBottomBar({
    super.key,
    required this.currentStep,
    required this.faceVerified,
    required this.isLoading,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isVerificationStep = currentStep == 5;
    final canSubmit = faceVerified && !isLoading;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: applyDarkBrown),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Kembali',
                style: TextStyle(color: applyDarkBrown),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: ElevatedButton(
              onPressed: isVerificationStep
                  ? (canSubmit ? onSubmit : null)
                  : onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: applyGold,
                disabledBackgroundColor: const Color(0xFFE8E4DF),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                isVerificationStep ? 'Kirim Lamaran' : 'Lanjut',
                style: TextStyle(
                  color: isVerificationStep && !canSubmit
                      ? Colors.grey
                      : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
