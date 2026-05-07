class JobModel {
  final int id;
  final String title;

  JobModel({required this.id, required this.title});

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(id: json['id'], title: json['nama_pekerjaan']);
  }
}
