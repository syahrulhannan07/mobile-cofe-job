String questionIdOf(dynamic question) {
  if (question is Map) {
    final rawId = question['id_pertanyaan'] ??
        question['id_pertanyaan_lowongan'] ??
        question['id'] ??
        '';
    return rawId.toString();
  }

  return '';
}

String questionTextOf(dynamic question, int number) {
  if (question is Map) {
    final rawText = question['pertanyaan'] ??
        question['pertanyaan_text'] ??
        question['teks_pertanyaan'] ??
        question['text'] ??
        question['question'];

    if (rawText != null && rawText.toString().trim().isNotEmpty) {
      return rawText.toString();
    }
  }

  return 'Pertanyaan $number';
}

String documentIdOf(dynamic document) {
  if (document is Map) {
    return document['id_jenis_dokumen']?.toString() ?? '';
  }

  return '';
}

String documentNameOf(dynamic document) {
  if (document is Map) {
    return document['nama_dokumen']?.toString() ?? 'Berkas';
  }

  return 'Berkas';
}

bool isDocumentRequired(dynamic document) {
  if (document is! Map) return false;
  return document['wajib'] == true || document['wajib'] == 1;
}
