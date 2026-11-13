import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/storage_url.dart';
import '../models/face_verification_outcome.dart';
import '../services/face_verification_service.dart';

class FaceVerificationWidget extends StatefulWidget {
  final FaceVerificationMode mode;
  final int idLamaran;
  final int? idWawancara;
  final String? profilePhoto;
  final ValueChanged<FaceVerificationOutcome>? onVerified;

  const FaceVerificationWidget({
    super.key,
    required this.mode,
    required this.idLamaran,
    this.idWawancara,
    this.profilePhoto,
    this.onVerified,
  });

  @override
  State<FaceVerificationWidget> createState() => _FaceVerificationWidgetState();
}

class _FaceVerificationWidgetState extends State<FaceVerificationWidget> {
  final FaceVerificationService _service = const FaceVerificationService();

  CameraController? _controller;
  CameraDescription? _cameraDescription;
  FaceDetector? _faceDetector;
  bool _initializing = true;
  String? _cameraError;
  bool _verifying = false;
  bool _verified = false;
  bool _faceAligned = false;
  bool _frameProcessing = false;
  int _alignedFrameCount = 0;
  DateTime _lastFrameAt = DateTime.fromMillisecondsSinceEpoch(0);
  FaceVerificationOutcome? _result;

  static const int _requiredAlignedFrames = 3;
  static const Duration _frameInterval = Duration(milliseconds: 250);

  bool get _isAttendance => widget.mode == FaceVerificationMode.attendance;

  bool get _supportsAutoScan =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  ImageFormatGroup get _streamImageFormat {
    if (!_supportsAutoScan) return ImageFormatGroup.jpeg;
    return defaultTargetPlatform == TargetPlatform.android
        ? ImageFormatGroup.nv21
        : ImageFormatGroup.bgra8888;
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller?.value.isStreamingImages == true) {
      unawaited(controller!.stopImageStream());
    }
    _faceDetector?.close();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    if (mounted) {
      setState(() {
        _initializing = true;
        _cameraError = null;
      });
    }

    await _stopAutoDetection();
    final previousDetector = _faceDetector;
    _faceDetector = null;
    await previousDetector?.close();

    final previous = _controller;
    _controller = null;
    await previous?.dispose();

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('Kamera tidak ditemukan.');
      }

      final selected = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: _streamImageFormat,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _cameraDescription = selected;
        _initializing = false;
        _cameraError = null;
      });

      if (_supportsAutoScan) {
        _faceDetector = FaceDetector(
          options: FaceDetectorOptions(
            performanceMode: FaceDetectorMode.fast,
            minFaceSize: 0.1,
          ),
        );
        unawaited(_startAutoDetection());
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _cameraError =
            'Kamera tidak dapat diakses. Pastikan izin kamera sudah diberikan, lalu coba lagi.';
      });
    }
  }

  Future<void> _startAutoDetection() async {
    final controller = _controller;
    if (!_supportsAutoScan ||
        _faceDetector == null ||
        controller == null ||
        !controller.value.isInitialized ||
        _verifying ||
        _verified) {
      return;
    }

    if (controller.value.isStreamingImages) return;

    try {
      await controller.startImageStream(_onCameraImage);
    } catch (_) {}
  }

  Future<void> _stopAutoDetection() async {
    final controller = _controller;
    try {
      if (controller != null && controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {}
    _resetAlignment();
  }

  void _resetAlignment() {
    _alignedFrameCount = 0;
    if (!_faceAligned) return;
    _faceAligned = false;
    if (mounted) setState(() {});
  }

  void _onCameraImage(CameraImage image) {
    final detector = _faceDetector;
    if (!mounted ||
        detector == null ||
        _verifying ||
        _verified ||
        _result != null ||
        _frameProcessing) {
      return;
    }

    if (MediaQuery.orientationOf(context) != Orientation.portrait) {
      _resetAlignment();
      return;
    }

    final now = DateTime.now();
    if (now.difference(_lastFrameAt) < _frameInterval) return;
    _lastFrameAt = now;

    final inputImage = _toInputImage(image);
    if (inputImage == null) return;

    _frameProcessing = true;
    unawaited(
      detector
          .processImage(inputImage)
          .then((faces) {
            if (!mounted || _verifying || _verified) return;
            _handleFaces(faces, image);
          })
          .catchError((_) {})
          .whenComplete(() => _frameProcessing = false),
    );
  }

  InputImage? _toInputImage(CameraImage image) {
    final rotation = _mlkitRotation(_cameraDescription?.sensorOrientation ?? 0);
    final size = Size(image.width.toDouble(), image.height.toDouble());

    if (defaultTargetPlatform == TargetPlatform.android) {
      if (image.format.group != ImageFormatGroup.nv21 ||
          image.planes.isEmpty) {
        return null;
      }
      final plane = image.planes.first;
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: size,
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (image.format.group != ImageFormatGroup.bgra8888 ||
          image.planes.isEmpty) {
        return null;
      }
      final bytes = image.planes.length == 1
          ? image.planes.first.bytes
          : Uint8List.fromList(
              image.planes.expand((plane) => plane.bytes).toList(),
            );
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: size,
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    }

    return null;
  }

  InputImageRotation _mlkitRotation(int degrees) {
    switch (degrees % 360) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  void _handleFaces(List<Face> faces, CameraImage image) {
    final aligned =
        faces.length == 1 && _isFaceWellAligned(faces.first, image);

    if (!aligned) {
      _resetAlignment();
      return;
    }

    _alignedFrameCount++;
    if (!_faceAligned) setState(() => _faceAligned = true);

    if (_alignedFrameCount >= _requiredAlignedFrames) {
      _alignedFrameCount = 0;
      _captureAndVerify();
    }
  }

  bool _isFaceWellAligned(Face face, CameraImage image) {
    final rotation = _mlkitRotation(_cameraDescription?.sensorOrientation ?? 0);
    final rotated =
        rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;
    final frameWidth =
        (rotated ? image.height : image.width).toDouble();
    final frameHeight =
        (rotated ? image.width : image.height).toDouble();
    if (frameWidth <= 0 || frameHeight <= 0) return false;

    final box = face.boundingBox;
    final faceWidth = box.width / frameWidth;
    final faceHeight = box.height / frameHeight;
    final centerX = (box.center.dx / frameWidth).clamp(0.0, 1.0);
    final centerY = (box.center.dy / frameHeight).clamp(0.0, 1.0);

    if (faceWidth < 0.15 ||
        faceWidth > 0.55 ||
        faceHeight < 0.15 ||
        faceHeight > 0.7) {
      return false;
    }

    final offsetX = (centerX - 0.5) / 0.31;
    final offsetY = (centerY - 0.47) / 0.27;

    return (offsetX * offsetX) + (offsetY * offsetY) <= 1.0;
  }

  Future<void> _captureAndVerify() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _verifying ||
        _verified) {
      return;
    }

    if (_isAttendance && widget.idWawancara == null) {
      setState(() {
        _result = FaceVerificationOutcome.failure(
          'Jadwal wawancara tidak valid. Muat ulang detail jadwal terlebih dahulu.',
        );
      });
      return;
    }

    setState(() {
      _verifying = true;
      _result = null;
    });

    await _stopAutoDetection();

    try {
      final picture = await controller.takePicture();
      final bytes = await picture.readAsBytes();

      if (bytes.length > 5 * 1024 * 1024) {
        if (!mounted) return;
        setState(() {
          _verifying = false;
          _result = FaceVerificationOutcome.failure(
            'Ukuran foto terlalu besar. Silakan coba ambil foto ulang.',
          );
        });
        return;
      }

      final imageBase64 = base64Encode(bytes);
      final outcome = _isAttendance
          ? await _service.confirmAttendance(
              idLamaran: widget.idLamaran,
              idWawancara: widget.idWawancara!,
              imageBase64: imageBase64,
            )
          : await _service.verifyApplication(
              idLamaran: widget.idLamaran,
              imageBase64: imageBase64,
            );

      if (!mounted) return;
      setState(() {
        _verifying = false;
        _result = outcome;
        _verified = outcome.success;
      });

      if (outcome.success) {
        widget.onVerified?.call(outcome);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _result = FaceVerificationOutcome.failure(
          'Gagal mengambil gambar dari kamera. Tutup aplikasi lain yang menggunakan kamera, lalu coba lagi.',
        );
      });
    }
  }

  void _resetVerification() {
    setState(() {
      _result = null;
      _verified = false;
      _verifying = false;
    });
    if (_controller == null || !_controller!.value.isInitialized) {
      _initializeCamera();
    } else {
      unawaited(_startAutoDetection());
    }
  }

  Future<void> _showReferencePhoto() async {
    final url = buildStorageUrl(widget.profilePhoto);
    if (url.isEmpty) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 10, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Foto Profil Referensi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        url,
                        width: 220,
                        height: 220,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const SizedBox(
                            width: 220,
                            height: 220,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.brownDark,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox(
                            width: 220,
                            height: 220,
                            child: Icon(
                              Icons.person_rounded,
                              size: 72,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Wajah Anda akan dicocokkan dengan foto profil ini. Pastikan foto menampilkan wajah Anda dengan jelas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final referenceUrl = buildStorageUrl(widget.profilePhoto);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        if (referenceUrl.isNotEmpty) ...[
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              onPressed: _showReferencePhoto,
              icon: const Icon(Icons.visibility_rounded, size: 18),
              label: const Text('Lihat Foto Profil Referensi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brownDark,
                side: const BorderSide(color: AppColors.brownLight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _buildCameraPanel(),
        const SizedBox(height: 14),
        if (_cameraError != null) _buildCameraError(),
        if (!_supportsAutoScan &&
            _result == null &&
            !_verifying &&
            _cameraError == null)
          _buildAutoScanUnavailable(),
        if (_result != null) _buildResultCard(),
        const SizedBox(height: 16),
        _buildTipsCard(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.brownDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isAttendance ? 'Presensi Wawancara' : 'Verifikasi Identitas',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isAttendance
                ? 'Lakukan presensi saat Anda sudah hadir dan siap mengikuti wawancara. Wajah akan dicocokkan dengan foto profil Anda, lalu kehadiran dicatat setelah verifikasi berhasil.'
                : 'Wajah Anda akan dicocokkan dengan foto profil untuk memverifikasi identitas sebelum lamaran dikirim.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Foto profil dan hasil kamera diproses oleh Face++ melalui server C.A.F.E. Job. Server hanya menyimpan hasil verifikasi, bukan gambar hasil pemindaian.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.75),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPanel() {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.brownDark.withValues(alpha: 0.12),
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (ready)
                Transform.flip(flipX: true, child: CameraPreview(controller))
              else
                _buildCameraPlaceholder(),
              if (ready)
                CustomPaint(
                  painter: _FaceOvalPainter(
                    color: _ovalColor,
                    showShade: !_verified,
                  ),
                ),
              if (ready)
                Positioned(
                  top: 14,
                  left: 14,
                  right: 14,
                  child: Center(child: _buildStatusBadge()),
                ),
              if (ready) _buildCornerGuides(),
              if (_verifying)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.25),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPlaceholder() {
    return Container(
      color: const Color(0xFFF7F3ED),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: _cameraError != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.no_photography_rounded,
                    size: 48,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _cameraError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.redAccent,
                      height: 1.5,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_initializing)
                    const CircularProgressIndicator(color: AppColors.brownDark),
                  const SizedBox(height: 14),
                  const Text(
                    'Menyiapkan kamera...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pastikan Anda telah mengizinkan akses kamera.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    late final Color color;
    late final IconData icon;
    late final String label;

    if (_verified) {
      color = const Color(0xFF16A34A);
      icon = Icons.verified_rounded;
      label = 'Terverifikasi';
    } else if (_verifying) {
      color = const Color(0xFFD97706);
      icon = Icons.hourglass_top_rounded;
      label = 'Memverifikasi wajah...';
    } else if (_result != null && !_result!.success) {
      color = const Color(0xFFDC2626);
      icon = Icons.error_outline_rounded;
      label = 'Verifikasi gagal';
    } else if (_faceAligned) {
      color = const Color(0xFF16A34A);
      icon = Icons.face_rounded;
      label = 'Wajah terdeteksi, memindai...';
    } else {
      color = const Color(0xFF4B2E2B);
      icon = Icons.face_retouching_natural_rounded;
      label = 'Posisikan wajah di dalam bingkai';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerGuides() {
    const color = Color(0xFFF0B85E);
    const thickness = 4.0;
    const length = 34.0;
    const inset = 18.0;

    Widget corner({
      required Alignment alignment,
      required BorderRadius borderRadius,
      required Border border,
    }) {
      return Align(
        alignment: alignment,
        child: Container(
          width: length,
          height: length,
          margin: const EdgeInsets.all(inset),
          decoration: BoxDecoration(borderRadius: borderRadius, border: border),
        ),
      );
    }

    return IgnorePointer(
      child: Stack(
        children: [
          corner(
            alignment: Alignment.topLeft,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(12)),
            border: const Border(
              top: BorderSide(color: color, width: thickness),
              left: BorderSide(color: color, width: thickness),
            ),
          ),
          corner(
            alignment: Alignment.topRight,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
            ),
            border: const Border(
              top: BorderSide(color: color, width: thickness),
              right: BorderSide(color: color, width: thickness),
            ),
          ),
          corner(
            alignment: Alignment.bottomLeft,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
            ),
            border: const Border(
              bottom: BorderSide(color: color, width: thickness),
              left: BorderSide(color: color, width: thickness),
            ),
          ),
          corner(
            alignment: Alignment.bottomRight,
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(12),
            ),
            border: const Border(
              bottom: BorderSide(color: color, width: thickness),
              right: BorderSide(color: color, width: thickness),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoScanUnavailable() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF0B85E).withValues(alpha: 0.5),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFD97706),
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pemindaian wajah otomatis hanya tersedia di aplikasi Android dan iOS.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF7A5C2E),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraError() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF0B85E).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFD97706),
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kamera belum dapat digunakan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF7A5C2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _cameraError!,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7A5C2E),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _initializeCamera,
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Coba Akses Kamera Lagi'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brownDark,
              side: const BorderSide(color: AppColors.brownLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final result = _result!;
    if (result.success) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF86EFAC)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFF16A34A),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Verifikasi berhasil',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF166534),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isAttendance
                        ? 'Kehadiran Anda telah tercatat. Perusahaan telah diberi tahu bahwa Anda hadir dan siap diwawancarai.'
                        : 'Wajah Anda sesuai dengan foto profil. Silakan kirim lamaran untuk menyelesaikan proses.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF166534),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final title = result.faceDetected == false
        ? 'Wajah belum terlihat jelas'
        : 'Wajah belum dapat diverifikasi';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF0B85E).withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.priority_high_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF7A5C2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.message.isNotEmpty
                ? result.message
                : 'Pastikan wajah terlihat jelas dan pencahayaan cukup, lalu coba lagi.',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7A5C2E),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _resetVerification,
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Verifikasi Ulang'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brownDark,
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.brownLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE8E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_rounded, size: 18, color: Color(0xFFF0B85E)),
              SizedBox(width: 8),
              Text(
                'Agar verifikasi berjalan lancar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildTip(
            'Pastikan hanya satu wajah terlihat dan berada di dalam bingkai.',
          ),
          if (_supportsAutoScan)
            _buildTip(
              'Pemindaian berjalan otomatis saat wajah berada di dalam bingkai dan terlihat jelas.',
            ),
          _buildTip(
            'Gunakan pencahayaan yang cukup dan hindari cahaya terang dari belakang.',
          ),
          _buildTip(
            'Lepaskan penutup wajah dan tahan posisi hingga pemindaian selesai.',
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.check_circle_rounded,
              size: 14,
              color: Color(0xFF6B8E23),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color get _ovalColor {
    if (_verified) return const Color(0xFF22C55E);
    if (_verifying) return const Color(0xFFEAB308);
    if (_result != null && !_result!.success) return const Color(0xFFEF4444);
    return const Color(0xFFF0B85E);
  }
}

class _FaceOvalPainter extends CustomPainter {
  final Color color;
  final bool showShade;

  const _FaceOvalPainter({required this.color, required this.showShade});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.46),
      width: size.width * 0.64,
      height: size.height * 0.56,
    );

    if (showShade) {
      final shade = Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addOval(rect),
      );
      canvas.drawPath(
        shade,
        Paint()..color = Colors.black.withValues(alpha: 0.42),
      );
    }

    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _FaceOvalPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.showShade != showShade;
  }
}
