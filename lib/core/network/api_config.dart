class ApiConfig {
  // Base URL Utama (Cukup ganti di sini jika pindah server/lokal)
  static const String baseUrl =
      'https://cofe-job.cicd.my.id/api/v1'; // Contoh IP
  // static const String baseUrl = 'http://localhost:8000/api'; // Contoh Chrome Web

  // --- DAFTAR ROUTE / ENDPOINT API ---

  // Fitur Autentikasi
  static const String login = '$baseUrl/auth/login';
  static const String registerPelamar = '$baseUrl/auth/daftar-pelamar';
  static const String logout = '$baseUrl/logout';

  // Fitur Beranda (Lowongan dan Perusahaan Terbaru)
  static const String beranda = '$baseUrl/beranda';

  // Fitur Lowongan
  static const String lowongan = '$baseUrl/lowongan?per_page=100';

  // Fitur Perusahaan
  static const String perusahaan = '$baseUrl/perusahaan?per_page=100';

  // Fitur Profil
  static const String profile = '$baseUrl/pelamar/profil';
  static const String updateProfile = '$baseUrl/pelamar/profil/update';
  static const String updatePassword =
      '$baseUrl/pelamar/profil/update-password';

  // Fitur Lowongan & Tracking
  static const String jobs = '$baseUrl/jobs';
  static const String trackingTimeline = '$baseUrl/tracking-timeline';
  static const String detailJadwal = '$baseUrl/interview-schedule';
}
