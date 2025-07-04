class Upload {
  final String filePath;
  final String fileType;
  final String legenda;
  final DateTime uploadDatetime;

  Upload({
    required this.filePath,
    required this.fileType,
    required this.legenda,
    required this.uploadDatetime,
  });

  factory Upload.fromJson(Map<String, dynamic> json) {
    return Upload(
      filePath: json['file_path'],
      fileType: json['file_type'],
      legenda: json['legenda'] ?? 'Sem legenda',
      uploadDatetime: DateTime.parse(json['upload_datetime']),
    );
  }
}
