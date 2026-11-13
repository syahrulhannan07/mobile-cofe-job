import 'dart:io' as io;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/storage_url.dart';
import '../services/job_application_service.dart';
import '../utils/apply_job_utils.dart';

typedef ApplyJobMessageCallback = void Function(
  String message, {
  bool isError,
});

class ApplyJobController extends ChangeNotifier {
  final String jobId;
  final String jobTitle;
  final ApplyJobMessageCallback? onMessage;

  ApplyJobController({
    required this.jobId,
    required this.jobTitle,
    this.onMessage,
  });

  int currentStep = 1;
  bool isLoading = false;
  bool isEditingMaster = false;
  bool faceVerified = false;
  bool lamaranTerkirim = false;

  String? idLamaran;
  List<dynamic> dokumenWajib = [];
  List<dynamic> pertanyaanSeleksi = [];

  final Map<String, Uint8List> uploadedFiles = {};
  final Map<String, String> uploadedFileNames = {};
  final Set<String> uploadedDokumenIds = {};

  final Map<String, TextEditingController> pertanyaanControllers = {};

  XFile? imageFile;
  Uint8List? profileImageBytes;
  String? profileImagePath;
  String? networkProfileImageUrl;

  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController namaController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController ttlController = TextEditingController();
  final TextEditingController noTelpController = TextEditingController();
  final TextEditingController alamatController = TextEditingController();
  final TextEditingController tentangSayaController =
      TextEditingController();

  String jenisKelamin = 'Laki-laki';

  final List<Map<String, dynamic>> pendidikanForms = [];
  final List<Map<String, dynamic>> skillForms = [];
  final List<Map<String, dynamic>> pengalamanForms = [];

  bool _disposed = false;

  ImageProvider? get profileImageProvider {
    if (kIsWeb && profileImageBytes != null) {
      return MemoryImage(profileImageBytes!);
    }
    if (!kIsWeb && profileImagePath != null) {
      return FileImage(io.File(profileImagePath!));
    }
    if (networkProfileImageUrl != null &&
        networkProfileImageUrl!.isNotEmpty) {
      return NetworkImage(networkProfileImageUrl!);
    }
    return null;
  }

  Future<bool> initialize() async {
    isLoading = true;
    _notify();

    try {
      final result = await JobApplicationService.startApplication(jobId);
      if (_disposed) return false;

      idLamaran = result.idLamaran;
      dokumenWajib = result.documents;

      try {
        pertanyaanSeleksi =
            await JobApplicationService.fetchSelectionQuestions(jobId);
        if (_disposed) return false;
        _prepareQuestionControllers();
      } on ApiException catch (error) {
        debugPrint('Gagal memuat pertanyaan seleksi: $error');
      } catch (error) {
        debugPrint('Gagal memuat pertanyaan seleksi: $error');
      }

      await fetchProfileData();
      return true;
    } on ApiException catch (error) {
      _showError(error.message);
      return false;
    } catch (error) {
      debugPrint('Gagal inisialisasi lamaran: $error');
      _showError('Terjadi kesalahan sinkronisasi data server.');
      return false;
    } finally {
      isLoading = false;
      _notify();
    }
  }

  void _prepareQuestionControllers() {
    for (final controller in pertanyaanControllers.values) {
      controller.dispose();
    }
    pertanyaanControllers.clear();

    for (final question in pertanyaanSeleksi) {
      final id = questionIdOf(question);
      if (id.isNotEmpty && id != 'null') {
        pertanyaanControllers[id] = TextEditingController();
      }
    }
  }

  Future<void> fetchProfileData() async {
    if (_disposed) return;

    try {
      final profile = await JobApplicationService.fetchProfile();
      if (_disposed) return;

      namaController.text = profile['nama_lengkap']?.toString() ?? '';
      emailController.text = profile['email']?.toString() ?? '';
      ttlController.text = profile['tanggal_lahir']?.toString() ?? '';

      final gender = profile['jenis_kelamin']
              ?.toString()
              .trim()
              .toLowerCase() ??
          '';
      if (gender == 'l' ||
          gender == 'laki-laki' ||
          gender == 'laki_laki') {
        jenisKelamin = 'Laki-laki';
      } else if (gender == 'p' || gender == 'perempuan') {
        jenisKelamin = 'Perempuan';
      }

      noTelpController.text =
          profile['nomor_telepon']?.toString() ?? '';
      alamatController.text = profile['alamat']?.toString() ?? '';
      tentangSayaController.text =
          profile['tentang_saya']?.toString() ?? '';

      final rawPhotoUrl = profile['foto_profil']?.toString() ?? '';
      networkProfileImageUrl = rawPhotoUrl.trim().isEmpty
          ? null
          : buildStorageUrl(rawPhotoUrl);

      _clearDynamicControllers();
      pendidikanForms.clear();
      skillForms.clear();
      pengalamanForms.clear();

      final education = profile['pendidikan'];
      if (education is List) {
        for (final item in education) {
          if (item is! Map) continue;
          pendidikanForms.add(
            _educationForm(
              id: (item['id'] ??
                      item['id_pendidikan'] ??
                      item['id_riwayat_pendidikan'])
                  ?.toString(),
              institusi: item['institusi']?.toString() ??
                  item['nama_instansi']?.toString() ??
                  '',
              jurusan: item['jurusan']?.toString() ?? '',
              tingkat: item['tingkat']?.toString() ?? '',
              tahunMulai: _dateOnly(item['tahun_mulai']),
              tahunSelesai: _dateOnly(item['tahun_selesai']),
              isEditing: false,
            ),
          );
        }
      }

      final skills = profile['skills'] ?? profile['skill'];
      if (skills is List) {
        for (final item in skills) {
          if (item is! Map) continue;
          skillForms.add(
            _skillForm(
              id: (item['id'] ??
                      item['id_skill'] ??
                      item['id_keahlian'])
                  ?.toString(),
              namaSkill:
                  (item['nama_skill'] ?? item['skill'] ?? '').toString(),
              isEditing: false,
            ),
          );
        }
      }

      final experiences = profile['pengalaman_kerja'];
      if (experiences is List) {
        for (final item in experiences) {
          if (item is! Map) continue;
          pengalamanForms.add(
            _experienceForm(
              id: (item['id'] ??
                      item['id_pengalaman'] ??
                      item['id_pengalaman_kerja'])
                  ?.toString(),
              namaPerusahaan:
                  item['nama_perusahaan']?.toString() ?? '',
              posisi: item['posisi']?.toString() ?? '',
              tanggalMulai: _dateOnly(item['tanggal_mulai']),
              tanggalSelesai: _dateOnly(item['tanggal_selesai']),
              deskripsi: item['deskripsi']?.toString() ?? '',
              isEditing: false,
            ),
          );
        }
      }

      _notify();
    } catch (error) {
      debugPrint('Error memuat profil: $error');
    }
  }

  String _dateOnly(dynamic value) {
    if (value == null) return '';
    return value.toString().split('T').first;
  }

  Map<String, dynamic> _educationForm({
    String? id,
    String institusi = '',
    String jurusan = '',
    String tingkat = '',
    String tahunMulai = '',
    String tahunSelesai = '',
    bool isEditing = true,
  }) {
    return {
      'id': id,
      'institusi': TextEditingController(text: institusi),
      'jurusan': TextEditingController(text: jurusan),
      'tingkat': TextEditingController(text: tingkat),
      'tahun_mulai': TextEditingController(text: tahunMulai),
      'tahun_selesai': TextEditingController(text: tahunSelesai),
      'isEditing': isEditing,
    };
  }

  Map<String, dynamic> _skillForm({
    String? id,
    String namaSkill = '',
    bool isEditing = true,
  }) {
    return {
      'id': id,
      'nama_skill': TextEditingController(text: namaSkill),
      'isEditing': isEditing,
    };
  }

  Map<String, dynamic> _experienceForm({
    String? id,
    String namaPerusahaan = '',
    String posisi = '',
    String tanggalMulai = '',
    String tanggalSelesai = '',
    String deskripsi = '',
    bool isEditing = true,
  }) {
    return {
      'id': id,
      'nama_perusahaan': TextEditingController(text: namaPerusahaan),
      'posisi': TextEditingController(text: posisi),
      'tanggal_mulai': TextEditingController(text: tanggalMulai),
      'tanggal_selesai': TextEditingController(text: tanggalSelesai),
      'deskripsi': TextEditingController(text: deskripsi),
      'isEditing': isEditing,
    };
  }

  void addPendidikanForm({
    String? id,
    String institusi = '',
    String jurusan = '',
    String tingkat = '',
    String tahunMulai = '',
    String tahunSelesai = '',
    bool isEditing = true,
  }) {
    pendidikanForms.add(
      _educationForm(
        id: id,
        institusi: institusi,
        jurusan: jurusan,
        tingkat: tingkat,
        tahunMulai: tahunMulai,
        tahunSelesai: tahunSelesai,
        isEditing: isEditing,
      ),
    );
    _notify();
  }

  void removePendidikanForm(int index) {
    if (index < 0 || index >= pendidikanForms.length) return;
    final form = pendidikanForms.removeAt(index);
    _disposeEducationForm(form);
    _notify();
  }

  void addSkillForm({
    String? id,
    String namaSkill = '',
    bool isEditing = true,
  }) {
    skillForms.add(
      _skillForm(
        id: id,
        namaSkill: namaSkill,
        isEditing: isEditing,
      ),
    );
    _notify();
  }

  void removeSkillForm(int index) {
    if (index < 0 || index >= skillForms.length) return;
    final form = skillForms.removeAt(index);
    _disposeSkillForm(form);
    _notify();
  }

  void addPengalamanForm({
    String? id,
    String namaPerusahaan = '',
    String posisi = '',
    String tanggalMulai = '',
    String tanggalSelesai = '',
    String deskripsi = '',
    bool isEditing = true,
  }) {
    pengalamanForms.add(
      _experienceForm(
        id: id,
        namaPerusahaan: namaPerusahaan,
        posisi: posisi,
        tanggalMulai: tanggalMulai,
        tanggalSelesai: tanggalSelesai,
        deskripsi: deskripsi,
        isEditing: isEditing,
      ),
    );
    _notify();
  }

  void removePengalamanForm(int index) {
    if (index < 0 || index >= pengalamanForms.length) return;
    final form = pengalamanForms.removeAt(index);
    _disposeExperienceForm(form);
    _notify();
  }

  void _disposeEducationForm(Map<String, dynamic> form) {
    form['institusi']?.dispose();
    form['jurusan']?.dispose();
    form['tingkat']?.dispose();
    form['tahun_mulai']?.dispose();
    form['tahun_selesai']?.dispose();
  }

  void _disposeSkillForm(Map<String, dynamic> form) {
    form['nama_skill']?.dispose();
  }

  void _disposeExperienceForm(Map<String, dynamic> form) {
    form['nama_perusahaan']?.dispose();
    form['posisi']?.dispose();
    form['tanggal_mulai']?.dispose();
    form['tanggal_selesai']?.dispose();
    form['deskripsi']?.dispose();
  }

  void _clearDynamicControllers() {
    for (final form in pendidikanForms) {
      _disposeEducationForm(form);
    }
    for (final form in skillForms) {
      _disposeSkillForm(form);
    }
    for (final form in pengalamanForms) {
      _disposeExperienceForm(form);
    }
  }

  Future<void> selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    var initialDate = DateTime.now();

    try {
      if (controller.text.isNotEmpty) {
        initialDate = DateFormat('yyyy-MM-dd').parse(controller.text);
      }
    } catch (_) {}

    final picked = await showDatePicker(
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

    if (picked != null && !_disposed) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
      _notify();
    }
  }

  void setMasterEditing(bool value) {
    isEditingMaster = value;
    _notify();
  }

  void setGender(String value) {
    jenisKelamin = value;
    _notify();
  }

  void cancelMasterEditing() {
    isEditingMaster = false;
    _notify();
    fetchProfileData();
  }

  void setEducationEditing(int index, bool value) {
    if (index < 0 || index >= pendidikanForms.length) return;
    pendidikanForms[index]['isEditing'] = value;
    _notify();
  }

  void setExperienceEditing(int index, bool value) {
    if (index < 0 || index >= pengalamanForms.length) return;
    pengalamanForms[index]['isEditing'] = value;
    _notify();
  }

  void setFaceVerified(bool value) {
    faceVerified = value;
    _notify();
  }

  void handleFaceResult({
    required bool success,
    required String message,
  }) {
    faceVerified = success;
    if (success) {
      _showSuccess(
        message.isEmpty ? 'Verifikasi wajah berhasil.' : message,
      );
    } else {
      _showError(
        message.isEmpty
            ? 'Verifikasi wajah belum berhasil. Silakan coba lagi.'
            : message,
      );
    }
    _notify();
  }

  Future<void> updateMasterProfile() async {
    isLoading = true;
    _notify();

    try {
      await JobApplicationService.updateMasterProfile(
        fields: {
          'nama_lengkap': namaController.text,
          'tanggal_lahir': ttlController.text,
          'jenis_kelamin': jenisKelamin,
          'nomor_telepon': noTelpController.text,
          'alamat': alamatController.text,
          'tentang_saya': tentangSayaController.text,
        },
        photoBytes: profileImageBytes,
        photoFileName: imageFile?.name,
      );
      if (_disposed) return;

      isEditingMaster = false;
      _showSuccess('Profil utama berhasil disimpan.');
      await fetchProfileData();
    } on ApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('Terjadi kesalahan: $error');
    } finally {
      isLoading = false;
      _notify();
    }
  }

  Future<void> saveSinglePendidikan(int index) async {
    if (index < 0 || index >= pendidikanForms.length) return;

    final form = pendidikanForms[index];
    final institusi =
        (form['institusi'] as TextEditingController).text.trim();

    if (institusi.isEmpty) {
      _showError('Nama Institusi harus diisi.');
      return;
    }

    isLoading = true;
    _notify();

    try {
      await JobApplicationService.saveEducation(
        id: form['id']?.toString(),
        body: {
          'institusi': institusi,
          'jurusan': (form['jurusan'] as TextEditingController).text,
          'tingkat': (form['tingkat'] as TextEditingController).text,
          'tahun_mulai':
              (form['tahun_mulai'] as TextEditingController).text,
          'tahun_selesai':
              (form['tahun_selesai'] as TextEditingController).text,
        },
      );
      if (_disposed) return;

      _showSuccess('Data pendidikan berhasil disimpan.');
      await fetchProfileData();
    } on ApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('Terjadi kesalahan: $error');
    } finally {
      isLoading = false;
      _notify();
    }
  }

  Future<void> saveSingleSkill(int index) async {
    if (index < 0 || index >= skillForms.length) return;

    final form = skillForms[index];
    final namaSkill =
        (form['nama_skill'] as TextEditingController).text.trim();

    if (namaSkill.isEmpty) {
      _showError('Nama skill tidak boleh kosong.');
      return;
    }

    if (form['id'] != null && form['id'].toString().isNotEmpty) {
      _showSuccess('Skill ini sudah tersimpan.');
      return;
    }

    isLoading = true;
    _notify();

    try {
      await JobApplicationService.saveSkill(
        body: {'nama_skill': namaSkill},
      );
      if (_disposed) return;

      _showSuccess('Keahlian baru berhasil ditambahkan.');
      await fetchProfileData();
    } on ApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('Terjadi kesalahan: $error');
    } finally {
      isLoading = false;
      _notify();
    }
  }

  Future<void> saveSinglePengalaman(int index) async {
    if (index < 0 || index >= pengalamanForms.length) return;

    final form = pengalamanForms[index];
    final namaPerusahaan =
        (form['nama_perusahaan'] as TextEditingController).text.trim();

    if (namaPerusahaan.isEmpty) {
      _showError('Nama perusahaan harus diisi.');
      return;
    }

    isLoading = true;
    _notify();

    try {
      await JobApplicationService.saveExperience(
        id: form['id']?.toString(),
        body: {
          'nama_perusahaan': namaPerusahaan,
          'posisi': (form['posisi'] as TextEditingController).text,
          'tanggal_mulai':
              (form['tanggal_mulai'] as TextEditingController).text,
          'tanggal_selesai':
              (form['tanggal_selesai'] as TextEditingController).text,
          'deskripsi':
              (form['deskripsi'] as TextEditingController).text,
        },
      );
      if (_disposed) return;

      _showSuccess('Data pengalaman kerja berhasil disimpan.');
      await fetchProfileData();
    } on ApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('Terjadi kesalahan: $error');
    } finally {
      isLoading = false;
      _notify();
    }
  }

  Future<void> deleteProfileItem({
    required String type,
    required String id,
    required int localIndex,
  }) async {
    isLoading = true;
    _notify();

    try {
      await JobApplicationService.deleteProfileItem(
        type: type,
        id: id,
      );
      if (_disposed) return;

      switch (type) {
        case 'pendidikan':
          if (localIndex >= 0 && localIndex < pendidikanForms.length) {
            _disposeEducationForm(pendidikanForms.removeAt(localIndex));
          }
          break;
        case 'skill':
          if (localIndex >= 0 && localIndex < skillForms.length) {
            _disposeSkillForm(skillForms.removeAt(localIndex));
          }
          break;
        case 'pengalaman':
          if (localIndex >= 0 &&
              localIndex < pengalamanForms.length) {
            _disposeExperienceForm(
              pengalamanForms.removeAt(localIndex),
            );
          }
          break;
      }

      _showSuccess('Data berhasil dihapus.');
    } on ApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('Kesalahan saat menghapus: $error');
    } finally {
      isLoading = false;
      _notify();
    }
  }

  Future<void> pickFile(String idJenisDokumen) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result == null || _disposed) return;

    final fileData = result.files.single;
    final bytes = fileData.bytes;

    if (bytes == null) {
      _showError('Gagal membaca data file.');
      return;
    }

    if (idLamaran == null) {
      _showError(
        'ID lamaran belum siap. Tunggu sebentar dan coba lagi.',
      );
      return;
    }

    uploadedFiles[idJenisDokumen] = bytes;
    uploadedFileNames[idJenisDokumen] = fileData.name;
    uploadedDokumenIds.remove(idJenisDokumen);

    isLoading = true;
    _notify();

    try {
      await JobApplicationService.uploadDocument(
        idLamaran: idLamaran!,
        idJenisDokumen: idJenisDokumen,
        bytes: bytes,
        fileName: fileData.name,
      );
      if (_disposed) return;

      uploadedDokumenIds.add(idJenisDokumen);
      _showSuccess('Dokumen berhasil diunggah.');
    } on ApiException catch (error) {
      uploadedFiles.remove(idJenisDokumen);
      uploadedFileNames.remove(idJenisDokumen);
      _showError(error.message);
    } catch (error) {
      uploadedFiles.remove(idJenisDokumen);
      uploadedFileNames.remove(idJenisDokumen);
      _showError('Terjadi kesalahan saat mengunggah: $error');
    } finally {
      isLoading = false;
      _notify();
    }
  }

  Future<void> pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked == null || _disposed) return;

    final bytes = await picked.readAsBytes();
    if (_disposed) return;

    imageFile = picked;
    profileImageBytes = bytes;
    if (!kIsWeb) profileImagePath = picked.path;
    _notify();
  }

  bool validateNextStep() {
    if (currentStep == 1) {
      for (final document in dokumenWajib) {
        final id = documentIdOf(document);
        if (isDocumentRequired(document) &&
            !uploadedDokumenIds.contains(id)) {
          _showError(
            'Dokumen ${documentNameOf(document)} wajib diunggah dan harus berhasil tersimpan sebelum melanjutkan.',
          );
          return false;
        }
      }
    } else if (currentStep == 2) {
      for (final question in pertanyaanSeleksi) {
        final id = questionIdOf(question);
        if (id.isEmpty || id == 'null') continue;

        final answer =
            pertanyaanControllers[id]?.text.trim() ?? '';
        if (answer.isEmpty) {
          _showError(
            'Harap jawab semua pertanyaan dari perusahaan sebelum melanjutkan.',
          );
          return false;
        }
      }
    } else if (currentStep == 3) {
      if (isEditingMaster) {
        _showError(
          'Simpan perubahan Profil Utama terlebih dahulu sebelum lanjut.',
        );
        return false;
      }
      for (final form in pendidikanForms) {
        if (form['isEditing'] == true) {
          _showError('Ada data Pendidikan yang belum disimpan.');
          return false;
        }
      }
      for (final form in skillForms) {
        if (form['isEditing'] == true) {
          _showError('Ada data Skill yang belum disimpan.');
          return false;
        }
      }
      for (final form in pengalamanForms) {
        if (form['isEditing'] == true) {
          _showError('Ada data Pengalaman yang belum disimpan.');
          return false;
        }
      }

      if (namaController.text.trim().isEmpty ||
          ttlController.text.trim().isEmpty ||
          noTelpController.text.trim().isEmpty) {
        _showError('Data profil pokok belum lengkap!');
        return false;
      }
    }

    return true;
  }

  void nextStep() {
    if (!validateNextStep()) return;
    if (currentStep >= 5) return;

    currentStep++;
    _notify();
  }

  void previousStep() {
    if (currentStep <= 1) return;

    if (currentStep == 5) {
      faceVerified = false;
    }
    currentStep--;
    _notify();
  }

  void goToStep(int step) {
    if (step < 1 || step > 5) return;
    currentStep = step;
    _notify();
  }

  Future<void> submitApplication() async {
    isLoading = true;
    _notify();

    try {
      if (idLamaran == null) {
        _showError(
          'ID lamaran tidak valid. Coba keluar dan masuk kembali.',
        );
        return;
      }

      final answers = <Map<String, dynamic>>[];
      pertanyaanControllers.forEach((id, controller) {
        final parsedId = int.tryParse(id);
        if (parsedId != null) {
          answers.add({
            'id_pertanyaan': parsedId,
            'jawaban': controller.text.trim(),
          });
        }
      });

      await JobApplicationService.submitAnswers(
        idLamaran: idLamaran!,
        answers: answers,
      );
      await JobApplicationService.submitApplication(idLamaran!);
      if (_disposed) return;

      lamaranTerkirim = true;
    } on ApiException catch (error) {
      faceVerified = false;
      _showError(error.message);
    } catch (error) {
      faceVerified = false;
      _showError(
        'Terjadi kesalahan: ${error.toString().replaceAll('Exception:', '').trim()}',
      );
    } finally {
      isLoading = false;
      _notify();
    }
  }

  void _showSuccess(String message) {
    onMessage?.call(message, isError: false);
  }

  void _showError(String message) {
    onMessage?.call(message, isError: true);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final controller in pertanyaanControllers.values) {
      controller.dispose();
    }
    pertanyaanControllers.clear();
    namaController.dispose();
    emailController.dispose();
    ttlController.dispose();
    noTelpController.dispose();
    alamatController.dispose();
    tentangSayaController.dispose();
    _clearDynamicControllers();
    super.dispose();
  }
}
