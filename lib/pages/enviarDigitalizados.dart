import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
// Importar o modelo Digitalizado

class ApiService {
  final String baseUrl;

  ApiService(this.baseUrl);

  // Outros métodos...

  // Novo método para enviar digitalizados
  Future<bool> enviarDigitalizados({
    required File file,
    required String fileName,
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/digitalizados.php');
      final request = http.MultipartRequest('POST', uri);

      // Adiciona o arquivo ao pedido
      request.files.add(await http.MultipartFile.fromPath('imagem', file.path));

      // Adiciona o nome do arquivo ao pedido
      request.fields['nome_arquivo'] = fileName;

      // Adiciona o token de autenticação ao cabeçalho do pedido
      request.headers['Authorization'] = token;

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseBody);

        if (jsonResponse['success'] != null) {
          return true;
        } else {
          print("Erro na resposta da API: ${jsonResponse['error']}");
          return false;
        }
      } else {
        final responseBody = await response.stream.bytesToString();
        print('Erro no envio: ${response.statusCode}');
        print('Resposta do servidor: $responseBody');
        return false;
      }
    } catch (e) {
      print('Erro: $e');
      return false;
    }
  }

  // Outros métodos...
}
