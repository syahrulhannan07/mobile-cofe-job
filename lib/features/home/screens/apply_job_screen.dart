import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/colors.dart';

class ApplyJobScreen extends StatefulWidget {
  final String jobTitle;

  const ApplyJobScreen({super.key, required this.jobTitle});

  @override
  State<ApplyJobScreen> createState() => _ApplyJobScreenState();
}

class _ApplyJobScreenState extends State<ApplyJobScreen>
    with SingleTickerProviderStateMixin {
  int currentStep = 1;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _flyAnimation;

  // --- DATA STATE TAHAP 1 (Dokumen) ---
  String? cvFileName;
  String? ijazahFileName;
  String? suratLamaranFileName;

  // --- DATA STATE TAHAP 2 (Pertanyaan) ---
  final TextEditingController _gajiController = TextEditingController();
  final TextEditingController _kualifikasiController = TextEditingController();
  final TextEditingController _pengalamanController = TextEditingController();

  // --- DATA STATE TAHAP 3 (Profile) ---
  File? _profileImage;
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _ttlController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();

  @override
  void initState() {
    super.initState();
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

  // Fungsi Pilih File Tahap 1
  Future<void> _pickFile(String type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );

    if (result != null) {
      setState(() {
        if (type == 'cv') cvFileName = result.files.single.name;
        if (type == 'ijazah') ijazahFileName = result.files.single.name;
        if (type == 'lamaran') suratLamaranFileName = result.files.single.name;
      });
    }
  }

  // Fungsi Pilih Foto Tahap 3
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  void _nextStep() {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentStep == 5) return _buildSuccessScreen();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
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
          "Curriculum Vitae (CV)",
          cvFileName ?? "PDF max 2MB",
          () => _pickFile('cv'),
          isUploaded: cvFileName != null,
        ),
        _buildUploadCard(
          Icons.school_rounded,
          "Ijazah Terakhir",
          ijazahFileName ?? "PDF atau JPG max 5MB",
          () => _pickFile('ijazah'),
          isUploaded: ijazahFileName != null,
        ),
        _buildUploadCard(
          Icons.mail_rounded,
          "Surat Lamaran",
          suratLamaranFileName ?? "PDF max 2MB",
          () => _pickFile('lamaran'),
          isUploaded: suratLamaranFileName != null,
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
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : const NetworkImage('https://via.placeholder.com/150')
                            as ImageProvider,
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
          "Masukkan nama",
          controller: _namaController,
        ),
        _buildInputField(
          "TEMPAT, TANGGAL LAHIR",
          "Contoh: Jakarta, 12 Mei 1995",
          controller: _ttlController,
        ),
        _buildInputField(
          "ALAMAT LENGKAP",
          "Jl. Kedai Kopi No. 8, Jakarta Selatan",
          isTextArea: true,
          controller: _alamatController,
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildStep4Review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          "Harap periksa ringkasan seluruh kelengkapan data lamaran.",
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textMain,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 25),
        const Text(
          "Profil Saya",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
              CircleAvatar(
                radius: 30,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : const NetworkImage('https://via.placeholder.com/150')
                          as ImageProvider,
              ),
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
                        fontSize: 16,
                      ),
                    ),
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
          "Jawaban Pertanyaan",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        _buildReviewCard("Gaji yang diinginkan:", _gajiController.text),
        _buildReviewCard("Kualifikasi:", _kualifikasiController.text),
        const SizedBox(height: 20),
        const Text(
          "Dokumen Terlampir",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
              if (cvFileName != null)
                _buildFileReviewItem(cvFileName!, "Curriculum Vitae"),
              if (ijazahFileName != null)
                _buildFileReviewItem(ijazahFileName!, "Ijazah"),
              if (suratLamaranFileName != null)
                _buildFileReviewItem(suratLamaranFileName!, "Surat Lamaran"),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // --- WIDGET HELPERS (MODIFIED) ---

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
          color: isUploaded ? Colors.green.shade200 : Colors.grey.shade300,
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
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

  // --- TETAP (Header, Stepper, Success Screen, etc.) ---
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
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF422E26),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Sertifikat & Portofolio",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Tambahkan dokumen pendukungmu.",
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFFF0B85E),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 20),
          ),
        ],
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
              onPressed: () => Navigator.pop(context),
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
