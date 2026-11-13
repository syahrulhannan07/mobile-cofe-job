import 'package:flutter/material.dart';

import '../../../controllers/apply_job_controller.dart';
import '../apply_job_avatar.dart';
import '../apply_job_colors.dart';
import '../apply_job_form_fields.dart';

class ApplyProfileStep extends StatelessWidget {
  final ApplyJobController controller;

  const ApplyProfileStep({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Center(
          child: Stack(
            children: [
              ApplyJobAvatar(
                radius: 50,
                name: controller.namaController.text,
                imageProvider: controller.profileImageProvider,
              ),
              if (controller.isEditingMaster)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: controller.pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: applyGold,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'IDENTITAS PRIBADI',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            if (!controller.isEditingMaster)
              IconButton(
                icon: const Icon(
                  Icons.edit_note_rounded,
                  color: applyGold,
                ),
                onPressed: () => controller.setMasterEditing(true),
              ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 8),
        ApplyInputField(
          label: 'Nama Lengkap',
          hint: 'Masukkan nama lengkap',
          controller: controller.namaController,
          readOnly: !controller.isEditingMaster,
        ),
        GestureDetector(
          onTap: controller.isEditingMaster
              ? () => controller.selectDate(
                    context,
                    controller.ttlController,
                  )
              : null,
          child: AbsorbPointer(
            child: ApplyDateField(
              label: 'Tanggal Lahir',
              hint: 'YYYY-MM-DD',
              controller: controller.ttlController,
              readOnly: !controller.isEditingMaster,
            ),
          ),
        ),
        const Text(
          'Jenis Kelamin',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: applyBrown,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: !controller.isEditingMaster
                ? Colors.grey[100]
                : applyFieldBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.jenisKelamin,
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down,
                color: !controller.isEditingMaster
                    ? Colors.transparent
                    : Colors.grey,
              ),
              onChanged: controller.isEditingMaster
                  ? (value) {
                      if (value != null) controller.setGender(value);
                    }
                  : null,
              items: <String>['Laki-laki', 'Perempuan']
                  .map<DropdownMenuItem<String>>(
                    (value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 15),
        ApplyInputField(
          label: 'Nomor Telepon',
          hint: 'Masukkan nomor telepon aktif',
          controller: controller.noTelpController,
          keyboardType: TextInputType.phone,
          readOnly: !controller.isEditingMaster,
        ),
        ApplyInputField(
          label: 'Alamat',
          hint: 'Jl. Contoh No 08',
          isTextArea: true,
          controller: controller.alamatController,
          readOnly: !controller.isEditingMaster,
        ),
        ApplyInputField(
          label: 'Tentang Saya',
          hint: 'Tulis deskripsi mengenai diri...',
          isTextArea: true,
          controller: controller.tentangSayaController,
          readOnly: !controller.isEditingMaster,
        ),
        if (controller.isEditingMaster)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.cancelMasterEditing,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: applyBrown),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: applyBrown),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: controller.updateMasterProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: applyBrown,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Simpan',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 25),
        const Text(
          'KUALIFIKASI & RIWAYAT',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PENDIDIKAN',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: applyBrown,
              ),
            ),
            TextButton(
              onPressed: controller.addPendidikanForm,
              child: const Text(
                '+ Tambah',
                style: TextStyle(
                  color: applyGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        ...controller.pendidikanForms.asMap().entries.map((entry) {
          final index = entry.key;
          final form = entry.value;
          final isEditing = form['isEditing'] == true;
          final isSaved = form['id'] != null;

          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Riwayat #${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Row(
                      children: [
                        if (!isEditing)
                          IconButton(
                            icon: const Icon(
                              Icons.edit_note_rounded,
                              color: applyGold,
                            ),
                            onPressed: () =>
                                controller.setEducationEditing(
                              index,
                              true,
                            ),
                          ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => isSaved
                              ? _confirmDelete(
                                  context,
                                  controller,
                                  type: 'pendidikan',
                                  id: form['id'].toString(),
                                  index: index,
                                )
                              : controller.removePendidikanForm(index),
                        ),
                      ],
                    ),
                  ],
                ),
                ApplyInputField(
                  label: 'NAMA INSTITUSI',
                  hint: 'Cth: Universitas X',
                  controller:
                      form['institusi'] as TextEditingController,
                  readOnly: !isEditing,
                ),
                ApplyInputField(
                  label: 'JURUSAN',
                  hint: 'Cth: Sistem Informasi',
                  controller: form['jurusan'] as TextEditingController,
                  readOnly: !isEditing,
                ),
                ApplyInputField(
                  label: 'TINGKAT',
                  hint: 'Cth: S1',
                  controller: form['tingkat'] as TextEditingController,
                  readOnly: !isEditing,
                ),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: isEditing
                            ? () => controller.selectDate(
                                  context,
                                  form['tahun_mulai']
                                      as TextEditingController,
                                )
                            : null,
                        child: AbsorbPointer(
                          child: ApplyDateField(
                            label: 'TAHUN MULAI',
                            hint: 'YYYY-MM-DD',
                            controller: form['tahun_mulai']
                                as TextEditingController,
                            readOnly: !isEditing,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: isEditing
                            ? () => controller.selectDate(
                                  context,
                                  form['tahun_selesai']
                                      as TextEditingController,
                                )
                            : null,
                        child: AbsorbPointer(
                          child: ApplyDateField(
                            label: 'TAHUN SELESAI',
                            hint: 'YYYY-MM-DD',
                            controller: form['tahun_selesai']
                                as TextEditingController,
                            readOnly: !isEditing,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (isEditing)
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () =>
                          controller.saveSinglePendidikan(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: applyBrown,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'KEAHLIAN / SKILL',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: applyBrown,
              ),
            ),
            TextButton(
              onPressed: controller.addSkillForm,
              child: const Text(
                '+ Tambah',
                style: TextStyle(
                  color: applyGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        ...controller.skillForms.asMap().entries.map((entry) {
          final index = entry.key;
          final form = entry.value;
          final isEditing = form['isEditing'] == true;
          final isSaved = form['id'] != null;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ApplyInputField(
                        label: 'NAMA SKILL',
                        hint: 'Cth: Keterampilan pelayanan',
                        controller:
                            form['nama_skill'] as TextEditingController,
                        readOnly: !isEditing,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => isSaved
                          ? _confirmDelete(
                              context,
                              controller,
                              type: 'skill',
                              id: form['id'].toString(),
                              index: index,
                            )
                          : controller.removeSkillForm(index),
                    ),
                  ],
                ),
                if (isEditing && !isSaved)
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () =>
                          controller.saveSingleSkill(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: applyBrown,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Simpan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PENGALAMAN KERJA',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: applyBrown,
              ),
            ),
            TextButton(
              onPressed: controller.addPengalamanForm,
              child: const Text(
                '+ Tambah',
                style: TextStyle(
                  color: applyGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        ...controller.pengalamanForms.asMap().entries.map((entry) {
          final index = entry.key;
          final form = entry.value;
          final isEditing = form['isEditing'] == true;
          final isSaved = form['id'] != null;

          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pengalaman #${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Row(
                      children: [
                        if (!isEditing)
                          IconButton(
                            icon: const Icon(
                              Icons.edit_note_rounded,
                              color: applyGold,
                            ),
                            onPressed: () =>
                                controller.setExperienceEditing(
                              index,
                              true,
                            ),
                          ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => isSaved
                              ? _confirmDelete(
                                  context,
                                  controller,
                                  type: 'pengalaman',
                                  id: form['id'].toString(),
                                  index: index,
                                )
                              : controller.removePengalamanForm(index),
                        ),
                      ],
                    ),
                  ],
                ),
                ApplyInputField(
                  label: 'NAMA PERUSAHAAN',
                  hint: 'Cth: PT Makmur',
                  controller:
                      form['nama_perusahaan'] as TextEditingController,
                  readOnly: !isEditing,
                ),
                ApplyInputField(
                  label: 'POSISI / JABATAN',
                  hint: 'Cth: Staff IT',
                  controller: form['posisi'] as TextEditingController,
                  readOnly: !isEditing,
                ),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: isEditing
                            ? () => controller.selectDate(
                                  context,
                                  form['tanggal_mulai']
                                      as TextEditingController,
                                )
                            : null,
                        child: AbsorbPointer(
                          child: ApplyDateField(
                            label: 'TAHUN MULAI',
                            hint: 'YYYY-MM-DD',
                            controller: form['tanggal_mulai']
                                as TextEditingController,
                            readOnly: !isEditing,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: isEditing
                            ? () => controller.selectDate(
                                  context,
                                  form['tanggal_selesai']
                                      as TextEditingController,
                                )
                            : null,
                        child: AbsorbPointer(
                          child: ApplyDateField(
                            label: 'TAHUN SELESAI',
                            hint: 'YYYY-MM-DD',
                            controller: form['tanggal_selesai']
                                as TextEditingController,
                            readOnly: !isEditing,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                ApplyInputField(
                  label: 'DESKRIPSI PEKERJAAN',
                  hint: 'Jelaskan peran kerja Anda',
                  controller: form['deskripsi'] as TextEditingController,
                  isTextArea: true,
                  readOnly: !isEditing,
                ),
                if (isEditing)
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () =>
                          controller.saveSinglePengalaman(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: applyBrown,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
        const SizedBox(height: 30),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ApplyJobController controller, {
    required String type,
    required String id,
    required int index,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Hapus data ini secara permanen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.deleteProfileItem(
        type: type,
        id: id,
        localIndex: index,
      );
    }
  }
}
