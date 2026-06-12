# C.A.F.E. Job Mobile App ☕📱

**C.A.F.E. Job Mobile App** (Career & Food Enterprise) adalah aplikasi seluler inovatif berbasis Flutter yang dirancang khusus untuk para pencari kerja di industri F&B (kafe dan restoran). Aplikasi ini memberikan pengalaman *mobile-first* bagi pelamar untuk menemukan lowongan terbaik, melamar pekerjaan, serta memantau proses rekrutmen secara *real-time* langsung dari genggaman.

---

## 🌟 Fitur Utama (Pelamar / Applicant)

### 1. Autentikasi & Sesi Aman
- **Secure Login:** Manajemen sesi pengguna yang persisten menggunakan `SharedPreferences` sehingga pengguna tidak perlu login berulang kali setelah menutup aplikasi.
- **Manajemen Akun & Keamanan:** Fitur enkripsi pembaruan password secara berkala langsung dari dalam aplikasi pada halaman pengaturan akun dengan validasi berlapis.
- **Firebase Google Sign-In:** Fasilitas autentikasi instan menggunakan akun Google melalui *Firebase Authentication*, memberikan alternatif pendaftaran dan masuk aplikasi yang lebih cepat, praktis, dan aman hanya dengan satu ketukan (*one-tap login*).
- **Forgot Password Recovery:** Fitur pemulihan akun yang aman melalui permintaan tautan pengaturan ulang kata sandi (*reset password link*) yang dikirimkan otomatis ke email pengguna yang terdaftar, mempermudah pemulihan akses akun secara mandiri.

### 2. Eksplorasi Lowongan F&B Kontemporer
- **Pencarian Kerja Cerdas:** Menjelajahi lowongan kerja aktif berdasarkan posisi, nama kafe, lokasi kafe, kisaran gaji, dan batas akhir pendaftaran.
- **Detail Lowongan Komprehensif:** Melihat deskripsi tugas, kriteria pelamar, serta mengajukan jawaban atas pertanyaan kustom yang disediakan langsung oleh pemilik kafe.

### 3. Tracking Timeline Interaktif (Deep-Linking)
- **Status Real-Time:** Pantau status lamaran secara visual melalui lini masa interaktif (Diproses, Ditinjau/Reviewed, Wawancara, Diterima, atau Ditolak).
- **Auto-Trigger Handler:** Fitur *deep-link* interaktif di mana notifikasi yang diklik dapat langsung mengarahkan pengguna untuk membuka modal detail jadwal wawancara, lokasi fisik, catatan HRD, atau tautan *virtual meeting* secara otomatis.

### 4. Notifikasi Multi-Channel Terintegrasi
- **FCM Push Notification:** Menerima notifikasi *pop-up* instan di latar belakang (*background*) maupun latar depan (*foreground*) perangkat saat ada pembaruan status lamaran dari pihak kafe.
- **WhatsApp Notification:** Integrasi gateway WhatsApp otomatis (via Fonnte) untuk mengirimkan pesan otomatis status lamaran ke nomor HP pelamar.

---

## 🛠️ Teknologi & Package yang Digunakan

| Komponen | Teknologi / Package | Deskripsi |
| --- | --- | --- |
| **Framework** | Flutter (Dart) | Core Framework Mobile lintas platform |
| **HTTP Client** | `http` | Integrasi REST API ke Backend Server Laravel |
| **Local Storage** | `shared_preferences` | Penyimpanan Token JWT & Status Login lokal |
| **Push Notification**| `firebase_messaging` & `firebase_core` | Layanan pengiriman Firebase Cloud Messaging (FCM) |
| **UI Design** | Google Fonts & Material Design 3 | Desain antarmuka modern, bersih, dan inklusif |

---

## 🚀 Instalasi & Konfigurasi Lokal

### Prasyarat
- Flutter SDK (Versi Stable terbaru)
- Dart SDK
- Android Studio / VS Code (dengan ekstensi Flutter & Dart)
- Android Emulator atau Perangkat Fisik (dengan fitur USB Debugging aktif)
- Backend API Laravel C.A.F.E Job yang sudah berjalan

### Langkah-langkah Penginstalan

1. **Clone Repository**
   ```bash
   git clone [https://github.com/syahrulhannan07/mobile_cofe_job.git](https://github.com/syahrulhannan07/mobile_cofe_job.git)
   cd mobile_cofe_job
   ```
   
2. **Installasi Dependency Package**
   ```bash
   flutter pub get
   ```
   
3. **Konfigurasi API Endpoint**
   - Jika menggunakan Emulator Android bawaan: static const String baseUrl = "[http://10.0.2.2:8000/api](http://10.0.2.2:8000/api)";
   - Jika menggunakan Perangkat Fisik (Real Device / HP Infinix): Pastikan HP dan Laptop berada dalam satu jaringan Wi-Fi yang sama 
4. **Konfigurasi Firebase (FCM)**
   Pastikan Anda telah mendaftarkan project ke Firebase Console dan mengunduh file kredensial:
   - Letakkan file google-services.json di dalam direktori proyek Flutter Anda pada folder: android/app/.

6. **Jalankan Aplikasi**
   ```bash
   flutter run
   ```
   
---

## 📸 Tampilan Preview
*(Tambahkan screenshot atau link demo di sini di masa mendatang)*

---

## 📄 Lisensi
Proyek ini dikembangkan untuk kebutuhan internal dan berlisensi di bawah [MIT License](LICENSE).

---

Developed with ❤️ by **Tim C.A.F.E. Job**

   git clone [https://github.com/syahrulhannan07/mobile_cofe_job.git](https://github.com/syahrulhannan07/mobile_cofe_job.git)
   cd mobile_cofe_job
