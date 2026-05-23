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

  // Fitur Lamaran
  static const String mulaiLamaran = '$baseUrl/lamaran/mulai';

  // Fungsi penolong untuk endpoint bertipe dinamis ID
  static String uploadDokumen(int idLamaran) =>
      '$baseUrl/lamaran/$idLamaran/dokumen';
  static String simpanJawaban(int idLamaran) =>
      '$baseUrl/lamaran/$idLamaran/jawaban';
  static String kirimLamaran(int idLamaran) =>
      '$baseUrl/lamaran/$idLamaran/kirim';

  // Fitur Profil
  static const String profile = '$baseUrl/pelamar/profil';
  static const String updateProfile = '$baseUrl/pelamar/profil/update';
  static const String updatePassword =
      '$baseUrl/pelamar/profil/update-password';

  // Endpoint Spesifik Mandiri untuk Pendidikan
  static const String pendidikan = "$baseUrl/pelamar/profil/pendidikan";

  // Endpoint Spesifik Mandiri untuk Skill
  static const String skill = "$baseUrl/pelamar/profil/skill";

  // Endpoint Spesifik Mandiri untuk Pengalaman Kerja
  static const String pengalaman = "$baseUrl/pelamar/profil/pengalaman";

  // Fitur Lowongan & Tracking
  static const String jobs = '$baseUrl/jobs';
  static const String trackingTimeline = '$baseUrl/tracking-timeline';
  static const String detailJadwal = '$baseUrl/interview-schedule';
}
