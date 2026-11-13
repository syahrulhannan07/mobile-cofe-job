import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../auth/screens/login_screen.dart';
import '../controllers/apply_job_controller.dart';
import '../widgets/apply_job/apply_job_bottom_bar.dart';
import '../widgets/apply_job/apply_job_header.dart';
import '../widgets/apply_job/apply_job_stepper.dart';
import '../widgets/apply_job/steps/apply_documents_step.dart';
import '../widgets/apply_job/steps/apply_face_verification_step.dart';
import '../widgets/apply_job/steps/apply_profile_step.dart';
import '../widgets/apply_job/steps/apply_questions_step.dart';
import '../widgets/apply_job/steps/apply_review_step.dart';
import 'application_success_screen.dart';

class ApplyJobScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const ApplyJobScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  State<ApplyJobScreen> createState() => _ApplyJobScreenState();
}

class _ApplyJobScreenState extends State<ApplyJobScreen> {
  late final ApplyJobController _controller;
  bool _isHandlingSessionExpiry = false;

  @override
  void initState() {
    super.initState();
    _controller = ApplyJobController(
      jobId: widget.jobId,
      jobTitle: widget.jobTitle,
      onMessage: _showMessage,
    );
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    if (isError && _isSessionExpired(message)) {
      _handleSessionExpired();
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade800 : Colors.green,
        ),
      );
  }

  bool _isSessionExpired(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('401') ||
        normalized.contains('sesi') ||
        normalized.contains('login kembali') ||
        normalized.contains('unauthenticated');
  }

  void _handleSessionExpired() {
    if (_isHandlingSessionExpiry) return;
    _isHandlingSessionExpiry = true;

    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.isFirst);
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _handleBack() {
    if (_controller.currentStep > 1) {
      _controller.previousStep();
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.lamaranTerkirim) {
          return ApplicationSuccessScreen(
            jobTitle: _controller.jobTitle,
          );
        }

        return PopScope(
          canPop:
              _controller.currentStep <= 1 && !_controller.isLoading,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && _controller.currentStep > 1) {
              _controller.previousStep();
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFFBF7F0),
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: ApplyJobHeader(
                      title: 'Lamar ${_headerTitle(_controller.jobTitle)}',
                      onBack: _handleBack,
                    ),
                  ),
                  ApplyJobStepper(
                    currentStep: _controller.currentStep,
                  ),
                  Expanded(
                    child: _buildStepContent(),
                  ),
                  ApplyJobBottomBar(
                    currentStep: _controller.currentStep,
                    faceVerified: _controller.faceVerified,
                    isLoading: _controller.isLoading,
                    onBack: _handleBack,
                    onNext: _controller.nextStep,
                    onSubmit: _handleSubmit,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepContent() {
    if (_controller.isLoading &&
        _controller.idLamaran == null &&
        _controller.dokumenWajib.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.buttonMain,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _stepFor(_controller.currentStep),
    );
  }

  Widget _stepFor(int step) {
    switch (step) {
      case 1:
        return ApplyDocumentsStep(controller: _controller);
      case 2:
        return ApplyQuestionsStep(controller: _controller);
      case 3:
        return ApplyProfileStep(controller: _controller);
      case 4:
        return ApplyReviewStep(controller: _controller);
      case 5:
      default:
        return ApplyFaceVerificationStep(controller: _controller);
    }
  }

  Future<void> _handleSubmit() async {
    await _controller.submitApplication();
  }

  String _headerTitle(String title) {
    return title == 'posisi ini' ? 'Pekerjaan' : title;
  }
}
