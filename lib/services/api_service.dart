import 'dart:convert';
import 'dart:io';
import 'package:api_login/models/semeadura_model.dart';
import 'package:http/http.dart' as http;
import '../models/token_model.dart';
import '../models/profile_model.dart';
import '../models/visit_model.dart';
import '../models/message_model.dart';
import '../models/digitalizados_model.dart'; // Importar o modelo Digitalizado // Importar o modelo Digitalizado

class ApiService {
  final String baseUrl;

  ApiService(this.baseUrl);

  // Método para login
  Future<TokenModel?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      print('Resposta da API: ${response.body}');
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      // Verifique se o JSON contém os dados esperados antes de tentar extrair os valores
      if (jsonResponse.containsKey('token') && jsonResponse['token'] != null) {
        return TokenModel.fromJson(jsonResponse);
      } else {
        throw Exception('Token ausente ou inválido na resposta da API');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Credenciais inválidas: senha incorreta');
    } else if (response.statusCode == 404) {
      throw Exception('Usuário não encontrado');
    } else if (response.statusCode == 400) {
      throw Exception('Username e senha são obrigatórios');
    } else {
      throw Exception('Falha ao fazer login. Código: ${response.statusCode}');
    }
  }

  // Método para buscar perfil
  Future<Profile?> fetchProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile.php'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return Profile.fromJson(jsonResponse);
    } else {
      throw Exception('Falha ao buscar perfil');
    }
  }

  // Método para buscar uploads
  Future<List<Upload>> fetchUploads(int visitaId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/list_uploads.php?visita_id=$visitaId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Upload.fromJson(json)).toList();
    } else {
      throw Exception('Erro na resposta da API');
    }
  }

  // Método para fazer upload de arquivos
  Future<bool> uploadFile(
      int visitaId, String filePath, String token, String legenda) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload.php'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['visita_id'] = visitaId.toString();
    request.fields['legenda'] = legenda;
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await http.Response.fromStream(response);
      final Map<String, dynamic> result = json.decode(responseData.body);
      return result.containsKey('success');
    } else {
      final responseData = await http.Response.fromStream(response);
      print('Erro ao enviar arquivo: ${responseData.body}');
      return false;
    }
  }

  // Método para adicionar visita
  Future<bool> addVisit(
      String token, String descricao, String dataVisita) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add_visit.php'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'descricao': descricao,
        'data_visita': dataVisita,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> result = jsonDecode(response.body);
      return result.containsKey('success');
    } else {
      return false;
    }
  }

  // Método para enviar dados de semeadura
  Future<bool> enviarSemeadura(Semeadura semeadura, String token) async {
    final uri = Uri.parse('$baseUrl/caderno.php');
    var request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['tipo'] = semeadura.tipo;
    request.fields['data'] = semeadura.data;
    request.fields['atividade'] = semeadura.atividade;
    request.fields['quantidade'] = semeadura.quantidade.toString();
    request.fields['especie'] = semeadura.especie;
    request.fields['local'] = semeadura.local;

    // Adicionar arquivo, se existir
    if (semeadura.arquivo.isNotEmpty) {
      request.files
          .add(await http.MultipartFile.fromPath('arquivo', semeadura.arquivo));
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await http.Response.fromStream(response);
      final Map<String, dynamic> result = json.decode(responseData.body);
      if (result.containsKey('message')) {
        return true;
      } else {
        print('Erro na resposta da API: ${responseData.body}');
        return false;
      }
    } else {
      final responseData = await http.Response.fromStream(response);
      print('Erro na resposta da API: ${responseData.body}');
      throw Exception('Erro ao enviar os dados da semeadura');
    }
  }

  // 1. Enviar mensagem
  Future<bool> sendMessage(String token, String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send_message.php'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        print("Mensagem enviada com sucesso!");
        return true;
      } else {
        print("Erro ao enviar mensagem. Status code: ${response.statusCode}");
        print("Resposta do servidor: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Erro na requisição de envio de mensagem: $e");
      return false;
    }
  }

  // 2. Buscar mensagens
  Future<List<Message>> fetchMessages(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fetch_messages.php'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = jsonDecode(response.body);
        print("Mensagens carregadas com sucesso!");
        return jsonResponse.map((json) => Message.fromJson(json)).toList();
      } else {
        print("Erro ao buscar mensagens. Status code: ${response.statusCode}");
        print("Resposta do servidor: ${response.body}");
        throw Exception('Erro ao buscar mensagens');
      }
    } catch (e) {
      print("Erro na requisição de busca de mensagens: $e");
      throw Exception('Erro ao buscar mensagens');
    }
  }

  // 3. Marcar mensagem como lida
  Future<bool> markAsRead(String token, int messageId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mark_as_read.php'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'message_id': messageId}),
    );

    if (response.statusCode == 200) {
      print("Mensagem marcada como lida com sucesso!");
      return true;
    } else {
      print(
          "Erro ao marcar mensagem como lida. Status code: ${response.statusCode}");
      return false;
    }
  }

  // 4. Buscar quantidade de mensagens não lidas
  Future<int> fetchUnreadMessagesCount(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fetch_unread_messages.php'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print("Quantidade de mensagens não lidas carregada com sucesso!");
        return jsonResponse['unread_count'] ?? 0;
      } else {
        print(
            "Erro ao buscar quantidade de mensagens não lidas. Status code: ${response.statusCode}");
        print("Resposta do servidor: ${response.body}");
        throw Exception('Erro ao buscar quantidade de mensagens não lidas');
      }
    } catch (e) {
      print("Erro na requisição de busca de mensagens não lidas: $e");
      throw Exception('Erro ao buscar quantidade de mensagens não lidas');
    }
  }

  // Novo método para enviar digitalizados
  Future<bool> enviarDigitalizados({
    required File file,
    required String fileName,
    required String token,
    required String documentType,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/digitalizados.php');
      final request = http.MultipartRequest('POST', uri);

      // Adiciona o arquivo ao pedido
      request.files.add(await http.MultipartFile.fromPath('imagem', file.path));

      // Adiciona o nome do arquivo ao pedido
      request.fields['nome_arquivo'] = fileName;
      request.fields['tipo_documento'] = documentType;

      // Adiciona o token de autenticação ao cabeçalho do pedido
      request.headers['Authorization'] = 'Bearer $token';

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final Map<String, dynamic> result = json.decode(responseData.body);
        return result.containsKey('success');
      } else {
        final responseData = await http.Response.fromStream(response);
        print('Erro ao enviar documento digitalizado: ${responseData.body}');
        return false;
      }
    } catch (e) {
      print('Erro ao enviar documento digitalizado: $e');
      return false;
    }
  }

  // Método para buscar documentos digitalizados
  Future<List<Digitalizado>> fetchDigitalizados(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/list_documentos.php'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Digitalizado.fromJson(item)).toList();
    } else {
      throw Exception('Erro ao buscar documentos');
    }
  }

  getDocumentosDigitalizados(String token) {}
}
