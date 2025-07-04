import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:photo_view/photo_view.dart';

class RegistroSemeadura extends StatefulWidget {
  final String token;

  const RegistroSemeadura({super.key, required this.token});

  @override
  _RegistroSemeaduraState createState() => _RegistroSemeaduraState();
}

class _RegistroSemeaduraState extends State<RegistroSemeadura> {
  List<dynamic> _atividades = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAtividades();
  }

  Future<void> _fetchAtividades() async {
    const url = 'https://api.testelab.me/list_caderno.php';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        if (decodedResponse is List) {
          setState(() {
            _atividades = decodedResponse
                .where((atividade) =>
                    atividade['tipo'] == 'Registro de Semeadura e Plantio')
                .toList();
            _isLoading = false;
          });
        } else if (decodedResponse is Map) {
          setState(() {
            _errorMessage = decodedResponse['message'] ?? 'Erro desconhecido';
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Resposta inesperada do servidor';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Erro ao carregar os dados: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Erro ao carregar os dados: $error';
        _isLoading = false;
      });
    }
  }

  void _mostrarDetalhes(BuildContext context, dynamic atividade) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(24),
              child: ListView(
                controller: controller,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    atividade['atividade'] ?? 'Sem descrição',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2e604a),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow('Data:', atividade['data']),
                  _buildDetailRow('Quantidade:', atividade['quantidade']),
                  _buildDetailRow('Espécie:', atividade['especie']),
                  if (atividade['arquivo'] != null &&
                      atividade['arquivo'].isNotEmpty) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _abrirArquivo(atividade['arquivo']);
                      },
                      icon: const Icon(Icons.attachment),
                      label: const Text('Visualizar Anexo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2e604a),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    String displayValue = value != null ? value.toString() : 'Não especificado';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2e604a),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayValue,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirArquivo(String caminho) async {
    final Uri url = Uri.parse('https://testelab.me/$caminho').normalizePath();

    if (caminho.endsWith('.pdf')) {
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/tempfile.pdf';
      final response = await http.get(url);

      final file = File(tempPath);
      await file.writeAsBytes(response.bodyBytes);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PDFViewerPage(path: tempPath)),
      );
    } else if (caminho.endsWith('.jpg') ||
        caminho.endsWith('.jpeg') ||
        caminho.endsWith('.png')) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ImageViewerPage(url: url.toString())),
      );
    } else {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'Não foi possível abrir o arquivo: $url';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1ED),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        title: const Text(
          'Registro de Semeadura',
          style: TextStyle(
            color: Color(0xFF2e604a),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF2e604a),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2e604a),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : _atividades.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.grass_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum registro encontrado',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: _atividades.length,
                      itemBuilder: (context, index) {
                        final atividade = _atividades[index];
                        final dataString = atividade['data'] as String?;
                        String dataFormatada = 'Data não disponível';

                        if (dataString != null && dataString.isNotEmpty) {
                          try {
                            final DateTime data = DateTime.parse(dataString);
                            dataFormatada =
                                DateFormat('dd/MM/yyyy').format(data);
                          } catch (e) {
                            dataFormatada = 'Data inválida';
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: InkWell(
                            onTap: () => _mostrarDetalhes(context, atividade),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2e604a)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.grass_rounded,
                                      color: Color(0xFF2e604a),
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          atividade['atividade'] ??
                                              'Sem descrição',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2e604a),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          dataFormatada,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFF2e604a),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class PDFViewerPage extends StatelessWidget {
  final String path;

  const PDFViewerPage({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        title: const Text(
          'Visualizar PDF',
          style: TextStyle(
            color: Color(0xFF2e604a),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF2e604a),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PDFView(
        filePath: path,
      ),
    );
  }
}

class ImageViewerPage extends StatelessWidget {
  final String url;

  const ImageViewerPage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Visualizar Imagem',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PhotoView(
        imageProvider: NetworkImage(url),
        backgroundDecoration: const BoxDecoration(
          color: Colors.black,
        ),
      ),
    );
  }
}
