import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data'; // Tambahan untuk Uint8List
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/network/api_config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  XFile? _imageFile; // Menggunakan XFile bawaan image_picker
  Uint8List?
  _imageBytes; // Menyimpan gambar dalam bentuk bytes agar cross-platform
  final _picker = ImagePicker();
  bool _isLoading = false;

  // Controller Utama Form Profil Master
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _ttlController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _tentangSayaController = TextEditingController();

  // Menyimpan data dinamis beserta ID dari database
  List<Map<String, dynamic>> _pendidikanForms = [];
  List<Map<String, dynamic>> _skillForms = [];
  List<Map<String, dynamic>> _pengalamanForms = [];

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
    _clearDynamicControllers();
    super.dispose();
  }

  void _clearDynamicControllers() {
    for (var form in _pendidikanForms) {
      form['institusi']?.dispose();
      form['jurusan']?.dispose();
      form['tingkat']?.dispose();
      form['tahun_mulai']?.dispose();
      form['tahun_selesai']?.dispose();
    }
    for (var form in _skillForms) {
      form['nama_skill']?.dispose();
    }
    for (var form in _pengalamanForms) {
      form['nama_perusahaan']?.dispose();
      form['posisi']?.dispose();
      form['tanggal_mulai']?.dispose();
      form['tanggal_selesai']?.dispose();
      form['deskripsi']?.dispose();
    }
  }

  // --- FUNGSI GENERATE ELEMENT FORM BARU ---
  void _addPendidikanForm({
    String? id,
    String institusi = '',
    String jurusan = '',
    String tingkat = '',
    String tahunMulai = '',
    String tahunSelesai = '',
  }) {
    setState(() {
      _pendidikanForms.add({
        'id': id,
        'institusi': TextEditingController(text: institusi),
        'jurusan': TextEditingController(text: jurusan),
        'tingkat': TextEditingController(text: tingkat),
        'tahun_mulai': TextEditingController(text: tahunMulai),
        'tahun_selesai': TextEditingController(text: tahunSelesai),
      });
    });
  }

  void _addSkillForm({String? id, String namaSkill = ''}) {
    setState(() {
      _skillForms.add({
        'id': id,
        'nama_skill': TextEditingController(text: namaSkill),
      });
    });
  }

  void _addPengalamanForm({
    String? id,
    String namaPerusahaan = '',
    String posisi = '',
    String tanggalMulai = '',
    String tanggalSelesai = '',
    String deskripsi = '',
  }) {
    setState(() {
      _pengalamanForms.add({
        'id': id,
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
        Uri.parse(ApiConfig.profile),
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

            String genderVal =
                profile['jenis_kelamin']?.toString().trim().toLowerCase() ?? '';
            if (genderVal == 'l' ||
                genderVal == 'laki-laki' ||
                genderVal == 'laki_laki') {
              _genderController.text = 'Laki-laki';
            } else if (genderVal == 'p' || genderVal == 'perempuan') {
              _genderController.text = 'Perempuan';
            } else {
              _genderController.text = 'Laki-laki';
            }

            _phoneController.text = profile['nomor_telepon']?.toString() ?? '';
            _alamatController.text = profile['alamat']?.toString() ?? '';
            _tentangSayaController.text =
                profile['tentang_saya']?.toString() ?? '';

            // Generate URL Foto
            String? rawPhotoUrl = profile['foto_profil']?.toString();
            if (rawPhotoUrl != null && rawPhotoUrl.isNotEmpty) {
              if (rawPhotoUrl.startsWith('http://') ||
                  rawPhotoUrl.startsWith('https://')) {
                _currentPhotoUrl = rawPhotoUrl;
              } else {
                final uri = Uri.parse(ApiConfig.profile);
                final baseUrl =
                    "${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}";
                final cleanPath = rawPhotoUrl.startsWith('/')
                    ? rawPhotoUrl
                    : '/$rawPhotoUrl';
                _currentPhotoUrl = "$baseUrl/storage$cleanPath";
              }
            } else {
              _currentPhotoUrl = null;
            }

            _clearDynamicControllers();
            _pendidikanForms.clear();
            _skillForms.clear();
            _pengalamanForms.clear();

            // 1. Load Data Pendidikan
            if (profile['pendidikan'] != null &&
                profile['pendidikan'] is List) {
              for (var item in profile['pendidikan']) {
                final detectedId =
                    item['id'] ??
                    item['id_pendidikan'] ??
                    item['id_riwayat_pendidikan'];
                _addPendidikanForm(
                  id: detectedId?.toString(),
                  institusi: item['institusi']?.toString() ?? '',
                  jurusan: item['jurusan']?.toString() ?? '',
                  tingkat: item['tingkat']?.toString() ?? '',
                  tahunMulai: item['tahun_mulai'] != null
                      ? item['tahun_mulai'].toString().split('T')[0]
                      : '',
                  tahunSelesai: item['tahun_selesai'] != null
                      ? item['tahun_selesai'].toString().split('T')[0]
                      : '',
                );
              }
            }

            // 2. Load Data Skill
            var skillData = profile['skills'] ?? profile['skill'];
            if (skillData != null && skillData is List) {
              for (var item in skillData) {
                final detectedId =
                    item['id'] ?? item['id_skill'] ?? item['id_keahlian'];
                _addSkillForm(
                  id: detectedId?.toString(),
                  namaSkill: (item['nama_skill'] ?? item['skill'] ?? '')
                      .toString(),
                );
              }
            }

            // 3. Load Data Pengalaman Kerja
            if (profile['pengalaman_kerja'] != null &&
                profile['pengalaman_kerja'] is List) {
              for (var item in profile['pengalaman_kerja']) {
                final detectedId =
                    item['id'] ??
                    item['id_pengalaman'] ??
                    item['id_pengalaman_kerja'];
                _addPengalamanForm(
                  id: detectedId?.toString(),
                  namaPerusahaan: item['nama_perusahaan']?.toString() ?? '',
                  posisi: item['posisi']?.toString() ?? '',
                  tanggalMulai: item['tanggal_mulai'] != null
                      ? item['tanggal_mulai'].toString().split('T')[0]
                      : '',
                  tanggalSelesai: item['tanggal_selesai'] != null
                      ? item['tanggal_selesai'].toString().split('T')[0]
                      : '',
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
      _showSnackBar("Terjadi kesalahan koneksi saat memuat data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- HAPUS DATA PERMANEN DARI DATABASE ---
  Future<void> _deleteItemDirectly(
    String type,
    String id,
    int localIndex,
  ) async {
    bool confirm = await _showConfirmDeleteDialog();
    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      String endpoint = '';
      if (type == 'pendidikan') endpoint = '${ApiConfig.pendidikan}/$id';
      if (type == 'skill') endpoint = '${ApiConfig.skill}/$id';
      if (type == 'pengalaman') endpoint = '${ApiConfig.pengalaman}/$id';

      print("DEBUG: Menghapus URL -> $endpoint");

      final response = await http.delete(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print("DEBUG: DELETE Res Status -> ${response.statusCode}");
      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          if (type == 'pendidikan') _pendidikanForms.removeAt(localIndex);
          if (type == 'skill') _skillForms.removeAt(localIndex);
          if (type == 'pengalaman') _pengalamanForms.removeAt(localIndex);
        });
        _showSnackBar("Data $type berhasil dihapus permanen.");
      } else {
        final errorData = json.decode(response.body);
        _showSnackBar(
          errorData['message'] ?? "Gagal menghapus data dari server.",
        );
      }
    } catch (e) {
      _showSnackBar("Kesalahan sistem saat menghapus data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- PROSES SIMPAN / UPDATE MENGGUNAKAN ENDPOINT SPESIFIK ---
  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        _showSnackBar("Sesi Anda habis. Silakan login kembali.");
        return;
      }

      // 1. UPDATE DATA UTAMA PROFIL
      final uri = Uri.parse(ApiConfig.updateProfile);
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        })
        ..fields['nama_lengkap'] = _namaController.text
        ..fields['tanggal_lahir'] = _ttlController.text
        ..fields['jenis_kelamin'] = _genderController.text.trim()
        ..fields['nomor_telepon'] = _phoneController.text
        ..fields['alamat'] = _alamatController.text
        ..fields['tentang_saya'] = _tentangSayaController.text;

      // MODIFIKASI: Menggunakan bytes agar kompatibel untuk Web dan Mobile
      if (_imageBytes != null && _imageFile != null) {
        String filename = _imageFile!.name;
        String ext = filename.split('.').last.toLowerCase();
        String mimeType = (ext == 'png') ? 'image/png' : 'image/jpeg';

        request.files.add(
          http.MultipartFile.fromBytes(
            'foto_profil',
            _imageBytes!,
            filename: filename,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      final streamedResponse = await request.send();
      final mainResponse = await http.Response.fromStream(streamedResponse);

      if (mainResponse.statusCode != 200) {
        final errorData = json.decode(mainResponse.body);
        _showSnackBar(
          errorData['message'] ?? "Gagal memperbarui data utama profil.",
        );
        setState(() => _isLoading = false);
        return;
      }

      Map<String, String> jsonHeaders = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      // 2. PROSES ITERASI DATA PENDIDIKAN (POST / PUT)
      for (var f in _pendidikanForms) {
        String institusi = (f['institusi'] as TextEditingController).text;
        if (institusi.isEmpty) continue;

        Map<String, dynamic> body = {
          'institusi': institusi,
          'jurusan': (f['jurusan'] as TextEditingController).text,
          'tingkat': (f['tingkat'] as TextEditingController).text,
          'tahun_mulai': (f['tahun_mulai'] as TextEditingController).text,
          'tahun_selesai': (f['tahun_selesai'] as TextEditingController).text,
        };

        if (f['id'] != null && f['id'].toString().isNotEmpty) {
          await http.put(
            Uri.parse('${ApiConfig.pendidikan}/${f['id']}'),
            headers: jsonHeaders,
            body: json.encode(body),
          );
        } else {
          await http.post(
            Uri.parse(ApiConfig.pendidikan),
            headers: jsonHeaders,
            body: json.encode(body),
          );
        }
      }

      // 3. PROSES ITERASI DATA SKILL (HANYA POST DATA BARU)
      for (var f in _skillForms) {
        String namaSkill = (f['nama_skill'] as TextEditingController).text;
        if (namaSkill.isEmpty) continue;

        // Jika skill sudah memiliki ID, lewati (tidak bisa/perlu update text)
        if (f['id'] != null && f['id'].toString().isNotEmpty) {
          continue;
        }

        // Jalankan POST hanya untuk skill baru yang diketik user
        Map<String, dynamic> body = {'nama_skill': namaSkill};
        await http.post(
          Uri.parse(ApiConfig.skill),
          headers: jsonHeaders,
          body: json.encode(body),
        );
      }

      // 4. PROSES ITERASI DATA PENGALAMAN (POST / PUT)
      for (var f in _pengalamanForms) {
        String namaPerusahaan =
            (f['nama_perusahaan'] as TextEditingController).text;
        if (namaPerusahaan.isEmpty) continue;

        Map<String, dynamic> body = {
          'nama_perusahaan': namaPerusahaan,
          'posisi': (f['posisi'] as TextEditingController).text,
          'tanggal_mulai': (f['tanggal_mulai'] as TextEditingController).text,
          'tanggal_selesai':
              (f['tanggal_selesai'] as TextEditingController).text,
          'deskripsi': (f['deskripsi'] as TextEditingController).text,
        };

        if (f['id'] != null && f['id'].toString().isNotEmpty) {
          await http.put(
            Uri.parse('${ApiConfig.pengalaman}/${f['id']}'),
            headers: jsonHeaders,
            body: json.encode(body),
          );
        } else {
          await http.post(
            Uri.parse(ApiConfig.pengalaman),
            headers: jsonHeaders,
            body: json.encode(body),
          );
        }
      }

      _showSuccessDialog();
      _fetchProfileData(); // Reload biar ID baru dari DB turun sinkron
    } catch (e) {
      _showSnackBar("Terjadi kesalahan sistem saat memperbarui data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showConfirmDeleteDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Hapus Data"),
            content: const Text(
              "Apakah Anda yakin ingin menghapus riwayat ini secara permanen dari database?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Batal"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Hapus", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  // MODIFIKASI: Membaca gambar ke dalam bentuk byte
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageFile = pickedFile;
        _imageBytes = bytes;
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
      } catch (_) {}
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
                                  // MODIFIKASI: Menggunakan MemoryImage untuk menampilkan bytes
                                  backgroundImage: _imageBytes != null
                                      ? MemoryImage(_imageBytes!)
                                      : (_currentPhotoUrl != null
                                            ? NetworkImage(_currentPhotoUrl!)
                                                  as ImageProvider
                                            : null),
                                  child:
                                      _imageBytes == null &&
                                          _currentPhotoUrl == null
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

                          // --- RIWAYAT PENDIDIKAN ---
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
                                    final item = _pendidikanForms[index];
                                    return _buildCardWrapper(
                                      index: index,
                                      onRemove: () {
                                        if (item['id'] != null &&
                                            item['id'].toString().isNotEmpty) {
                                          _deleteItemDirectly(
                                            'pendidikan',
                                            item['id'],
                                            index,
                                          );
                                        } else {
                                          setState(
                                            () => _pendidikanForms.removeAt(
                                              index,
                                            ),
                                          );
                                        }
                                      },
                                      child: Column(
                                        children: [
                                          _buildSimpleField(
                                            "Nama Institusi",
                                            item['institusi']!,
                                          ),
                                          _buildSimpleField(
                                            "Jurusan",
                                            item['jurusan']!,
                                          ),
                                          _buildSimpleField(
                                            "Tingkat (ex: S1/D3)",
                                            item['tingkat']!,
                                          ),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildSimpleDateField(
                                                  "Tahun Mulai",
                                                  item['tahun_mulai']!,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: _buildSimpleDateField(
                                                  "Tahun Selesai",
                                                  item['tahun_selesai']!,
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

                          // --- SKILL / KEAHLIAN ---
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
                                    final item = _skillForms[index];
                                    final bool isFromDb =
                                        item['id'] != null &&
                                        item['id'].toString().isNotEmpty;

                                    return _buildCardWrapper(
                                      index: index,
                                      onRemove: () {
                                        if (isFromDb) {
                                          _deleteItemDirectly(
                                            'skill',
                                            item['id'],
                                            index,
                                          );
                                        } else {
                                          setState(
                                            () => _skillForms.removeAt(index),
                                          );
                                        }
                                      },
                                      child: _buildSimpleField(
                                        isFromDb
                                            ? "Nama Skill (Tersimpan)"
                                            : "Nama Skill Baru",
                                        item['nama_skill']!,
                                        readOnly: isFromDb,
                                      ),
                                    );
                                  },
                                ),

                          const Divider(height: 40, thickness: 1),

                          // --- PENGALAMAN KERJA ---
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
                                    final item = _pengalamanForms[index];
                                    return _buildCardWrapper(
                                      index: index,
                                      onRemove: () {
                                        if (item['id'] != null &&
                                            item['id'].toString().isNotEmpty) {
                                          _deleteItemDirectly(
                                            'pengalaman',
                                            item['id'],
                                            index,
                                          );
                                        } else {
                                          setState(
                                            () => _pengalamanForms.removeAt(
                                              index,
                                            ),
                                          );
                                        }
                                      },
                                      child: Column(
                                        children: [
                                          _buildSimpleField(
                                            "Nama Perusahaan",
                                            item['nama_perusahaan']!,
                                          ),
                                          _buildSimpleField(
                                            "Posisi / Jabatan",
                                            item['posisi']!,
                                          ),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildSimpleDateField(
                                                  "Tanggal Mulai",
                                                  item['tanggal_mulai']!,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: _buildSimpleDateField(
                                                  "Tanggal Selesai",
                                                  item['tanggal_selesai']!,
                                                ),
                                              ),
                                            ],
                                          ),
                                          _buildSimpleField(
                                            "Deskripsi Pekerjaan",
                                            item['deskripsi']!,
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

  // --- REUSABLE COMPONENTS ---
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
            items: items
                .map(
                  (String val) =>
                      DropdownMenuItem<String>(value: val, child: Text(val)),
                )
                .toList(),
            onChanged: (value) => setState(() => controller.text = value ?? ''),
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

  Widget _buildSimpleField(
    String hint,
    TextEditingController controller, {
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        style: TextStyle(
          fontSize: 14,
          color: readOnly ? Colors.grey[600] : Colors.black,
        ),
        decoration: InputDecoration(
          labelText: hint,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
          filled: readOnly,
          fillColor: readOnly ? Colors.grey[100] : Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: readOnly
              ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                )
              : null,
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
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
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
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
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Data master dan semua perubahan riwayat kompetensi Anda telah berhasil diproses.",
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
                    onPressed: () => Navigator.pop(context),
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
}
