import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/colors.dart';
import '../../../core/network/api_config.dart';

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

class _ApplyJobScreenState extends State<ApplyJobScreen>
    with SingleTickerProviderStateMixin {
  int currentStep = 1;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _flyAnimation;

  // --- DATA STATE TAHAP 1 (Dokumen Berkas) ---
  File? cvFile;
  File? ijazahFile;
  File? suratLamaranFile;
  File? sertifikatFile;

  String? cvFileName;
  String? ijazahFileName;
  String? suratLamaranFileName;
  String? sertifikatFileName;

  // --- DATA STATE TAHAP 2 (Pertanyaan Deskriptif) ---
  final TextEditingController _gajiController = TextEditingController();
  final TextEditingController _kualifikasiController = TextEditingController();
  final TextEditingController _pengalamanController = TextEditingController();

  // --- DATA STATE TAHAP 3 (Profil Sinkronisasi DB) ---
  File? _profileImage;
  String? _networkProfileImageUrl;
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _ttlController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingProfileData();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _flyAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0),
          end: const Offset(1.5, -1.5),
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.5, 1.0, curve: Curves.easeInOutCubic),
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _gajiController.dispose();
    _kualifikasiController.dispose();
    _pengalamanController.dispose();
    _namaController.dispose();
    _ttlController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  // Sinkronisasi data profil pelamar yang sudah pernah diisi sebelumnya
  Future<void> _loadExistingProfileData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      // Coba ambil dari SharedPreferences lokal terlebih dahulu untuk kecepatan render
      String? localName = prefs.getString("user_name");
      if (localName != null) _namaController.text = localName;

      // Ambil data terbaru langsung dari backend database profile (/v1/pelamar/profil)
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/pelamar/profil"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        var pelamar = resData['data'];
        if (pelamar != null) {
          setState(() {
            _namaController.text =
                pelamar['nama_lengkap'] ??
                pelamar['nama_pengguna'] ??
                _namaController.text;
            _ttlController.text = pelamar['tempat_tanggal_lahir'] ?? '';
            _alamatController.text = pelamar['alamat'] ?? '';
            if (pelamar['foto_profil'] != null) {
              _networkProfileImageUrl = pelamar['foto_profil'];
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal sinkronisasi data profil: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Pengambilan Dokumen Tahap 1
  Future<void> _pickFile(String type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        File pickedFile = File(result.files.single.path!);
        if (type == 'cv') {
          cvFile = pickedFile;
          cvFileName = result.files.single.name;
        } else if (type == 'ijazah') {
          ijazahFile = pickedFile;
          ijazahFileName = result.files.single.name;
        } else if (type == 'lamaran') {
          suratLamaranFile = pickedFile;
          suratLamaranFileName = result.files.single.name;
        } else if (type == 'sertifikat') {
          sertifikatFile = pickedFile;
          sertifikatFileName = result.files.single.name;
        }
      });
    }
  }

  // Pengambilan Foto Pengguna Tahap 3
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  // Validasi berpindah ke halaman berikutnya
  void _nextStep() {
    if (currentStep == 1) {
      if (cvFile == null || ijazahFile == null || suratLamaranFile == null) {
        _showValidationError(
          "Harap lengkapi semua dokumen wajib (CV, Ijazah, & Surat Lamaran)!",
        );
        return;
      }
    } else if (currentStep == 2) {
      if (_gajiController.text.trim().isEmpty ||
          _kualifikasiController.text.trim().isEmpty ||
          _pengalamanController.text.trim().isEmpty) {
        _showValidationError("Semua pertanyaan perusahaan wajib diisi!");
        return;
      }
    } else if (currentStep == 3) {
      if (_namaController.text.trim().isEmpty ||
          _ttlController.text.trim().isEmpty ||
          _alamatController.text.trim().isEmpty) {
        _showValidationError("Data profile tidak boleh ada yang kosong!");
        return;
      }
    } else if (currentStep == 4) {
      _submitFormLamaran();
      return;
    }

    if (currentStep < 5) {
      setState(() => currentStep++);
      if (currentStep == 5) {
        _animationController.forward();
      }
    }
  }

  void _prevStep() {
    if (currentStep > 1) {
      setState(() => currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- PROSES SUBMIT TRANSACTION MULTI-STEP SESUAI ROUTES/API.PHP LARAVEL ---
  Future<void> _submitFormLamaran() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      // ==========================================
      // KELOMPOK 1: MULAI LAMARAN (POST /v1/lamaran/mulai)
      // ==========================================
      var uriMulai = Uri.parse("${ApiConfig.baseUrl}/lamaran/mulai");
      var responseMulai = await http.post(
        uriMulai,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: {"id_lowongan": widget.jobId},
      );

      if (responseMulai.statusCode != 200 && responseMulai.statusCode != 201) {
        final err = jsonDecode(responseMulai.body);
        _showValidationError(
          err['message'] ?? "Gagal menginisialisasi lamaran.",
        );
        setState(() => _isLoading = false);
        return;
      }

      final dataMulai = jsonDecode(responseMulai.body);
      // Mendapatkan ID Lamaran yang di-generate backend (menyesuaikan format draf respon bungkus Laravel kamu)
      dynamic idLamaranRaw = dataMulai['data'] != null
          ? dataMulai['data']['id']
          : dataMulai['id'];
      if (idLamaranRaw == null) {
        _showValidationError(
          "Format respon server tidak sesuai (ID Lamaran Kosong).",
        );
        setState(() => _isLoading = false);
        return;
      }
      String idLamaran = idLamaranRaw.toString();

      // ==========================================
      // KELOMPOK 2: SIMPAN JAWABAN PERTANYAAN (POST /v1/lamaran/{id}/jawaban)
      // ==========================================
      var uriJawaban = Uri.parse(
        "${ApiConfig.baseUrl}/lamaran/$idLamaran/jawaban",
      );
      var responseJawaban = await http.post(
        uriJawaban,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "gaji_diinginkan": _gajiController.text,
          "kualifikasi": _kualifikasiController.text,
          "pengalaman": _pengalamanController.text,
        }),
      );

      if (responseJawaban.statusCode != 200 &&
          responseJawaban.statusCode != 201) {
        final err = jsonDecode(responseJawaban.body);
        _showValidationError(
          err['message'] ?? "Gagal menyimpan jawaban kuisioner.",
        );
        setState(() => _isLoading = false);
        return;
      }

      // Opsional: Perbarui Profile Utama Terlebih Dahulu seandainya ada perubahan data profile pelamar
      var uriUpdateProfil = Uri.parse(
        "${ApiConfig.baseUrl}/pelamar/profil/update",
      );
      var profilRequest = http.MultipartRequest('POST', uriUpdateProfil);
      profilRequest.headers.addAll({
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      });
      profilRequest.fields['nama_lengkap'] = _namaController.text;
      profilRequest.fields['tempat_tanggal_lahir'] = _ttlController.text;
      profilRequest.fields['alamat'] = _alamatController.text;
      if (_profileImage != null) {
        profilRequest.files.add(
          await http.MultipartFile.fromPath('foto_profil', _profileImage!.path),
        );
      }
      await profilRequest.send();

      // ==========================================
      // KELOMPOK 3: UPLOAD DOKUMEN BERKAS (POST /v1/lamaran/{id}/dokumen)
      // ==========================================
      var uriDokumen = Uri.parse(
        "${ApiConfig.baseUrl}/lamaran/$idLamaran/dokumen",
      );
      var docRequest = http.MultipartRequest('POST', uriDokumen);
      docRequest.headers.addAll({
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      });

      if (cvFile != null) {
        docRequest.files.add(
          await http.MultipartFile.fromPath('cv', cvFile!.path),
        );
      }
      if (ijazahFile != null) {
        docRequest.files.add(
          await http.MultipartFile.fromPath('ijazah', ijazahFile!.path),
        );
      }
      if (suratLamaranFile != null) {
        docRequest.files.add(
          await http.MultipartFile.fromPath(
            'surat_lamaran',
            suratLamaranFile!.path,
          ),
        );
      }
      if (sertifikatFile != null) {
        docRequest.files.add(
          await http.MultipartFile.fromPath('sertifikat', sertifikatFile!.path),
        );
      }

      var docStreamedRes = await docRequest.send();
      var docResponse = await http.Response.fromStream(docStreamedRes);

      if (docResponse.statusCode != 200 && docResponse.statusCode != 201) {
        final err = jsonDecode(docResponse.body);
        _showValidationError(
          err['message'] ?? "Gagal mengunggah file dokumen pelamar.",
        );
        setState(() => _isLoading = false);
        return;
      }

      // ==========================================
      // KELOMPOK 4: FINALISASI/KIRIM (POST /v1/lamaran/{id}/kirim)
      // ==========================================
      var uriKirim = Uri.parse("${ApiConfig.baseUrl}/lamaran/$idLamaran/kirim");
      var responseKirim = await http.post(
        uriKirim,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (responseKirim.statusCode == 200 || responseKirim.statusCode == 201) {
        setState(() => currentStep = 5);
        _animationController.forward();
      } else {
        final errorData = jsonDecode(responseKirim.body);
        _showValidationError(
          errorData['message'] ??
              "Gagal menyelesaikan pengiriman berkas lamaran.",
        );
      }
    } catch (e) {
      _showValidationError(
        "Terjadi kesalahan sistem atau jaringan internet: $e",
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentStep == 5) return _buildSuccessScreen();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _prevStep();
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFF0B85E)),
                )
              : Column(
                  children: [
                    _buildHeader(context),
                    _buildStepper(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: _buildCurrentStepContent(),
                      ),
                    ),
                    _buildBottomButtons(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (currentStep) {
      case 1:
        return _buildStep1Dokumen();
      case 2:
        return _buildStep2Pertanyaan();
      case 3:
        return _buildStep3Profile();
      case 4:
        return _buildStep4Review();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1Dokumen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          "Silakan lengkapi dokumen persyaratan di bawah ini untuk memulai perjalanan kariermu.",
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textMain,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 25),
        _buildUploadCard(
          Icons.description_rounded,
          "Curriculum Vitae (CV) *Wajib",
          cvFileName ?? "PDF max 2MB",
          () => _pickFile('cv'),
          isUploaded: cvFile != null,
        ),
        _buildUploadCard(
          Icons.school_rounded,
          "Ijazah Terakhir *Wajib",
          ijazahFileName ?? "PDF atau JPG max 5MB",
          () => _pickFile('ijazah'),
          isUploaded: ijazahFile != null,
        ),
        _buildUploadCard(
          Icons.mail_rounded,
          "Surat Lamaran *Wajib",
          suratLamaranFileName ?? "PDF max 2MB",
          () => _pickFile('lamaran'),
          isUploaded: suratLamaranFile != null,
        ),
        const SizedBox(height: 10),
        _buildSupportingDocSection(),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildStep2Pertanyaan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          "Silakan jawab pertanyaan pada lowongan ini untuk membantu perusahaan mengenal potensi Anda lebih dalam.",
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textMain,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 25),
        _buildInputField(
          "Berapa gaji bulanan yang diinginkan?",
          "Rp Contoh: 5,000,000",
          controller: _gajiController,
        ),
        _buildInputField(
          "Kualifikasi mana yang anda miliki?",
          "Sebutkan sertifikasi atau keahlian utama Anda...",
          isTextArea: true,
          controller: _kualifikasiController,
        ),
        _buildInputField(
          "Apakah anda mempunyai pengalaman kerja?",
          "Sebutkan posisi dan perusahaan sebelumnya...",
          isTextArea: true,
          controller: _pengalamanController,
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildStep3Profile() {
    ImageProvider profileImageProvider = const NetworkImage(
      'https://via.placeholder.com/150',
    );
    if (_profileImage != null) {
      profileImageProvider = FileImage(_profileImage!);
    } else if (_networkProfileImageUrl != null &&
        _networkProfileImageUrl!.isNotEmpty) {
      profileImageProvider = NetworkImage(_networkProfileImageUrl!);
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: profileImageProvider,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0B85E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 25),
        _buildInputField(
          "NAMA LENGKAP",
          "Masukkan nama lengkap",
          controller: _namaController,
        ),
        _buildInputField(
          "TEMPAT, TANGGAL LAHIR",
          "Contoh: Indramayu, 12 Mei 2003",
          controller: _ttlController,
        ),
        _buildInputField(
          "ALAMAT LENGKAP",
          "Jl. Lohbener Lama No. 08, Indramayu",
          isTextArea: true,
          controller: _alamatController,
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildStep4Review() {
    ImageProvider reviewImageProvider = const NetworkImage(
      'https://via.placeholder.com/150',
    );
    if (_profileImage != null) {
      reviewImageProvider = FileImage(_profileImage!);
    } else if (_networkProfileImageUrl != null &&
        _networkProfileImageUrl!.isNotEmpty) {
      reviewImageProvider = NetworkImage(_networkProfileImageUrl!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          "Harap periksa kembali ringkasan seluruh kelengkapan data lamaran Anda sebelum dikirim.",
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textMain,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 25),
        const Text(
          "Profil Pelamar",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF422E26),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              CircleAvatar(radius: 30, backgroundImage: reviewImageProvider),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _namaController.text.isEmpty
                          ? "Nama Belum Diisi"
                          : _namaController.text,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _ttlController.text,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      _alamatController.text,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Tanggapan Pertanyaan",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF422E26),
          ),
        ),
        const SizedBox(height: 10),
        _buildReviewCard("Gaji Bulanan Yang Diinginkan:", _gajiController.text),
        _buildReviewCard(
          "Kompetensi & Kualifikasi:",
          _kualifikasiController.text,
        ),
        _buildReviewCard("Pengalaman Kerja:", _pengalamanController.text),
        const SizedBox(height: 20),
        const Text(
          "Dokumen Pendukung Terlampir",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF422E26),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              if (cvFile != null)
                _buildFileReviewItem(cvFileName!, "Curriculum Vitae (CV)"),
              if (ijazahFile != null)
                _buildFileReviewItem(ijazahFileName!, "Ijazah Kelulusan"),
              if (suratLamaranFile != null)
                _buildFileReviewItem(
                  suratLamaranFileName!,
                  "Surat Lamaran Kerja",
                ),
              if (sertifikatFile != null)
                _buildFileReviewItem(
                  sertifikatFileName!,
                  "Sertifikat Pendukung",
                ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildUploadCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isUploaded = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7F2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isUploaded ? Colors.green.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 30, color: const Color(0xFFB8860B)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: isUploaded
                  ? Colors.green
                  : const Color(0xFFF0B85E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text(
              isUploaded ? "Ganti" : "Pilih",
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    String hint, {
    bool isTextArea = false,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF422E26),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: isTextArea ? 4 : 1,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF9F7F2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildReviewCard(String question, String answer) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            answer.isEmpty ? "-" : answer,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileReviewItem(String fileName, String label) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(
            Icons.insert_drive_file,
            color: Color(0xFFF0B85E),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  fileName,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: _prevStep,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF6B4F31),
            ),
          ),
          Expanded(
            child: Text(
              widget.jobTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B4F31),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      child: Row(
        children: [
          _stepIndicator(1, "Dokumen"),
          _stepLine(1),
          _stepIndicator(2, "Pertanyaan"),
          _stepLine(2),
          _stepIndicator(3, "Profile"),
          _stepLine(3),
          _stepIndicator(4, "Review"),
        ],
      ),
    );
  }

  Widget _stepIndicator(int n, String label) {
    bool isActive = currentStep == n;
    bool isCompleted = currentStep > n;
    return Column(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: isActive || isCompleted
                ? const Color(0xFFF0B85E)
                : const Color(0xFFE0E0E0),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              "$n",
              style: TextStyle(
                color: isActive || isCompleted ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _stepLine(int n) {
    return Expanded(
      child: Container(
        height: 2,
        color: currentStep > n
            ? const Color(0xFFF0B85E)
            : const Color(0xFFE0E0E0),
        margin: const EdgeInsets.only(bottom: 15),
      ),
    );
  }

  Widget _buildSupportingDocSection() {
    return GestureDetector(
      onTap: () => _pickFile('sertifikat'),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF422E26),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Sertifikat & Portofolio (Opsional)",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    sertifikatFileName ?? "Tambahkan dokumen pendukungmu.",
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: sertifikatFile != null
                    ? Colors.green
                    : const Color(0xFFF0B85E),
                shape: BoxShape.circle,
              ),
              child: Icon(
                sertifikatFile != null ? Icons.check : Icons.add,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _prevStep,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF6B4F31)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Kembali",
                style: TextStyle(color: Color(0xFF6B4F31)),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF0B85E),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                currentStep == 4 ? "Kirim" : "Lanjut",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF422E26),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0B85E),
                  shape: BoxShape.circle,
                ),
                child: SlideTransition(
                  position: _flyAnimation,
                  child: const Icon(
                    Icons.send_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Lamaran Terkirim",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDF2E2),
                foregroundColor: const Color(0xFF422E26),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Selesai",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
