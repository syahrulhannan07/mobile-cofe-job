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

  // Mapping Jawaban Tahap 2: { id_pertanyaan: TextEditingController }
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

      // 2. Fetch Detail Lowongan
      final resDetail = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/lowongan/${widget.jobId}/detail"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (resDetail.statusCode == 200) {
        final resData = jsonDecode(resDetail.body);
        if (resData['status'] == 'success' && resData['data'] != null) {
          var dataLowongan = resData['data'];
          
          if (dataLowongan['pertanyaan_lowongan'] is List) {
            pertanyaanSeleksi = dataLowongan['pertanyaan_lowongan'];
          } else if (dataLowongan['lowongan'] != null && dataLowongan['lowongan']['pertanyaan_lowongan'] is List) {
            pertanyaanSeleksi = dataLowongan['lowongan']['pertanyaan_lowongan'];
          } else if (dataLowongan['pertanyaan_seleksi'] is List) {
            pertanyaanSeleksi = dataLowongan['pertanyaan_seleksi'];
          } else if (dataLowongan['lowongan'] != null && dataLowongan['lowongan']['pertanyaan_seleksi'] is List) {
            pertanyaanSeleksi = dataLowongan['lowongan']['pertanyaan_seleksi'];
          }

          pertanyaanControllers.clear();
          for (var p in pertanyaanSeleksi) {
            String idPertanyaan = (p['id_pertanyaan'] ?? p['id_pertanyaan_lowongan'] ?? p['id'] ?? '').toString();
            if (idPertanyaan.isNotEmpty) {
              pertanyaanControllers[idPertanyaan] = TextEditingController();
            }
          }
        }
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
        _showValidationError("Profil utama berhasil disimpan.");
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
        _showValidationError("Data pendidikan berhasil disimpan.");
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
    if (form['id'] != null && form['id'].toString().isNotEmpty) { _showValidationError("Skill ini sudah tersimpan."); return; }

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
        _showValidationError("Keahlian baru berhasil ditambahkan.");
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
        _showValidationError("Data pengalaman kerja berhasil disimpan.");
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
        
        _showValidationError("Data berhasil dihapus.");
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
        String idPertanyaan = (q['id_pertanyaan'] ?? q['id_pertanyaan_lowongan'] ?? q['id'] ?? '').toString();
        if (idPertanyaan.isEmpty) continue;
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
        _showValidationError("ID lamaran tidak valid.");
        setState(() => _isLoading = false);
        return;
      }

      // STEP 1: Simpan Jawaban Kuesioner
      List<Map<String, dynamic>> listJawaban = [];
      pertanyaanControllers.forEach((idPertanyaan, controller) {
        listJawaban.add({
          "id_pertanyaan": int.parse(idPertanyaan),
          "jawaban": controller.text,
        });
      });

      if (listJawaban.isNotEmpty) {
        var uriJawaban = Uri.parse("${ApiConfig.baseUrl}/lamaran/$idLamaran/jawaban");
        var responseJawaban = await http.post(
          uriJawaban,
          headers: {"Accept": "application/json", "Content-Type": "application/json", "Authorization": "Bearer $token"},
          body: jsonEncode(listJawaban),
        );

        if (responseJawaban.statusCode != 200 && responseJawaban.statusCode != 201) {
          final err = jsonDecode(responseJawaban.body);
          _showValidationError(err['message'] ?? "Gagal menyimpan jawaban seleksi.");
          setState(() => _isLoading = false);
          return;
        }
      }

      // STEP 2: Unggah Berkas Dokumen Tahap 1
      if (uploadedFiles.isNotEmpty) {
        var uriDokumen = Uri.parse("${ApiConfig.baseUrl}/lamaran/$idLamaran/dokumen");
        var docRequest = http.MultipartRequest('POST', uriDokumen);
        docRequest.headers.addAll({"Accept": "application/json", "Authorization": "Bearer $token"});

        for (var entry in uploadedFiles.entries) {
          String fileName = uploadedFileNames[entry.key] ?? "dokumen.pdf";
          docRequest.files.add(
            http.MultipartFile.fromBytes('dokumen_${entry.key}', entry.value, filename: fileName),
          );
        }

        var docStreamedRes = await docRequest.send();
        var docResponse = await http.Response.fromStream(docStreamedRes);

        if (docResponse.statusCode != 200 && docResponse.statusCode != 201) {
          final err = jsonDecode(docResponse.body);
          _showValidationError(err['message'] ?? "Gagal mengunggah file dokumen berkas.");
          setState(() => _isLoading = false);
          return;
        }
      }

      // STEP 3: Finalisasi / Kirim Lamaran
      var uriKirim = Uri.parse("${ApiConfig.baseUrl}/lamaran/$idLamaran/kirim");
      var responseKirim = await http.post(
        uriKirim,
        headers: {"Accept": "application/json", "Authorization": "Bearer $token"},
      );

      if (responseKirim.statusCode == 200 || responseKirim.statusCode == 201) {
        setState(() => currentStep = 5);
        _animationController.forward();
      } else {
        final errorData = jsonDecode(responseKirim.body);
        _showValidationError(errorData['message'] ?? "Gagal menyelesaikan pengiriman berkas lamaran.");
      }
    } catch (e) {
      _showValidationError("Terjadi kesalahan sistem atau jaringan internet: $e");
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
        child: Center(child: Text("Tidak ada pertanyaan seleksi khusus. Silakan klik Lanjut.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text("Silakan jawab pertanyaan pada lowongan ini untuk membantu perusahaan mengenal potensi Anda lebih dalam.", style: TextStyle(fontSize: 14, color: AppColors.textMain, height: 1.5)),
        const SizedBox(height: 25),
        ...pertanyaanSeleksi.map((q) {
          String idPertanyaan = (q['id_pertanyaan'] ?? q['id_pertanyaan_lowongan'] ?? q['id'] ?? '').toString();
          String teksPertanyaan = q['pertanyaan'] ?? q['pertanyaan_text'] ?? "Pertanyaan Seleksi";
          return _buildInputField(teksPertanyaan, "Tulis jawaban Anda di sini...", isTextArea: true, controller: pertanyaanControllers[idPertanyaan]);
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
    ImageProvider reviewImageProvider = const NetworkImage('https://via.placeholder.com/150');
    if (kIsWeb && _profileImageBytes != null) reviewImageProvider = MemoryImage(_profileImageBytes!);
    else if (!kIsWeb && _profileImagePath != null) reviewImageProvider = FileImage(io.File(_profileImagePath!));
    else if (_networkProfileImageUrl != null && _networkProfileImageUrl!.isNotEmpty) reviewImageProvider = NetworkImage(_networkProfileImageUrl!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text("Harap periksa kembali ringkasan seluruh kelengkapan data lamaran Anda sebelum dikirim.", style: TextStyle(fontSize: 14, color: AppColors.textMain, height: 1.5)),
        const SizedBox(height: 25),
        const Text("Profil Pelamar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF422E26))),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 30, backgroundImage: reviewImageProvider),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_namaController.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 6),
                    Text("TTL: ${_ttlController.text}", style: const TextStyle(color: Colors.black87, fontSize: 12)),
                    Text("Gender: $_jenisKelamin", style: const TextStyle(color: Colors.black87, fontSize: 12)),
                    Text("Telp: ${_noTelpController.text}", style: const TextStyle(color: Colors.black87, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        _buildReviewCard("Riwayat Pendidikan", "${_pendidikanForms.length} Data Tersimpan"),
        _buildReviewCard("Keahlian / Skill", "${_skillForms.length} Data Tersimpan"),
        _buildReviewCard("Pengalaman Kerja", "${_pengalamanForms.length} Data Tersimpan"),
        
        const SizedBox(height: 20),
        const Text("Tanggapan Pertanyaan Seleksi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF422E26))),
        const SizedBox(height: 10),
        if (pertanyaanSeleksi.isEmpty)
          const Text("Tidak ada pertanyaan khusus dari perusahaan.", style: TextStyle(color: Colors.grey, fontSize: 13))
        else
          ...pertanyaanSeleksi.map((q) {
            String idPertanyaan = (q['id_pertanyaan'] ?? q['id_pertanyaan_lowongan'] ?? q['id'] ?? '').toString();
            return _buildReviewCard(q['pertanyaan'] ?? q['pertanyaan_text'] ?? "Pertanyaan", pertanyaanControllers[idPertanyaan]?.text ?? "-");
          }),
        const SizedBox(height: 20),
        const Text("Dokumen Terlampir", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF422E26))),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            children: dokumenWajib.map((doc) {
              String idDoc = doc['id_jenis_dokumen'].toString();
              String name = uploadedFileNames[idDoc] ?? "Belum diunggah";
              return _buildFileReviewItem(name, doc['nama_dokumen'] ?? "Berkas");
            }).toList(),
          ),
        ),
        const SizedBox(height: 30),
      ],
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
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      child: Row(
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
          width: 35, height: 35,
          decoration: BoxDecoration(color: isActive || isCompleted ? const Color(0xFFF0B85E) : const Color(0xFFE0E0E0), shape: BoxShape.circle),
          child: Center(child: Text("$n", style: TextStyle(color: isActive || isCompleted ? Colors.white : Colors.grey, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _stepLine(int n) {
    return Expanded(child: Container(height: 2, color: currentStep > n ? const Color(0xFFF0B85E) : const Color(0xFFE0E0E0), margin: const EdgeInsets.only(bottom: 15)));
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 140, height: 140,
                decoration: const BoxDecoration(color: Color(0xFFF0B85E), shape: BoxShape.circle),
                child: SlideTransition(position: _flyAnimation, child: const Icon(Icons.send_rounded, size: 60, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 30),
            const Text("Lamaran Terkirim", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (idLamaran != null) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => TrackingTimelineScreen(lamaranId: int.parse(idLamaran!))));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFDF2E2), foregroundColor: const Color(0xFF422E26), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text("Selesai & Lihat Status", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}