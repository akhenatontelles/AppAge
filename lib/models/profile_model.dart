import 'package:intl/intl.dart';

class Visit {
  final int id;
  final String dataVisita;
  final String descricao;

  Visit({required this.id, required this.dataVisita, required this.descricao});

  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      id: json['id'],
      dataVisita: json['data_visita'],
      descricao: json['descricao'],
    );
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }
}

class Profile {
  final int id;
  final String nome;
  final String username;
  final String userType;
  final List<Visit> visitas;

  Profile({
    required this.id,
    required this.nome,
    required this.username,
    required this.userType,
    required this.visitas,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    var list = json['visitas'] as List? ?? [];
    List<Visit> visitasList = list.map((i) => Visit.fromJson(i)).toList();

    return Profile(
      id: json['id'],
      nome: json['nome'],
      username: json['username'],
      userType: json['user_type'],
      visitas: visitasList,
    );
  }
}
