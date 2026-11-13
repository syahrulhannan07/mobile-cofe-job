import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../models/face_verification_outcome.dart';
import '../widgets/face_verification_widget.dart';

class FaceVerificationScreen extends StatelessWidget {
  final int idLamaran;
  final int idWawancara;
  final String? profilePhoto;

  const FaceVerificationScreen({
    super.key,
    required this.idLamaran,
    required this.idWawancara,
    this.profilePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.brownDark,
          ),
        ),
        title: const Text(
          'Presensi Wawancara',
          style: TextStyle(
            color: AppColors.brownDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: FaceVerificationWidget(
            mode: FaceVerificationMode.attendance,
            idLamaran: idLamaran,
            idWawancara: idWawancara,
            profilePhoto: profilePhoto,
            onVerified: (outcome) {
              if (!context.mounted) return;
              Navigator.pop(context, outcome);
            },
          ),
        ),
      ),
    );
  }
}
