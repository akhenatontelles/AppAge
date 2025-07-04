class Digitalizado {
  final int id;
  final String nomeArquivo;
  final String imagem;

  Digitalizado({
    required this.id,
    required this.nomeArquivo,
    required this.imagem,
  });

  factory Digitalizado.fromJson(Map<String, dynamic> json) {
    return Digitalizado(
      id: json['id'],
      nomeArquivo: json['nome_arquivo'],
      imagem: json['imagem'],
    );
  }

  map(Digitalizado Function(dynamic json) param0) {}
}
