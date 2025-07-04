class Semeadura {
  final String tipo;
  final String data;
  final String atividade;
  final int quantidade;
  final String especie;
  final String local;
  final String arquivo; // Pode ser usado para armazenar a imagem ou documento

  Semeadura({
    required this.tipo,
    required this.data,
    required this.atividade,
    required this.quantidade,
    required this.especie,
    required this.local,
    required this.arquivo,
  });

  factory Semeadura.fromJson(Map<String, dynamic> json) {
    return Semeadura(
      tipo: json['tipo'],
      data: json['data'],
      atividade: json['atividade'],
      quantidade: json['quantidade'],
      especie: json['especie'],
      local: json['local'],
      arquivo: json['arquivo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      'data': data,
      'atividade': atividade,
      'quantidade': quantidade,
      'especie': especie,
      'local': local,
      'arquivo': arquivo,
    };
  }
}
