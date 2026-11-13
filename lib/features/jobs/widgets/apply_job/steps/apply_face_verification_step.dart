import 'package:flutter/material.dart';

import '../../../../face_verification/models/face_verification_outcome.dart';
import '../../../../face_verification/widgets/face_verification_widget.dart';
import '../../../controllers/apply_job_controller.dart';

class ApplyFaceVerificationStep extends StatelessWidget {
  final ApplyJobController controller;

  const ApplyFaceVerificationStep({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final idLamaran = int.tryParse(controller.idLamaran ?? '');

    if (idLamaran == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'ID lamaran tidak valid. Coba keluar dan masuk kembali.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return FaceVerificationWidget(
      mode: FaceVerificationMode.application,
      idLamaran: idLamaran,
      profilePhoto:
          controller.profileImagePath ?? controller.networkProfileImageUrl,
      onVerified: (outcome) {
        controller.handleFaceResult(
          success: outcome.success,
          message: outcome.message,
        );
      },
    );
  }
}
