class TokenModel {
  final String? token;
  final String? nome;

  TokenModel({this.token, this.nome});

  // Método factory para criar o TokenModel a partir de um JSON
  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      token: json['token']?.toString(),
      nome: json['nome']?.toString(),
    );
  }
}
