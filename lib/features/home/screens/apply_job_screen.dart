import 'dart:io' as io;
import 'dart:convert';
import 'package:flutter/foundation.dart'; // Untuk mengecek kIsWeb
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/network/api_config.dart';
// ignore: unused_import
import 'tracking_timeline_screen.dart';

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

  // --- INTEGRASI STATE API BACKEND (COFE-JOB) ---
  String? idLamaran;
  List<dynamic> dokumenWajib = [];
  List<dynamic> pertanyaanSeleksi = [];

  // Mapping Dokumen Tahap 1
  Map<String, Uint8List> uploadedFiles = {};
  Map<String, String> uploadedFileNames = {};

  // Mapping Jawaban Tahap 2: { id_pertanyaan (String) → TextEditingController }
  // SATU map ini saja yang digunakan, _jawabanControllers dihapus (redundan)
  Map<String, TextEditingController> pertanyaanControllers = {};

  // --- DATA STATE TAHAP 3 (Profil Pelamar Lengkap Sesuai Profile Screen) ---
  XFile? _imageFile;
  Uint8List? _profileImageBytes;
  String? _profileImagePath;      
  String? _networkProfileImageUrl;
  final _picker = ImagePicker();

  bool _isEditingMaster = false;
  
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _ttlController = TextEditingController();
  String _jenisKelamin = 'Laki-laki'; 
  final TextEditingController _noTelpController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _tentangSayaController = TextEditingController();
  
  // List Dinamis Form
  List<Map<String, dynamic>> _pendidikanForms = [];
  List<Map<String, dynamic>> _skillForms = [];
  List<Map<String, dynamic>> _pengalamanForms = [];

  @override
  void initState() {
    super.initState();
    _inisialisasiLamaran(); 

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
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
    pertanyaanControllers.forEach((_, controller) => controller.dispose());
    _namaController.dispose();
    _ttlController.dispose();
    _noTelpController.dispose();
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

  String _safeStringConvert(dynamic value) {
    if (value == null) return '';
    if (value is List) {
      return value.join(', '); 
    }
    return value.toString();
  }

  // ==========================================
  // MANAJEMEN LIST DINAMIS TAHAP 3
  // ==========================================
  void _addPendidikanForm({String? id, String institusi = '', String jurusan = '', String tingkat = '', String tahunMulai = '', String tahunSelesai = '', bool isEditing = true}) {
    setState(() {
      _pendidikanForms.add({
        'id': id,
        'institusi': TextEditingController(text: institusi),
        'jurusan': TextEditingController(text: jurusan),
        'tingkat': TextEditingController(text: tingkat),
        'tahun_mulai': TextEditingController(text: tahunMulai),
        'tahun_selesai': TextEditingController(text: tahunSelesai),
        'isEditing': isEditing,
      });
    });
  }

  // MENAMBAHKAN FUNGSI PENGHAPUS FORM PENDIDIKAN YANG HILANG
  void _removePendidikanForm(int index) {
    setState(() {
      if (index >= 0 && index < _pendidikanForms.length) {
        var form = _pendidikanForms[index];
        form['institusi']?.dispose();
        form['jurusan']?.dispose();
        form['tingkat']?.dispose();
        form['tahun_mulai']?.dispose();
        form['tahun_selesai']?.dispose();
        _pendidikanForms.removeAt(index);
      }
    });
  }

  void _addSkillForm({String? id, String namaSkill = '', bool isEditing = true}) {
    setState(() {
      _skillForms.add({
        'id': id,
        'nama_skill': TextEditingController(text: namaSkill),
        'isEditing': isEditing,
      });
    });
  }

  // MENAMBAHKAN FUNGSI PENGHAPUS FORM SKILL YANG HILANG
  void _removeSkillForm(int index) {
    setState(() {
      if (index >= 0 && index < _skillForms.length) {
        var form = _skillForms[index];
        form['nama_skill']?.dispose();
        _skillForms.removeAt(index);
      }
    });
  }

  void _addPengalamanForm({String? id, String namaPerusahaan = '', String posisi = '', String tanggalMulai = '', String tanggalSelesai = '', String deskripsi = '', bool isEditing = true}) {
    setState(() {
      _pengalamanForms.add({
        'id': id,
        'nama_perusahaan': TextEditingController(text: namaPerusahaan),
        'posisi': TextEditingController(text: posisi),
        'tanggal_mulai': TextEditingController(text: tanggalMulai),
        'tanggal_selesai': TextEditingController(text: tanggalSelesai),
        'deskripsi': TextEditingController(text: deskripsi),
        'isEditing': isEditing,
      });
    });
  }

  // MENAMBAHKAN FUNGSI PENGHAPUS FORM PENGALAMAN YANG HILANG
  void _removePengalamanForm(int index) {
    setState(() {
      if (index >= 0 && index < _pengalamanForms.length) {
        var form = _pengalamanForms[index];
        form['nama_perusahaan']?.dispose();
        form['posisi']?.dispose();
        form['tanggal_mulai']?.dispose();
        form['tanggal_selesai']?.dispose();
        form['deskripsi']?.dispose();
        _pengalamanForms.removeAt(index);
      }
    });
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime initialDate = DateTime.now();
    try {
      if (controller.text.isNotEmpty) {
        initialDate = DateFormat('yyyy-MM-dd').parse(controller.text);
      }
    } catch (_) {}
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4B2E2B), 
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

  // ==========================================
  // INITIALIZATION: MULAI LAMARAN & GET DETAIL
  // ==========================================
  Future<void> _inisialisasiLamaran() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      // 1. Inisialisasi Mulai Lamaran
      final resMulai = await http.post(
        Uri.parse(ApiConfig.mulaiLamaran),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "id_lowongan": widget.jobId.toString(),
        }),
      );

      if (resMulai.statusCode == 200 || resMulai.statusCode == 201) {
        final resData = jsonDecode(resMulai.body);
        if (resData['status'] == 'success' && resData['data'] != null) {
          var dataMulai = resData['data'];
          
          if (dataMulai['id_lamaran'] is List) {
            idLamaran = (dataMulai['id_lamaran'] as List).isNotEmpty ? dataMulai['id_lamaran'][0].toString() : null;
          } else {
            idLamaran = dataMulai['id_lamaran']?.toString();
          }
          
          if (dataMulai['dokumen_wajib'] is List) {
            dokumenWajib = dataMulai['dokumen_wajib'];
          }
        }
      } else {
        final errData = jsonDecode(resMulai.body);
        _showValidationError(errData['message'] ?? "Gagal memulai lamaran.");
        Navigator.pop(context);
        return;
      }

      // 2. Fetch Detail Lowongan untuk mendapatkan pertanyaan_seleksi
      final resDetail = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/lowongan/${widget.jobId}"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("=== [ApplyJob] Detail Lowongan status: ${resDetail.statusCode} ===");
      debugPrint("=== [ApplyJob] Body: ${resDetail.body} ===");

      if (resDetail.statusCode == 200) {
        final resData = jsonDecode(resDetail.body);
        
        // Telusuri semua kemungkinan lokasi pertanyaan_seleksi dalam response
        List<dynamic>? foundPertanyaan;

        if (resData['data'] != null) {
          var dataLowongan = resData['data'];

          // Kemungkinan 1: data.pertanyaan_seleksi (struktur flat)
          if (dataLowongan['pertanyaan_seleksi'] is List) {
            foundPertanyaan = dataLowongan['pertanyaan_seleksi'];
          }
          // Kemungkinan 2: data.lowongan.pertanyaan_seleksi (nested)
          else if (dataLowongan['lowongan'] is Map &&
              dataLowongan['lowongan']['pertanyaan_seleksi'] is List) {
            foundPertanyaan = dataLowongan['lowongan']['pertanyaan_seleksi'];
          }
          // Kemungkinan 3: data.data.pertanyaan_seleksi (double nested)
          else if (dataLowongan['data'] is Map &&
              dataLowongan['data']['pertanyaan_seleksi'] is List) {
            foundPertanyaan = dataLowongan['data']['pertanyaan_seleksi'];
          }
        }
        // Kemungkinan 4: langsung di root response (tanpa wrapper data)
        else if (resData['pertanyaan_seleksi'] is List) {
          foundPertanyaan = resData['pertanyaan_seleksi'];
        }

        if (foundPertanyaan != null && foundPertanyaan.isNotEmpty) {
          pertanyaanSeleksi = foundPertanyaan;
          debugPrint("=== [ApplyJob] Ditemukan ${pertanyaanSeleksi.length} pertanyaan ===");
          debugPrint("=== [ApplyJob] Sample key pertanyaan pertama: ${pertanyaanSeleksi.first.keys.toList()} ===");

          pertanyaanControllers.clear();
          for (var p in pertanyaanSeleksi) {
            // Coba semua kemungkinan nama field ID pertanyaan
            String idPertanyaan = (
              p['id_pertanyaan'] ??
              p['id_pertanyaan_lowongan'] ??
              p['id'] ??
              ''
            ).toString();

            if (idPertanyaan.isNotEmpty && idPertanyaan != 'null') {
              pertanyaanControllers[idPertanyaan] = TextEditingController();
              debugPrint("=== [ApplyJob] Controller dibuat untuk id: $idPertanyaan ===");
            } else {
              debugPrint("=== [ApplyJob] PERINGATAN: id pertanyaan kosong/null untuk item: $p ===");
            }
          }
        } else {
          debugPrint("=== [ApplyJob] TIDAK DITEMUKAN pertanyaan_seleksi di response. Keys root: ${resData.keys.toList()} ===");
          if (resData['data'] != null) {
            debugPrint("=== [ApplyJob] Keys data: ${(resData['data'] as Map).keys.toList()} ===");
          }
        }
      } else {
        debugPrint("=== [ApplyJob] Gagal fetch detail lowongan: ${resDetail.statusCode} ===");
      }

      // 3. Ambil data profil pelamar
      await _fetchProfileData();

    } catch (e) {
      debugPrint("Gagal inisialisasi runtime lamaran: $e");
      _showValidationError("Terjadi kesalahan sinkronisasi data server.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

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

            String genderVal = profile['jenis_kelamin']?.toString().trim().toLowerCase() ?? '';
            if (genderVal == 'l' || genderVal == 'laki-laki' || genderVal == 'laki_laki') {
              _jenisKelamin = 'Laki-laki';
            } else if (genderVal == 'p' || genderVal == 'perempuan') {
              _jenisKelamin = 'Perempuan';
            }

            _noTelpController.text = profile['nomor_telepon']?.toString() ?? '';
            _alamatController.text = profile['alamat']?.toString() ?? '';
            _tentangSayaController.text = profile['tentang_saya']?.toString() ?? '';

            // Foto URL
            String? rawPhotoUrl = profile['foto_profil']?.toString();
            if (rawPhotoUrl != null && rawPhotoUrl.isNotEmpty) {
              if (rawPhotoUrl.startsWith('http://') || rawPhotoUrl.startsWith('https://')) {
                _networkProfileImageUrl = rawPhotoUrl;
              } else {
                final uri = Uri.parse(ApiConfig.profile);
                final baseUrl = "${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}";
                final cleanPath = rawPhotoUrl.startsWith('/') ? rawPhotoUrl : '/$rawPhotoUrl';
                _networkProfileImageUrl = "$baseUrl/storage$cleanPath";
              }
            }

            _clearDynamicControllers();
            _pendidikanForms.clear();
            _skillForms.clear();
            _pengalamanForms.clear();

            // Load Data Pendidikan
            if (profile['pendidikan'] != null && profile['pendidikan'] is List) {
              for (var item in profile['pendidikan']) {
                _addPendidikanForm(
                  id: (item['id'] ?? item['id_pendidikan'] ?? item['id_riwayat_pendidikan'])?.toString(),
                  institusi: item['institusi']?.toString() ?? item['nama_instansi']?.toString() ?? '',
                  jurusan: item['jurusan']?.toString() ?? '',
                  tingkat: item['tingkat']?.toString() ?? '',
                  tahunMulai: item['tahun_mulai'] != null ? item['tahun_mulai'].toString().split('T')[0] : '',
                  tahunSelesai: item['tahun_selesai'] != null ? item['tahun_selesai'].toString().split('T')[0] : '',
                  isEditing: false,
                );
              }
            }

            // Load Data Skill
            var skillData = profile['skills'] ?? profile['skill'];
            if (skillData != null && skillData is List) {
              for (var item in skillData) {
                _addSkillForm(
                  id: (item['id'] ?? item['id_skill'] ?? item['id_keahlian'])?.toString(),
                  namaSkill: (item['nama_skill'] ?? item['skill'] ?? '') .toString(),
                  isEditing: false,
                );
              }
            }

            // Load Data Pengalaman Kerja
            if (profile['pengalaman_kerja'] != null && profile['pengalaman_kerja'] is List) {
              for (var item in profile['pengalaman_kerja']) {
                _addPengalamanForm(
                  id: (item['id'] ?? item['id_pengalaman'] ?? item['id_pengalaman_kerja'])?.toString(),
                  namaPerusahaan: item['nama_perusahaan']?.toString() ?? '',
                  posisi: item['posisi']?.toString() ?? '',
                  tanggalMulai: item['tanggal_mulai'] != null ? item['tanggal_mulai'].toString().split('T')[0] : '',
                  tanggalSelesai: item['tanggal_selesai'] != null ? item['tanggal_selesai'].toString().split('T')[0] : '',
                  deskripsi: item['deskripsi']?.toString() ?? '',
                  isEditing: false,
                );
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error memuat profil: $e");
    }
  }

  // ==========================================
  // API INTEGRASI SIMPAN PER ITEM TAHAP 3
  // ==========================================
  Future<void> _updateMasterProfile() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final uri = Uri.parse(ApiConfig.updateProfile);
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        })
        ..fields['nama_lengkap'] = _namaController.text
        ..fields['tanggal_lahir'] = _ttlController.text
        ..fields['jenis_kelamin'] = _jenisKelamin
        ..fields['nomor_telepon'] = _noTelpController.text
        ..fields['alamat'] = _alamatController.text
        ..fields['tentang_saya'] = _tentangSayaController.text;

      if (_profileImageBytes != null && _imageFile != null) {
        String filename = _imageFile!.name;
        String ext = filename.split('.').last.toLowerCase();
        String mimeType = (ext == 'png') ? 'image/png' : 'image/jpeg';

        request.files.add(
          http.MultipartFile.fromBytes(
            'foto_profil',
            _profileImageBytes!,
            filename: filename,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      final streamedResponse = await request.send();
      final mainResponse = await http.Response.fromStream(streamedResponse);

      if (mainResponse.statusCode == 200) {
        _showValidationSuccess("Profil utama berhasil disimpan.");
        setState(() => _isEditingMaster = false);
        _fetchProfileData();
      } else {
        final errorData = json.decode(mainResponse.body);
        _showValidationError(errorData['message'] ?? "Gagal memperbarui profil utama.");
      }
    } catch (e) {
      _showValidationError("Terjadi kesalahan: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSinglePendidikan(int index) async {
    final form = _pendidikanForms[index];
    String institusi = (form['institusi'] as TextEditingController).text;
    if (institusi.isEmpty) { _showValidationError("Nama Institusi harus diisi."); return; }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      Map<String, dynamic> body = {
        'institusi': institusi,
        'jurusan': (form['jurusan'] as TextEditingController).text,
        'tingkat': (form['tingkat'] as TextEditingController).text,
        'tahun_mulai': (form['tahun_mulai'] as TextEditingController).text,
        'tahun_selesai': (form['tahun_selesai'] as TextEditingController).text,
      };

      http.Response response;
      if (form['id'] != null && form['id'].toString().isNotEmpty) {
        response = await http.put(Uri.parse('${ApiConfig.pendidikan}/${form['id']}'), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: json.encode(body));
      } else {
        response = await http.post(Uri.parse(ApiConfig.pendidikan), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: json.encode(body));
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showValidationSuccess("Data pendidikan berhasil disimpan.");
        _fetchProfileData(); 
      }
    } catch (e) {
      _showValidationError("Terjadi kesalahan: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSingleSkill(int index) async {
    final form = _skillForms[index];
    String namaSkill = (form['nama_skill'] as TextEditingController).text;
    if (namaSkill.isEmpty) { _showValidationError("Nama skill tidak boleh kosong."); return; }
    if (form['id'] != null && form['id'].toString().isNotEmpty) { _showValidationSuccess("Skill ini sudah tersimpan."); return; }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse(ApiConfig.skill),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({'nama_skill': namaSkill}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showValidationSuccess("Keahlian baru berhasil ditambahkan.");
        _fetchProfileData();
      }
    } catch (e) {
      _showValidationError("Terjadi kesalahan: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSinglePengalaman(int index) async {
    final form = _pengalamanForms[index];
    String namaPerusahaan = (form['nama_perusahaan'] as TextEditingController).text;
    if (namaPerusahaan.isEmpty) { _showValidationError("Nama perusahaan harus diisi."); return; }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      Map<String, dynamic> body = {
        'nama_perusahaan': namaPerusahaan,
        'posisi': (form['posisi'] as TextEditingController).text,
        'tanggal_mulai': (form['tanggal_mulai'] as TextEditingController).text,
        'tanggal_selesai': (form['tanggal_selesai'] as TextEditingController).text,
        'deskripsi': (form['deskripsi'] as TextEditingController).text,
      };

      http.Response response;
      if (form['id'] != null && form['id'].toString().isNotEmpty) {
        response = await http.put(Uri.parse('${ApiConfig.pengalaman}/${form['id']}'), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: json.encode(body));
      } else {
        response = await http.post(Uri.parse(ApiConfig.pengalaman), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: json.encode(body));
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showValidationSuccess("Data pengalaman kerja berhasil disimpan.");
        _fetchProfileData();
      }
    } catch (e) {
      _showValidationError("Terjadi kesalahan: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // DIUBAH: MENYESUAIKAN CALLING METHOD SUPAYA TIDAK NESTED SETSTATE
  Future<void> _deleteItemDirectly(String type, String id, int localIndex) async {
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

      final response = await http.delete(
        Uri.parse(endpoint),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Pemanggilan method lokal langsung (karena di dalam method sudah ada setState)
        if (type == 'pendidikan') _removePendidikanForm(localIndex);
        if (type == 'skill') _removeSkillForm(localIndex);
        if (type == 'pengalaman') _removePengalamanForm(localIndex);
        
        _showValidationSuccess("Data berhasil dihapus.");
      }
    } catch (e) {
      _showValidationError("Kesalahan saat menghapus: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showConfirmDeleteDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Konfirmasi"),
            content: const Text("Hapus data ini secara permanen?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ?? false;
  }

  // Pengambilan Dokumen Tahap 1
  Future<void> _pickFile(String idJenisDokumen) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result != null) {
      final fileData = result.files.single;
      Uint8List? fileBytes = fileData.bytes;

      if (fileBytes != null) {
        setState(() {
          uploadedFiles[idJenisDokumen] = fileBytes;
          uploadedFileNames[idJenisDokumen] = fileData.name;
        });
      } else {
        _showValidationError("Gagal membaca data file.");
      }
    }
  }

  // Pengambilan Foto Pengguna Tahap 3
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageFile = pickedFile;
        _profileImageBytes = bytes;
        if (!kIsWeb) _profileImagePath = pickedFile.path;
      });
    }
  }

  // ==========================================
  // VALIDASI & LOGIKA PINDAH STEP
  // ==========================================
  bool _validasiStepLanjut() {
    if (currentStep == 1) {
      for (var doc in dokumenWajib) {
        bool isWajib = doc['wajib'] == true || doc['wajib'] == 1;
        String idDoc = doc['id_jenis_dokumen'].toString();
        if (isWajib && !uploadedFiles.containsKey(idDoc)) {
          _showValidationError("Dokumen ${doc['nama_dokumen']} wajib diunggah sebelum melanjutkan.");
          return false;
        }
      }
    } else if (currentStep == 2) {
      for (var q in pertanyaanSeleksi) {
        String idPertanyaan = (
          q['id_pertanyaan'] ??
          q['id_pertanyaan_lowongan'] ??
          q['id'] ??
          ''
        ).toString();
        if (idPertanyaan.isEmpty || idPertanyaan == 'null') continue;
        String jawaban = pertanyaanControllers[idPertanyaan]?.text.trim() ?? "";
        if (jawaban.isEmpty) {
          _showValidationError("Harap jawab semua pertanyaan dari perusahaan sebelum melanjutkan.");
          return false;
        }
      }
    } else if (currentStep == 3) {
      if (_isEditingMaster) {
        _showValidationError("Simpan perubahan Profil Utama terlebih dahulu sebelum lanjut.");
        return false;
      }
      for (var form in _pendidikanForms) {
        if (form['isEditing']) { _showValidationError("Ada data Pendidikan yang belum disimpan."); return false; }
      }
      for (var form in _skillForms) {
        if (form['isEditing']) { _showValidationError("Ada data Skill yang belum disimpan."); return false; }
      }
      for (var form in _pengalamanForms) {
        if (form['isEditing']) { _showValidationError("Ada data Pengalaman yang belum disimpan."); return false; }
      }
      
      if (_namaController.text.trim().isEmpty || _ttlController.text.trim().isEmpty || _noTelpController.text.trim().isEmpty) {
        _showValidationError("Data profil pokok belum lengkap!");
        return false;
      }
    }
    return true;
  }

  void _nextStep() {
    if (!_validasiStepLanjut()) return;

    if (currentStep < 4) {
      setState(() => currentStep++);
    } else if (currentStep == 4) {
      _submitFormFormLamaran();
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

  void _showValidationSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ========================================================
  // PROSES KIRIM LAMARAN
  // ========================================================
  Future<void> _submitFormFormLamaran() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      if (idLamaran == null) {
        _showValidationError("ID lamaran tidak valid. Coba keluar dan masuk kembali.");
        setState(() => _isLoading = false);
        return;
      }

      debugPrint("=== [Submit] Mulai pengiriman lamaran ID: $idLamaran ===");
      debugPrint("=== [Submit] Jumlah pertanyaan: ${pertanyaanSeleksi.length} ===");
      debugPrint("=== [Submit] Jumlah controller: ${pertanyaanControllers.length} ===");

      // ─── STEP 1: Unggah Berkas Dokumen Tahap 1 ────────────────────────
      // ─── STEP 1: Unggah Berkas Dokumen (satu per satu per file) ──────────
      if (uploadedFiles.isNotEmpty) {
        debugPrint("=== [Submit] Mengunggah ${uploadedFiles.length} dokumen satu per satu... ===");
        var uriDokumen = Uri.parse("${ApiConfig.baseUrl}/lamaran/$idLamaran/dokumen");

        for (var entry in uploadedFiles.entries) {
          String idDoc = entry.key;       // contoh: "1", "6", "5"
          String fileName = uploadedFileNames[idDoc] ?? "dokumen.pdf";
          String ext = fileName.split('.').last.toLowerCase();
          String mimeType = ext == 'pdf'
              ? 'application/pdf'
              : (ext == 'png' ? 'image/png' : 'image/jpeg');

          debugPrint("=== [Submit] Upload dokumen id_jenis_dokumen=$idDoc → $fileName ===");

          var docRequest = http.MultipartRequest('POST', uriDokumen);
          docRequest.headers.addAll({
            "Accept": "application/json",
            "Authorization": "Bearer $token",
          });

          // Field file: nama field = 'dokumen'
          docRequest.files.add(
            http.MultipartFile.fromBytes(
              'dokumen',
              entry.value,
              filename: fileName,
              contentType: MediaType.parse(mimeType),
            ),
          );

          // Field text: id_jenis_dokumen
          docRequest.fields['id_jenis_dokumen'] = idDoc;

          var docStreamedRes = await docRequest.send();
          var docResponse = await http.Response.fromStream(docStreamedRes);

          debugPrint("=== [Submit] Dokumen $idDoc status: ${docResponse.statusCode} ===");
          debugPrint("=== [Submit] Dokumen $idDoc body: ${docResponse.body} ===");

          if (docResponse.statusCode != 200 && docResponse.statusCode != 201) {
            String errMsg = "Gagal mengunggah dokumen '$fileName'.";
            try {
              final err = jsonDecode(docResponse.body);
              errMsg = err['message'] ?? err['error'] ?? errMsg;
            } catch (_) {}
            _showValidationError(errMsg);
            setState(() => _isLoading = false);
            return;
          }
        }
        debugPrint("=== [Submit] ✅ Semua dokumen berhasil diunggah. ===");
      } else {
        debugPrint("=== [Submit] Tidak ada dokumen untuk diunggah. ===");
      }

      // ─── STEP 2: Simpan Jawaban Kuesioner ─────────────────────────────
      List<Map<String, dynamic>> listJawaban = [];
      pertanyaanControllers.forEach((idPertanyaan, controller) {
        String jawaban = controller.text.trim();
        int? idInt = int.tryParse(idPertanyaan);
        if (idInt != null) {
          listJawaban.add({"id_pertanyaan": idInt, "jawaban": jawaban});
          debugPrint("=== [Submit] Jawaban id=$idInt: '$jawaban' ===");
        }
      });

      debugPrint("=== [Submit] Total jawaban: ${listJawaban.length} ===");

      if (listJawaban.isNotEmpty) {
        var uriJawaban = Uri.parse("${ApiConfig.baseUrl}/lamaran/$idLamaran/jawaban");
        bool jawabanBerhasil = false;

        // Format A: raw array  → body = [{"id_pertanyaan":X,"jawaban":"..."},...]
        final bodyA = jsonEncode(listJawaban);
        debugPrint("=== [Submit] Coba format A (array): $bodyA ===");
        var resA = await http.post(uriJawaban,
            headers: {"Accept": "application/json", "Content-Type": "application/json", "Authorization": "Bearer $token"},
            body: bodyA);
        debugPrint("=== [Submit] Format A status: ${resA.statusCode}, body: ${resA.body} ===");
        if (resA.statusCode == 200 || resA.statusCode == 201) jawabanBerhasil = true;

        // Format B: wrapped object  → body = {"jawaban":[...]}
        if (!jawabanBerhasil) {
          final bodyB = jsonEncode({"jawaban": listJawaban});
          debugPrint("=== [Submit] Coba format B (wrapped): $bodyB ===");
          var resB = await http.post(uriJawaban,
              headers: {"Accept": "application/json", "Content-Type": "application/json", "Authorization": "Bearer $token"},
              body: bodyB);
          debugPrint("=== [Submit] Format B status: ${resB.statusCode}, body: ${resB.body} ===");
          if (resB.statusCode == 200 || resB.statusCode == 201) jawabanBerhasil = true;
        }

        // Format C: kirim satu per satu sebagai POST individual
        if (!jawabanBerhasil) {
          debugPrint("=== [Submit] Coba format C (satu per satu)... ===");
          bool semuaBerhasil = true;
          for (var item in listJawaban) {
            final bodyItem = jsonEncode(item);
            var resItem = await http.post(uriJawaban,
                headers: {"Accept": "application/json", "Content-Type": "application/json", "Authorization": "Bearer $token"},
                body: bodyItem);
            debugPrint("=== [Submit] Item id=${item['id_pertanyaan']} status: ${resItem.statusCode}, body: ${resItem.body} ===");
            if (resItem.statusCode != 200 && resItem.statusCode != 201) {
              semuaBerhasil = false;
              String errMsg = "Gagal menyimpan jawaban.";
              try { errMsg = jsonDecode(resItem.body)['message'] ?? errMsg; } catch (_) {}
              _showValidationError(errMsg);
              setState(() => _isLoading = false);
              return;
            }
          }
          if (semuaBerhasil) jawabanBerhasil = true;
        }

        if (!jawabanBerhasil) {
          _showValidationError("Gagal menyimpan jawaban seleksi. Coba lagi.");
          setState(() => _isLoading = false);
          return;
        }
        debugPrint("=== [Submit] ✅ Jawaban berhasil disimpan. ===");
      } else {
        debugPrint("=== [Submit] Tidak ada pertanyaan, skip jawaban. ===");
      }

      // ─── STEP 3: Finalisasi / Kirim Lamaran ───────────────────────────
      debugPrint("=== [Submit] Finalisasi lamaran... ===");
      var uriKirim = Uri.parse("${ApiConfig.baseUrl}/lamaran/$idLamaran/kirim");
      var responseKirim = await http.post(
        uriKirim,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("=== [Submit] Kirim status: ${responseKirim.statusCode} ===");
      debugPrint("=== [Submit] Kirim body: ${responseKirim.body} ===");

      if (responseKirim.statusCode == 200 || responseKirim.statusCode == 201) {
        setState(() => currentStep = 5);
        _animationController.forward();
        debugPrint("=== [Submit] ✅ Lamaran berhasil dikirim! ===");
      } else {
        String errMsg = "Gagal menyelesaikan pengiriman lamaran.";
        try {
          final errorData = jsonDecode(responseKirim.body);
          errMsg = errorData['message'] ?? errorData['error'] ?? errMsg;
        } catch (_) {}
        _showValidationError(errMsg);
      }
    } catch (e, stackTrace) {
      debugPrint("=== [Submit] ERROR: $e ===");
      debugPrint("=== [Submit] StackTrace: $stackTrace ===");
      _showValidationError("Terjadi kesalahan: ${e.toString().replaceAll('Exception:', '').trim()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // BUILD RENDER WIDGET (MAINTAIN ORIGINAL DESIGN)
  // ==========================================
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
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFF0B85E)))
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
    if (dokumenWajib.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text("Tidak ada dokumen persyaratan khusus.", style: TextStyle(color: Colors.grey))),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text("Silakan lengkapi dokumen persyaratan di bawah ini untuk memulai perjalanan kariermu.", style: TextStyle(fontSize: 14, color: AppColors.textMain, height: 1.5)),
        const SizedBox(height: 25),
        ...dokumenWajib.map((doc) {
          String idDoc = doc['id_jenis_dokumen'].toString();
          bool isWajib = doc['wajib'] == true || doc['wajib'] == 1;
          String labelWajib = isWajib ? " (Wajib)" : " (Opsional)";
          return _buildUploadCard(
            Icons.description_rounded,
            "${doc['nama_dokumen']}$labelWajib",
            uploadedFileNames[idDoc] ?? "Ketuk untuk memilih berkas",
            () => _pickFile(idDoc),
            isUploaded: uploadedFiles.containsKey(idDoc),
          );
        }),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildStep2Pertanyaan() {
    if (pertanyaanSeleksi.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            "Tidak ada pertanyaan seleksi khusus.\nSilakan klik Lanjut.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          "Silakan jawab pertanyaan pada lowongan ini untuk membantu perusahaan mengenal potensi Anda lebih dalam.",
          style: TextStyle(fontSize: 14, color: AppColors.textMain, height: 1.5),
        ),
        const SizedBox(height: 25),
        ...pertanyaanSeleksi.asMap().entries.map((entry) {
          int nomor = entry.key + 1;
          var q = entry.value;

          // Ambil ID pertanyaan — coba semua kemungkinan nama field
          String idPertanyaan = (
            q['id_pertanyaan'] ??
            q['id_pertanyaan_lowongan'] ??
            q['id'] ??
            ''
          ).toString();

          // Ambil teks pertanyaan — coba semua kemungkinan nama field
          String teksPertanyaan = (
            q['pertanyaan'] ??
            q['pertanyaan_text'] ??
            q['teks_pertanyaan'] ??
            q['text'] ??
            q['question'] ??
            'Pertanyaan $nomor'
          ).toString();

          // Pastikan controller tersedia; buat jika belum ada (fallback safety)
          if (idPertanyaan.isNotEmpty && idPertanyaan != 'null' &&
              !pertanyaanControllers.containsKey(idPertanyaan)) {
            pertanyaanControllers[idPertanyaan] = TextEditingController();
          }

          TextEditingController? controller = idPertanyaan.isNotEmpty && idPertanyaan != 'null'
              ? pertanyaanControllers[idPertanyaan]
              : null;

          return _buildInputField(
            "$nomor. $teksPertanyaan",
            "Tulis jawaban Anda di sini...",
            isTextArea: true,
            controller: controller,
          );
        }),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildStep3Profile() {
    ImageProvider profileImageProvider = const NetworkImage('https://via.placeholder.com/150');
    if (kIsWeb && _profileImageBytes != null) profileImageProvider = MemoryImage(_profileImageBytes!);
    else if (!kIsWeb && _profileImagePath != null) profileImageProvider = FileImage(io.File(_profileImagePath!));
    else if (_networkProfileImageUrl != null && _networkProfileImageUrl!.isNotEmpty) profileImageProvider = NetworkImage(_networkProfileImageUrl!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Center(
          child: Stack(
            children: [
              CircleAvatar(radius: 50, backgroundColor: Colors.grey.shade300, backgroundImage: profileImageProvider),
              if (_isEditingMaster)
                Positioned(
                  bottom: 0, right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Color(0xFFF0B85E), shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        
        // --- MASTER PROFIL HEADER ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("IDENTITAS PRIBADI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            if (!_isEditingMaster)
              IconButton(icon: const Icon(Icons.edit_note_rounded, color: Color(0xFFF0B85E)), onPressed: () => setState(() => _isEditingMaster = true)),
          ],
        ),
        const Divider(),
        const SizedBox(height: 8),

        // --- MASTER PROFIL FORM ---
        _buildInputField("Nama Lengkap", "Masukkan nama lengkap", controller: _namaController, readOnly: !_isEditingMaster),
        GestureDetector(
          onTap: _isEditingMaster ? () => _selectDate(context, _ttlController) : null,
          child: AbsorbPointer(child: _buildDateField("Tanggal Lahir", "YYYY-MM-DD", controller: _ttlController, readOnly: !_isEditingMaster)),
        ),
        
        const Text("Jenis Kelamin", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF422E26))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: !_isEditingMaster ? Colors.grey[100] : const Color(0xFFF9F7F2), borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _jenisKelamin,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: !_isEditingMaster ? Colors.transparent : Colors.grey),
              onChanged: _isEditingMaster ? (String? newValue) { if (newValue != null) setState(() => _jenisKelamin = newValue); } : null,
              items: <String>['Laki-laki', 'Perempuan'].map<DropdownMenuItem<String>>((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
            ),
          ),
        ),
        const SizedBox(height: 15),

        _buildInputField("Nomor Telepon", "Masukkan nomor telepon aktif", controller: _noTelpController, keyboardType: TextInputType.phone, readOnly: !_isEditingMaster),
        _buildInputField("Alamat", "Jl. Contoh No 08", isTextArea: true, controller: _alamatController, readOnly: !_isEditingMaster),
        _buildInputField("Tentang Saya", "Tulis deskripsi mengenai diri...", isTextArea: true, controller: _tentangSayaController, readOnly: !_isEditingMaster),
        
        if (_isEditingMaster)
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () { setState(() => _isEditingMaster = false); _fetchProfileData(); }, style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF422E26)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text("Batal", style: TextStyle(color: Color(0xFF422E26))))),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(onPressed: _updateMasterProfile, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF422E26), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text("Simpan", style: TextStyle(color: Colors.white)))),
            ],
          ),

        const SizedBox(height: 25),
        const Text("KUALIFIKASI & RIWAYAT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        const Divider(),

        // --- PENDIDIKAN LIST ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("PENDIDIKAN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF422E26))),
            TextButton(onPressed: () => _addPendidikanForm(), child: const Text("+ Tambah", style: TextStyle(color: Color(0xFFF0B85E), fontStyle: FontStyle.normal, fontWeight: FontWeight.bold))),
          ],
        ),
        ..._pendidikanForms.asMap().entries.map((entry) {
          int index = entry.key; var form = entry.value;
          bool isEditing = form['isEditing']; bool isSaved = form['id'] != null;
          return Container(
            margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Riwayat #${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                    Row(
                      children: [
                        if (!isEditing) IconButton(icon: const Icon(Icons.edit_note_rounded, color: Color(0xFFF0B85E)), onPressed: () => setState(() => form['isEditing'] = true)),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => isSaved ? _deleteItemDirectly('pendidikan', form['id'].toString(), index) : _removePendidikanForm(index)),
                      ],
                    ),
                  ],
                ),
                _buildInputField("NAMA INSTITUSI", "Cth: Universitas X", controller: form['institusi'], readOnly: !isEditing),
                _buildInputField("JURUSAN", "Cth: Sistem Informasi", controller: form['jurusan'], readOnly: !isEditing),
                _buildInputField("TINGKAT", "Cth: S1", controller: form['tingkat'], readOnly: !isEditing),
                Row(
                  children: [
                    Expanded(child: GestureDetector(onTap: isEditing ? () => _selectDate(context, form['tahun_mulai']) : null, child: AbsorbPointer(child: _buildDateField("TAHUN MULAI", "YYYY-MM-DD", controller: form['tahun_mulai'], readOnly: !isEditing)))),
                    const SizedBox(width: 10),
                    Expanded(child: GestureDetector(onTap: isEditing ? () => _selectDate(context, form['tahun_selesai']) : null, child: AbsorbPointer(child: _buildDateField("TAHUN SELESAI", "YYYY-MM-DD", controller: form['tahun_selesai'], readOnly: !isEditing)))),
                  ],
                ),
                if (isEditing)
                  Align(alignment: Alignment.centerRight, child: ElevatedButton(onPressed: () => _saveSinglePendidikan(index), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF422E26), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text("Simpan Perubahan", style: TextStyle(color: Colors.white, fontSize: 12)))),
              ],
            ),
          );
        }),

        // --- SKILL LIST ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("KEAHLIAN / SKILL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF422E26))),
            TextButton(onPressed: () => _addSkillForm(), child: const Text("+ Tambah", style: TextStyle(color: Color(0xFFF0B85E), fontWeight: FontWeight.bold))),
          ],
        ),
        ..._skillForms.asMap().entries.map((entry) {
          int index = entry.key; var form = entry.value;
          bool isEditing = form['isEditing']; bool isSaved = form['id'] != null;
          return Container(
            margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildInputField("NAMA SKILL", "Cth: Keterampilan pelayanan", controller: form['nama_skill'], readOnly: !isEditing)),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => isSaved ? _deleteItemDirectly('skill', form['id'].toString(), index) : _removeSkillForm(index)),
                  ],
                ),
                if (isEditing && !isSaved)
                  Align(alignment: Alignment.centerRight, child: ElevatedButton(onPressed: () => _saveSingleSkill(index), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF422E26), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text("Simpan", style: TextStyle(color: Colors.white, fontSize: 12)))),
              ],
            ),
          );
        }),

        // --- PENGALAMAN KERJA LIST ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("PENGALAMAN KERJA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF422E26))),
            TextButton(onPressed: () => _addPengalamanForm(), child: const Text("+ Tambah", style: TextStyle(color: Color(0xFFF0B85E), fontWeight: FontWeight.bold))),
          ],
        ),
        ..._pengalamanForms.asMap().entries.map((entry) {
          int index = entry.key; var form = entry.value;
          bool isEditing = form['isEditing']; bool isSaved = form['id'] != null;
          return Container(
            margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Pengalaman #${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                    Row(
                      children: [
                        if (!isEditing) IconButton(icon: const Icon(Icons.edit_note_rounded, color: Color(0xFFF0B85E)), onPressed: () => setState(() => form['isEditing'] = true)),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => isSaved ? _deleteItemDirectly('pengalaman', form['id'].toString(), index) : _removePengalamanForm(index)),
                      ],
                    ),
                  ],
                ),
                _buildInputField("NAMA PERUSAHAAN", "Cth: PT Makmur", controller: form['nama_perusahaan'], readOnly: !isEditing),
                _buildInputField("POSISI / JABATAN", "Cth: Staff IT", controller: form['posisi'], readOnly: !isEditing),
                Row(
                  children: [
                    Expanded(child: GestureDetector(onTap: isEditing ? () => _selectDate(context, form['tanggal_mulai']) : null, child: AbsorbPointer(child: _buildDateField("TAHUN MULAI", "YYYY-MM-DD", controller: form['tanggal_mulai'], readOnly: !isEditing)))),
                    const SizedBox(width: 10),
                    Expanded(child: GestureDetector(onTap: isEditing ? () => _selectDate(context, form['tanggal_selesai']) : null, child: AbsorbPointer(child: _buildDateField("TAHUN SELESAI", "YYYY-MM-DD", controller: form['tanggal_selesai'], readOnly: !isEditing)))),
                  ],
                ),
                _buildInputField("DESKRIPSI PEKERJAAN", "Jelaskan peran kerja Anda", controller: form['deskripsi'], isTextArea: true, readOnly: !isEditing),
                if (isEditing)
                  Align(alignment: Alignment.centerRight, child: ElevatedButton(onPressed: () => _saveSinglePengalaman(index), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF422E26), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text("Simpan Perubahan", style: TextStyle(color: Colors.white, fontSize: 12)))),
              ],
            ),
          );
        }),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildStep4Review() {
    ImageProvider reviewImageProvider = const AssetImage('assets/images/placeholder_avatar.png');
    try {
      if (kIsWeb && _profileImageBytes != null) {
        reviewImageProvider = MemoryImage(_profileImageBytes!);
      } else if (!kIsWeb && _profileImagePath != null) {
        reviewImageProvider = FileImage(io.File(_profileImagePath!));
      } else if (_networkProfileImageUrl != null && _networkProfileImageUrl!.isNotEmpty) {
        reviewImageProvider = NetworkImage(_networkProfileImageUrl!);
      }
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8EC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF0B85E).withOpacity(0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFFF0B85E), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Periksa kembali seluruh data lamaran Anda sebelum dikirim. Setelah dikirim, data tidak dapat diubah.",
                  style: const TextStyle(fontSize: 12, color: Color(0xFF7A5C2E), height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ─── SEKSI: PROFIL PELAMAR ────────────────────────────────────────
        _buildReviewSectionHeader("Profil Pelamar", Icons.person_rounded, onEdit: () => setState(() => currentStep = 3)),
        const SizedBox(height: 12),

        // Foto & Info Utama
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _reviewCardDecoration(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: reviewImageProvider,
                    onBackgroundImageError: (_, __) {},
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: GestureDetector(
                      onTap: () => setState(() => currentStep = 3),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0B85E),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(Icons.edit_rounded, size: 13, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _namaController.text.isNotEmpty ? _namaController.text : "-",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2B1810)),
                    ),
                    const SizedBox(height: 6),
                    _reviewInfoRow(Icons.cake_rounded, "Tanggal Lahir", _ttlController.text),
                    _reviewInfoRow(Icons.wc_rounded, "Jenis Kelamin", _jenisKelamin),
                    _reviewInfoRow(Icons.phone_rounded, "No. Telepon", _noTelpController.text),
                    _reviewInfoRow(Icons.location_on_rounded, "Alamat", _alamatController.text),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tentang Saya
        if (_tentangSayaController.text.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: _reviewCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.format_quote_rounded, size: 16, color: Color(0xFFF0B85E)),
                  const SizedBox(width: 6),
                  const Text("Tentang Saya", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF422E26))),
                ]),
                const SizedBox(height: 8),
                Text(_tentangSayaController.text, style: const TextStyle(fontSize: 13, color: Color(0xFF6B6B6B), height: 1.5)),
              ],
            ),
          ),
        ],

        // Pendidikan
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: _reviewCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.school_rounded, size: 16, color: Color(0xFFF0B85E)),
                const SizedBox(width: 6),
                const Text("Pendidikan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF422E26))),
                const Spacer(),
                Text("${_pendidikanForms.length} Data", style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
              if (_pendidikanForms.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text("Belum ada data pendidikan", style: TextStyle(color: Colors.grey, fontSize: 12)),
                )
              else ...[
                const SizedBox(height: 10),
                ..._pendidikanForms.asMap().entries.map((e) {
                  var f = e.value;
                  String inst = (f['institusi'] as TextEditingController).text;
                  String jur  = (f['jurusan'] as TextEditingController).text;
                  String tkt  = (f['tingkat'] as TextEditingController).text;
                  String tMul = (f['tahun_mulai'] as TextEditingController).text;
                  String tSel = (f['tahun_selesai'] as TextEditingController).text;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7F3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(inst.isNotEmpty ? inst : "-", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          if (jur.isNotEmpty) Text(jur, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                          if (tkt.isNotEmpty) Text(tkt, style: const TextStyle(fontSize: 12, color: Color(0xFFF0B85E), fontWeight: FontWeight.w600)),
                          if (tMul.isNotEmpty || tSel.isNotEmpty)
                            Text("${tMul.isNotEmpty ? tMul : '?'} — ${tSel.isNotEmpty ? tSel : 'Sekarang'}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),

        // Keahlian
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: _reviewCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF0B85E)),
                const SizedBox(width: 6),
                const Text("Keahlian / Skill", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF422E26))),
                const Spacer(),
                Text("${_skillForms.length} Skill", style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
              if (_skillForms.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text("Belum ada data keahlian", style: TextStyle(color: Colors.grey, fontSize: 12)),
                )
              else ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _skillForms.map((f) {
                    String nama = (f['nama_skill'] as TextEditingController).text;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0B85E).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF0B85E).withOpacity(0.4)),
                      ),
                      child: Text(nama.isNotEmpty ? nama : "-", style: const TextStyle(fontSize: 12, color: Color(0xFF6B4F31), fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),

        // Pengalaman Kerja
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: _reviewCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.work_rounded, size: 16, color: Color(0xFFF0B85E)),
                const SizedBox(width: 6),
                const Text("Pengalaman Kerja", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF422E26))),
                const Spacer(),
                Text("${_pengalamanForms.length} Data", style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
              if (_pengalamanForms.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text("Belum ada data pengalaman", style: TextStyle(color: Colors.grey, fontSize: 12)),
                )
              else ...[
                const SizedBox(height: 10),
                ..._pengalamanForms.asMap().entries.map((e) {
                  var f = e.value;
                  String perusahaan = (f['nama_perusahaan'] as TextEditingController).text;
                  String posisi     = (f['posisi'] as TextEditingController).text;
                  String tMul       = (f['tanggal_mulai'] as TextEditingController).text;
                  String tSel       = (f['tanggal_selesai'] as TextEditingController).text;
                  String desk       = (f['deskripsi'] as TextEditingController).text;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7F3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(perusahaan.isNotEmpty ? perusahaan : "-", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 2),
                          if (posisi.isNotEmpty) Text(posisi, style: const TextStyle(fontSize: 12, color: Color(0xFFF0B85E), fontWeight: FontWeight.w600)),
                          if (tMul.isNotEmpty || tSel.isNotEmpty)
                            Text("${tMul.isNotEmpty ? tMul : '?'} — ${tSel.isNotEmpty ? tSel : 'Sekarang'}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          if (desk.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(desk, style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4)),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ─── SEKSI: TANGGAPAN PERTANYAAN ─────────────────────────────────
        _buildReviewSectionHeader("Tanggapan Pertanyaan Seleksi", Icons.quiz_rounded),
        const SizedBox(height: 12),
        if (pertanyaanSeleksi.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: _reviewCardDecoration(),
            child: const Row(children: [
              Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
              SizedBox(width: 8),
              Text("Tidak ada pertanyaan khusus dari perusahaan.", style: TextStyle(color: Colors.grey, fontSize: 13)),
            ]),
          )
        else
          ...pertanyaanSeleksi.asMap().entries.map((entry) {
            int nomor = entry.key + 1;
            var q = entry.value;
            String idPertanyaan = (q['id_pertanyaan'] ?? q['id_pertanyaan_lowongan'] ?? q['id'] ?? '').toString();
            String teksPertanyaan = (q['pertanyaan'] ?? q['pertanyaan_text'] ?? q['teks_pertanyaan'] ?? 'Pertanyaan $nomor').toString();
            String jawaban = pertanyaanControllers[idPertanyaan]?.text ?? "-";
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: _reviewCardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 22, height: 22,
                        decoration: const BoxDecoration(color: Color(0xFFF0B85E), shape: BoxShape.circle),
                        child: Center(child: Text("$nomor", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(teksPertanyaan, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2B1810)))),
                    ]),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F4EE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(jawaban.isNotEmpty ? jawaban : "-", style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 13, height: 1.4)),
                    ),
                  ],
                ),
              ),
            );
          }),

        const SizedBox(height: 24),

        // ─── SEKSI: DOKUMEN ───────────────────────────────────────────────
        _buildReviewSectionHeader("Dokumen Terlampir", Icons.folder_rounded),
        const SizedBox(height: 12),
        Container(
          decoration: _reviewCardDecoration(),
          child: dokumenWajib.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text("Tidak ada dokumen persyaratan.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                )
              : Column(
                  children: dokumenWajib.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var doc = entry.value;
                    String idDoc = doc['id_jenis_dokumen'].toString();
                    bool isWajib = doc['wajib'] == true || doc['wajib'] == 1;
                    String fileName = uploadedFileNames[idDoc] ?? "";
                    bool uploaded = fileName.isNotEmpty;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 38, height: 38,
                                decoration: BoxDecoration(
                                  color: uploaded ? Colors.green.shade50 : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  uploaded ? Icons.insert_drive_file_rounded : Icons.upload_file_rounded,
                                  color: uploaded ? Colors.green : Colors.red.shade300,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Text(doc['nama_dokumen'] ?? "Berkas", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2B1810))),
                                      if (isWajib) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                                          child: const Text("Wajib", style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ]),
                                    const SizedBox(height: 2),
                                    Text(
                                      uploaded ? fileName : "Belum diunggah",
                                      style: TextStyle(fontSize: 11, color: uploaded ? Colors.grey : Colors.red.shade300),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                uploaded ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                                color: uploaded ? Colors.green : Colors.red.shade300,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                        if (idx < dokumenWajib.length - 1)
                          Divider(height: 1, color: Colors.grey.shade100),
                      ],
                    );
                  }).toList(),
                ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  // Helper: decoration untuk review card
  BoxDecoration _reviewCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFEDE8E2)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
    );
  }

  // Helper: section header untuk review
  Widget _buildReviewSectionHeader(String title, IconData icon, {VoidCallback? onEdit}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFF0B85E).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFFF0B85E)),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF422E26))),
        const Spacer(),
        if (onEdit != null)
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF0B85E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF0B85E).withOpacity(0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.edit_rounded, size: 13, color: Color(0xFFF0B85E)),
                SizedBox(width: 4),
                Text("Edit", style: TextStyle(fontSize: 11, color: Color(0xFFF0B85E), fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
      ],
    );
  }

  // Helper: info row dalam review profil
  Widget _reviewInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: const Color(0xFFF0B85E)),
          const SizedBox(width: 5),
          Text("$label: ", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Expanded(child: Text(value.isNotEmpty ? value : "-", style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildUploadCard(IconData icon, String title, String subtitle, VoidCallback onTap, {bool isUploaded = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7F2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isUploaded ? Colors.green.shade300 : Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 30, color: const Color(0xFFB8860B)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(backgroundColor: isUploaded ? Colors.green : const Color(0xFFF0B85E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 16)),
            child: Text(isUploaded ? "Ganti" : "Pilih", style: const TextStyle(fontSize: 12, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, String hint, {bool isTextArea = false, TextEditingController? controller, TextInputType keyboardType = TextInputType.text, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF422E26))),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          maxLines: isTextArea ? 4 : 1,
          keyboardType: keyboardType,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: readOnly ? Colors.grey[100] : const Color(0xFFF9F7F2),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildDateField(String label, String hint, {TextEditingController? controller, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF422E26))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: readOnly ? Colors.grey[100] : const Color(0xFFF9F7F2),
            suffixIcon: Icon(Icons.calendar_month_rounded, color: readOnly ? Colors.grey : const Color(0xFF6B4F31)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Text(answer.isEmpty ? "-" : answer, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildFileReviewItem(String fileName, String label) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file, color: Color(0xFFF0B85E), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(fileName, style: const TextStyle(color: Colors.grey, fontSize: 11), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Icon(fileName == "Belum diunggah" ? Icons.error_outline : Icons.check_circle, color: fileName == "Belum diunggah" ? Colors.red : Colors.green, size: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          IconButton(onPressed: _prevStep, icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF6B4F31))),
          Expanded(child: Text(widget.jobTitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6B4F31)))),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 16, 30, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepIndicator(1, "Dokumen"), _stepLine(1),
          _stepIndicator(2, "Pertanyaan"), _stepLine(2),
          _stepIndicator(3, "Profile"), _stepLine(3),
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
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: isActive || isCompleted ? const Color(0xFFF0B85E) : const Color(0xFFE8E4DF),
            shape: BoxShape.circle,
            boxShadow: isActive ? [BoxShadow(color: const Color(0xFFF0B85E).withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))] : [],
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : Text("$n", style: TextStyle(color: isActive ? Colors.white : const Color(0xFFADA9A4), fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 10, color: isActive ? const Color(0xFFF0B85E) : Colors.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _stepLine(int n) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Container(height: 2, color: currentStep > n ? const Color(0xFFF0B85E) : const Color(0xFFE0E0E0)),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(child: OutlinedButton(onPressed: _prevStep, style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF6B4F31)), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text("Kembali", style: TextStyle(color: Color(0xFF6B4F31))))),
          const SizedBox(width: 15),
          Expanded(child: ElevatedButton(onPressed: _nextStep, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF0B85E), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: Text(currentStep == 4 ? "Kirim" : "Lanjut", style: const TextStyle(color: Colors.white)))),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF422E26),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ─── Animasi Pesawat → Ceklis ─────────────────────────
                SizedBox(
                  width: 160,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Lingkaran luar (halo)
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 160, height: 160,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0B85E).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Lingkaran tengah
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 120, height: 120,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF0B85E),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Icon pesawat terbang
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          // Fase 1 (0.0–0.55): pesawat muncul dengan scale
                          // Fase 2 (0.55–1.0): pesawat terbang ke kanan atas & ceklis muncul
                          double progress = _animationController.value;
                          bool showPlane = progress < 0.75;
                          bool showCheck = progress >= 0.65;

                          double planeOpacity = progress < 0.55 
                              ? progress / 0.55 
                              : (progress < 0.75 ? 1.0 : 0.0);
                          
                          double planeDx = progress < 0.55 ? 0.0 : ((progress - 0.55) / 0.20) * 80;
                          double planeDy = progress < 0.55 ? 0.0 : -((progress - 0.55) / 0.20) * 60;
                          double planeScale = progress < 0.4 ? progress / 0.4 : 1.0;

                          double checkOpacity = progress < 0.65 ? 0.0 : ((progress - 0.65) / 0.35).clamp(0.0, 1.0);
                          double checkScale = progress < 0.65 ? 0.0 : ((progress - 0.65) / 0.35).clamp(0.0, 1.0);

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Pesawat
                              if (showPlane)
                                Transform.translate(
                                  offset: Offset(planeDx, planeDy),
                                  child: Transform.scale(
                                    scale: planeScale,
                                    child: Opacity(
                                      opacity: planeOpacity.clamp(0.0, 1.0),
                                      child: const Icon(Icons.send_rounded, size: 52, color: Colors.white),
                                    ),
                                  ),
                                ),
                              // Ceklis
                              if (showCheck)
                                Transform.scale(
                                  scale: checkScale,
                                  child: Opacity(
                                    opacity: checkOpacity,
                                    child: const Icon(Icons.check_rounded, size: 58, color: Colors.white),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // Teks utama
                const Text(
                  "Lamaran Terkirim!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Berkas lamaran Anda telah berhasil dikirimkan. Tim rekrutmen akan meninjau kualifikasi Anda dan menghubungi Anda jika terpilih.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 40),

                // Tombol Lihat Status Lamaran
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/status-lamaran',
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF0B85E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_turned_in_rounded, size: 18),
                        SizedBox(width: 8),
                        Text("Lihat Status Lamaran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Tombol Kembali ke Beranda
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/beranda',
                        (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home_rounded, size: 18),
                        SizedBox(width: 8),
                        Text("Kembali ke Beranda", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}