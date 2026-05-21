import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
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

            // 🌟 SINKRONISASI JENIS KELAMIN: Membaca variasi output string dari Laravel
            String genderVal =
                profile['jenis_kelamin']?.toString().toLowerCase() ?? '';
            if (genderVal == 'l' || genderVal == 'laki-laki') {
              _genderController.text = 'Laki-laki';
            } else if (genderVal == 'p' || genderVal == 'perempuan') {
              _genderController.text = 'Perempuan';
            } else {
              _genderController.text =
                  'Laki-laki'; // Default fallback agar tidak kosong
            }

            _phoneController.text = profile['nomor_telepon']?.toString() ?? '';
            _alamatController.text = profile['alamat']?.toString() ?? '';
            _tentangSayaController.text =
                profile['tentang_saya']?.toString() ?? '';

            // 🌟 SINKRONISASI FOTO PROFIL: Menggabungkan path relatif database dengan domain server utama
            String? rawPhotoUrl = profile['foto_profil']?.toString();
            if (rawPhotoUrl != null && rawPhotoUrl.isNotEmpty) {
              if (rawPhotoUrl.startsWith('http')) {
                _currentPhotoUrl = rawPhotoUrl;
              } else {
                // Menangani jika kembalian berupa 'storage/...' atau '/storage/...'
                String cleanPath = rawPhotoUrl.startsWith('/')
                    ? rawPhotoUrl.substring(1)
                    : rawPhotoUrl;
                _currentPhotoUrl = 'https://cofe-job.cicd.my.id/$cleanPath';
              }
            } else {
              _currentPhotoUrl = null;
            }

            _pendidikanForms.clear();
            _skillForms.clear();
            _pengalamanForms.clear();

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

  // --- POP-UP DIALOG SUKSES ---
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20.0,
                  offset: const Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 55,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Profil Diperbarui",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Data riwayat pendidikan, skill kompetensi, dan pengalaman kerja Anda telah berhasil disimpan ke database.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF635147),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Selesai",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
        // 🌟 FIX UTAMA VALiDATION: Mengirim string kecil utuh 'laki-laki' atau 'perempuan' agar lolos validasi Laravel
        ..fields['jenis_kelamin'] =
            _genderController.text.toLowerCase() == 'perempuan'
            ? 'perempuan'
            : 'laki-laki'
        ..fields['nomor_telepon'] = _phoneController.text
        ..fields['alamat'] = _alamatController.text
        ..fields['tentang_saya'] = _tentangSayaController.text;

      // Filter & Mapping Data Pendidikan
      List<Map<String, String>> pendidikanData = _pendidikanForms
          .where((f) => f['institusi']!.text.isNotEmpty)
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

      // Filter & Mapping Data Skill (Key database backend: 'skills')
      List<Map<String, String>> skillData = _skillForms
          .where((f) => f['nama_skill']!.text.isNotEmpty)
          .map(
            (f) => {
              'nama_skill': f['nama_skill']!.text,
              'deskripsi': f['deskripsi']!.text,
            },
          )
          .toList();
      request.fields['skills'] = json.encode(skillData);

      // Filter & Mapping Data Pengalaman Kerja
      List<Map<String, String>> pengalamanData = _pengalamanForms
          .where((f) => f['nama_perusahaan']!.text.isNotEmpty)
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
        _showSuccessDialog();
        _fetchProfileData(); // Reload data segar dari database
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

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    DateTime initialDate = DateTime.now();
    if (controller.text.isNotEmpty) {
      try {
        initialDate = DateFormat('yyyy-MM-dd').parse(controller.text);
      } catch (_) {
        initialDate = DateTime.now();
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF635147),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
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

                          _buildTextField(
                            "Nama Lengkap",
                            "Masukkan nama lengkap",
                            _namaController,
                          ),
                          _buildDateField(
                            "Tanggal Lahir",
                            "Pilih tanggal lahir",
                            _ttlController,
                          ),
                          _buildDropdownField(
                            "Jenis Kelamin",
                            _genderController,
                            ["Laki-laki", "Perempuan"],
                          ),
                          _buildTextField(
                            "Nomor Telepon",
                            "08xxxxxxxxxx",
                            _phoneController,
                            keyboardType: TextInputType.phone,
                          ),
                          _buildTextField(
                            "Alamat",
                            "Alamat lengkap saat ini",
                            _alamatController,
                          ),

                          const Divider(height: 40, thickness: 1),

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
                                                child: _buildSimpleDateField(
                                                  "Tahun Mulai",
                                                  _pendidikanForms[index]['tahun_mulai']!,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: _buildSimpleDateField(
                                                  "Tahun Selesai",
                                                  _pendidikanForms[index]['tahun_selesai']!,
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
                                                child: _buildSimpleDateField(
                                                  "Tanggal Mulai",
                                                  _pengalamanForms[index]['tanggal_mulai']!,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: _buildSimpleDateField(
                                                  "Tanggal Selesai",
                                                  _pengalamanForms[index]['tanggal_selesai']!,
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
            fontSize: 17,
            color: Color(0xFF635147),
          ),
        ),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(
            Icons.add_circle_outline,
            color: Color(0xFF635147),
            size: 20,
          ),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          msg,
          style: TextStyle(
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
            fontSize: 13,
          ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.brownLight.withOpacity(0.4)),
      ),
      child: Stack(
        children: [
          Padding(padding: const EdgeInsets.only(top: 25), child: child),
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: onRemove,
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
                size: 22,
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF635147).withOpacity(0.1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                "Data #${index + 1}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Color(0xFF635147),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(
    String label,
    String hint,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            readOnly: true,
            onTap: () => _selectDate(context, controller),
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: const Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFF635147),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    TextEditingController controller,
    List<String> items,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: controller.text.isEmpty ? null : controller.text,
            items: items.map((String val) {
              return DropdownMenuItem<String>(value: val, child: Text(val));
            }).toList(),
            onChanged: (value) {
              setState(() {
                controller.text = value ?? '';
              });
            },
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleField(String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
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

  Widget _buildSimpleDateField(String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: () => _selectDate(context, controller),
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: hint,
          suffixIcon: const Icon(
            Icons.calendar_month_rounded,
            size: 18,
            color: Color(0xFF635147),
          ),
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
}
