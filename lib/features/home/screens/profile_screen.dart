import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _image;
  final _picker = ImagePicker();
  bool _isLoading = false;

  // Definisikan Controller Utama
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _ttlController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _tentangSayaController = TextEditingController();

  // Struktur Data Form Dinamis untuk Relasi Database
  List<Map<String, TextEditingController>> _pendidikanForms = [];
  List<Map<String, TextEditingController>> _skillForms = [];
  List<Map<String, TextEditingController>> _pengalamanForms = [];

  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _ttlController.dispose();
    _genderController.dispose();
    _phoneController.dispose();
    _alamatController.dispose();
    _tentangSayaController.dispose();

    // Dispose semua controller dinamis
    for (var form in _pendidikanForms) {
      form.values.forEach((controller) => controller.dispose());
    }
    for (var form in _skillForms) {
      form.values.forEach((controller) => controller.dispose());
    }
    for (var form in _pengalamanForms) {
      form.values.forEach((controller) => controller.dispose());
    }
    super.dispose();
  }

  // --- FUNGSI TAMBAH FORM DINAMIS ---
  void _addPendidikanForm({
    String institusi = '',
    String jurusan = '',
    String tingkat = '',
    String tahunMulai = '',
    String tahunSelesai = '',
  }) {
    setState(() {
      _pendidikanForms.add({
        'institusi': TextEditingController(text: institusi),
        'jurusan': TextEditingController(text: jurusan),
        'tingkat': TextEditingController(text: tingkat),
        'tahun_mulai': TextEditingController(text: tahunMulai),
        'tahun_selesai': TextEditingController(text: tahunSelesai),
      });
    });
  }

  void _addSkillForm({String namaSkill = '', String deskripsi = ''}) {
    setState(() {
      _skillForms.add({
        'nama_skill': TextEditingController(text: namaSkill),
        'deskripsi': TextEditingController(text: deskripsi),
      });
    });
  }

  void _addPengalamanForm({
    String namaPerusahaan = '',
    String posisi = '',
    String tanggalMulai = '',
    String tanggalSelesai = '',
    String deskripsi = '',
  }) {
    setState(() {
      _pengalamanForms.add({
        'nama_perusahaan': TextEditingController(text: namaPerusahaan),
        'posisi': TextEditingController(text: posisi),
        'tanggal_mulai': TextEditingController(text: tanggalMulai),
        'tanggal_selesai': TextEditingController(text: tanggalSelesai),
        'deskripsi': TextEditingController(text: deskripsi),
      });
    });
  }

  // --- AMBIL DATA PROFIL DARI API ---
  Future<void> _fetchProfileData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        _showSnackBar("Token tidak ditemukan. Silakan login ulang.");
        return;
      }

      final response = await http.get(
        Uri.parse('https://cofe-job.cicd.my.id/api/v1/pelamar/profil'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final profile = data['data'] ?? data;

        if (profile != null) {
          setState(() {
            _namaController.text = profile['nama_lengkap']?.toString() ?? '';
            _ttlController.text = profile['tanggal_lahir']?.toString() ?? '';
            _genderController.text = profile['jenis_kelamin']?.toString() ?? '';
            _phoneController.text = profile['nomor_telepon']?.toString() ?? '';
            _alamatController.text = profile['alamat']?.toString() ?? '';
            _tentangSayaController.text =
                profile['tentang_saya']?.toString() ?? '';
            _currentPhotoUrl = profile['foto_profil'];

            // Clear form lama jika ada sebelum mengisi dari DB
            _pendidikanForms.clear();
            _skillForms.clear();
            _pengalamanForms.clear();

            // 1. Parsing list Pendidikan dari DB
            if (profile['pendidikan'] != null &&
                profile['pendidikan'] is List) {
              for (var item in profile['pendidikan']) {
                _addPendidikanForm(
                  institusi: item['institusi']?.toString() ?? '',
                  jurusan: item['jurusan']?.toString() ?? '',
                  tingkat: item['tingkat']?.toString() ?? '',
                  tahunMulai: item['tahun_mulai']?.toString() ?? '',
                  tahunSelesai: item['tahun_selesai']?.toString() ?? '',
                );
              }
            }

            // 2. Parsing list Skill dari DB
            var skillData = profile['skills'] ?? profile['skill'];
            if (skillData != null && skillData is List) {
              for (var item in skillData) {
                _addSkillForm(
                  namaSkill: (item['nama_skill'] ?? item['skill'] ?? '')
                      .toString(),
                  deskripsi: item['deskripsi']?.toString() ?? '',
                );
              }
            }

            // 3. Parsing list Pengalaman Kerja dari DB
            if (profile['pengalaman_kerja'] != null &&
                profile['pengalaman_kerja'] is List) {
              for (var item in profile['pengalaman_kerja']) {
                _addPengalamanForm(
                  namaPerusahaan: item['nama_perusahaan']?.toString() ?? '',
                  posisi: item['posisi']?.toString() ?? '',
                  tanggalMulai: item['tanggal_mulai']?.toString() ?? '',
                  tanggalSelesai: item['tanggal_selesai']?.toString() ?? '',
                  deskripsi: item['deskripsi']?.toString() ?? '',
                );
              }
            }
          });
        }
      } else {
        final errorData = json.decode(response.body);
        _showSnackBar(errorData['message'] ?? "Gagal mengambil data profil.");
      }
    } catch (e) {
      _showSnackBar("Terjadi kesalahan koneksi atau sistem: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- SIMPAN & UPDATE PROFIL KE API ---
  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        _showSnackBar("Sesi Anda habis. Silakan login kembali.");
        return;
      }

      final uri = Uri.parse(
        'https://cofe-job.cicd.my.id/api/v1/pelamar/profil/update',
      );
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        })
        ..fields['nama_lengkap'] = _namaController.text
        ..fields['tanggal_lahir'] = _ttlController.text
        ..fields['jenis_kelamin'] = _genderController.text
        ..fields['nomor_telepon'] = _phoneController.text
        ..fields['alamat'] = _alamatController.text
        ..fields['tentang_saya'] = _tentangSayaController.text;

      // Konversi list objek form dinamis menjadi JSON String agar bisa diterima oleh API Backend Laravel
      List<Map<String, String>> pendidikanData = _pendidikanForms
          .map(
            (f) => {
              'institusi': f['institusi']!.text,
              'jurusan': f['jurusan']!.text,
              'tingkat': f['tingkat']!.text,
              'tahun_mulai': f['tahun_mulai']!.text,
              'tahun_selesai': f['tahun_selesai']!.text,
            },
          )
          .toList();
      request.fields['pendidikan'] = json.encode(pendidikanData);

      List<Map<String, String>> skillData = _skillForms
          .map(
            (f) => {
              'nama_skill': f['nama_skill']!.text,
              'deskripsi': f['deskripsi']!.text,
            },
          )
          .toList();
      request.fields['skill'] = json.encode(skillData);

      List<Map<String, String>> pengalamanData = _pengalamanForms
          .map(
            (f) => {
              'nama_perusahaan': f['nama_perusahaan']!.text,
              'posisi': f['posisi']!.text,
              'tanggal_mulai': f['tanggal_mulai']!.text,
              'tanggal_selesai': f['tanggal_selesai']!.text,
              'deskripsi': f['deskripsi']!.text,
            },
          )
          .toList();
      request.fields['pengalaman_kerja'] = json.encode(pengalamanData);

      if (_image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('foto_profil', _image!.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        _showSnackBar("Profil berhasil diperbarui!");
        _fetchProfileData();
      } else {
        final errorData = json.decode(response.body);
        _showSnackBar(errorData['message'] ?? "Gagal memperbarui profil.");
      }
    } catch (e) {
      _showSnackBar("Terjadi kesalahan sistem saat memperbarui data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    const Color coffeeBrown = Color(0xFF635147);
    const Color bgCream = Color(0xFFFDF7F0);

    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        child: _isLoading && _namaController.text.isEmpty
            ? const Center(child: CircularProgressIndicator(color: coffeeBrown))
            : Column(
                children: [
                  const SizedBox(height: 20),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.brownLight,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            left: 10,
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: coffeeBrown,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const Text(
                            "Profile",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: coffeeBrown,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar Foto Profil
                          Center(
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 65,
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage: _image != null
                                      ? FileImage(_image!)
                                      : (_currentPhotoUrl != null
                                            ? NetworkImage(_currentPhotoUrl!)
                                                  as ImageProvider
                                            : null),
                                  child:
                                      _image == null && _currentPhotoUrl == null
                                      ? const Icon(
                                          Icons.person,
                                          size: 80,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _pickImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: coffeeBrown,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.edit_note_rounded,
                                        color: coffeeBrown,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Form Biodata Utama
                          _buildInputField(
                            "Nama Lengkap",
                            "Masukkan nama lengkap",
                            _namaController,
                          ),
                          _buildInputField(
                            "Tempat, tanggal lahir",
                            "Contoh: Indramayu, 12-10-2000",
                            _ttlController,
                          ),
                          _buildInputField(
                            "Jenis Kelamin",
                            "Laki-laki / Perempuan",
                            _genderController,
                          ),
                          _buildInputField(
                            "Nomor Telepon",
                            "08xxxxxxxxxx",
                            _phoneController,
                            keyboardType: TextInputType.phone,
                          ),
                          _buildInputField(
                            "Alamat",
                            "Alamat lengkap saat ini",
                            _alamatController,
                          ),

                          const Divider(height: 40, thickness: 1),

                          // --- SECTION DINAMIS PENDIDIKAN ---
                          _buildSectionHeader(
                            "Riwayat Pendidikan",
                            () => _addPendidikanForm(),
                          ),
                          const SizedBox(height: 10),
                          _pendidikanForms.isEmpty
                              ? _buildEmptyState("Belum ada data pendidikan.")
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _pendidikanForms.length,
                                  itemBuilder: (context, index) {
                                    return _buildCardWrapper(
                                      index: index,
                                      onRemove: () => setState(
                                        () => _pendidikanForms.removeAt(index),
                                      ),
                                      child: Column(
                                        children: [
                                          _buildSimpleField(
                                            "Nama Institusi",
                                            _pendidikanForms[index]['institusi']!,
                                          ),
                                          _buildSimpleField(
                                            "Jurusan",
                                            _pendidikanForms[index]['jurusan']!,
                                          ),
                                          _buildSimpleField(
                                            "Tingkat (ex: S1/D3)",
                                            _pendidikanForms[index]['tingkat']!,
                                          ),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildSimpleField(
                                                  "Tahun Mulai",
                                                  _pendidikanForms[index]['tahun_mulai']!,
                                                  keyboardType:
                                                      TextInputType.datetime,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: _buildSimpleField(
                                                  "Tahun Selesai",
                                                  _pendidikanForms[index]['tahun_selesai']!,
                                                  keyboardType:
                                                      TextInputType.datetime,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                          const Divider(height: 40, thickness: 1),

                          // --- SECTION DINAMIS SKILL ---
                          _buildSectionHeader(
                            "Keahlian / Skill",
                            () => _addSkillForm(),
                          ),
                          const SizedBox(height: 10),
                          _skillForms.isEmpty
                              ? _buildEmptyState("Belum ada data keahlian.")
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _skillForms.length,
                                  itemBuilder: (context, index) {
                                    return _buildCardWrapper(
                                      index: index,
                                      onRemove: () => setState(
                                        () => _skillForms.removeAt(index),
                                      ),
                                      child: Column(
                                        children: [
                                          _buildSimpleField(
                                            "Nama Skill",
                                            _skillForms[index]['nama_skill']!,
                                          ),
                                          _buildSimpleField(
                                            "Deskripsi Keahlian",
                                            _skillForms[index]['deskripsi']!,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                          const Divider(height: 40, thickness: 1),

                          // --- SECTION DINAMIS PENGALAMAN KERJA ---
                          _buildSectionHeader(
                            "Pengalaman Kerja",
                            () => _addPengalamanForm(),
                          ),
                          const SizedBox(height: 10),
                          _pengalamanForms.isEmpty
                              ? _buildEmptyState(
                                  "Belum ada data pengalaman kerja.",
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _pengalamanForms.length,
                                  itemBuilder: (context, index) {
                                    return _buildCardWrapper(
                                      index: index,
                                      onRemove: () => setState(
                                        () => _pengalamanForms.removeAt(index),
                                      ),
                                      child: Column(
                                        children: [
                                          _buildSimpleField(
                                            "Nama Perusahaan",
                                            _pengalamanForms[index]['nama_perusahaan']!,
                                          ),
                                          _buildSimpleField(
                                            "Posisi / Jabatan",
                                            _pengalamanForms[index]['posisi']!,
                                          ),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildSimpleField(
                                                  "Tanggal Mulai",
                                                  _pengalamanForms[index]['tanggal_mulai']!,
                                                  keyboardType:
                                                      TextInputType.datetime,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: _buildSimpleField(
                                                  "Tanggal Selesai",
                                                  _pengalamanForms[index]['tanggal_selesai']!,
                                                  keyboardType:
                                                      TextInputType.datetime,
                                                ),
                                              ),
                                            ],
                                          ),
                                          _buildSimpleField(
                                            "Deskripsi Pekerjaan",
                                            _pengalamanForms[index]['deskripsi']!,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                          const Divider(height: 40, thickness: 1),

                          // Tentang Saya
                          const Text(
                            "Tentang Saya",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _tentangSayaController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText:
                                  "Ceritakan singkat tentang diri Anda...",
                              filled: true,
                              fillColor: AppColors.brownLight.withOpacity(0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Tombol Simpan Perubahan
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: coffeeBrown,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: _isLoading ? null : _updateProfile,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "Simpan Perubahan",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // --- WIDGET HELPER UI ---

  Widget _buildSectionHeader(String title, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF635147),
          ),
        ),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF635147)),
          label: const Text(
            "Tambah",
            style: TextStyle(
              color: Color(0xFF635147),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Text(
        msg,
        style: TextStyle(
          color: Colors.grey[500],
          fontStyle: FontStyle.italic,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildCardWrapper({
    required int index,
    required VoidCallback onRemove,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.brownLight.withOpacity(0.5)),
      ),
      child: Stack(
        children: [
          Padding(padding: const EdgeInsets.only(top: 20), child: child),
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: onRemove,
              child: const Icon(
                Icons.cancel,
                color: Colors.redAccent,
                size: 22,
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Text(
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleField(
    String hint,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: hint,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: AppColors.brownLight.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
