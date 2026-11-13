enum FaceVerificationMode { application, attendance }

class FaceVerificationOutcome {
  final bool success;
  final String message;
  final int? statusCode;
  final double? confidence;
  final double? threshold;
  final bool? faceDetected;
  final Map<String, dynamic>? presensi;
  final String? statusJadwal;

  const FaceVerificationOutcome({
    required this.success,
    required this.message,
    this.statusCode,
    this.confidence,
    this.threshold,
    this.faceDetected,
    this.presensi,
    this.statusJadwal,
  });

  factory FaceVerificationOutcome.failure(
    String message, {
    int? statusCode,
    bool? faceDetected,
  }) {
    return FaceVerificationOutcome(
      success: false,
      message: message,
      statusCode: statusCode,
      faceDetected: faceDetected,
    );
  }

  factory FaceVerificationOutcome.fromResponse(
    int statusCode,
    Map<String, dynamic> body,
  ) {
    final data = body['data'] is Map
        ? Map<String, dynamic>.from(body['data'] as Map)
        : null;
    final success = statusCode == 200 && body['status'] == 'success';
    final message = body['message']?.toString() ?? '';

    return FaceVerificationOutcome(
      success: success,
      message: message.isNotEmpty
          ? message
          : (success
                ? 'Verifikasi wajah berhasil.'
                : 'Verifikasi wajah belum berhasil. Silakan coba lagi.'),
      statusCode: statusCode,
      confidence: _toDouble(body['confidence']),
      threshold: _toDouble(body['threshold']),
      faceDetected: body['face_detected'] is bool
          ? body['face_detected'] as bool
          : null,
      presensi: data?['presensi'] is Map
          ? Map<String, dynamic>.from(data!['presensi'] as Map)
          : null,
      statusJadwal: data?['status_jadwal']?.toString(),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
