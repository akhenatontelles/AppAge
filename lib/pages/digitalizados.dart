import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:photo_view/photo_view.dart';
import '../services/api_service.dart';
import '../models/digitalizados_model.dart';

class DigitalizadosPage extends StatefulWidget {
  final String token;

  const DigitalizadosPage({super.key, required this.token});

  @override
  _DigitalizadosPageState createState() => _DigitalizadosPageState();
}

class _DigitalizadosPageState extends State<DigitalizadosPage> {
  File? _selectedFile;
  bool _fileLoaded = false;
  String? _selectedDocumentType;
  final List<String> _documentTypes = [
    'Análise de Água',
    'Análise de Solo',
    'CAF',
    'CAR',
    'CNH',
    'Comprovante de Endereço',
    'CPF',
    'Declaração da Emater',
    'Documento da Propriedade',
    'RG',
  ];
  final TextEditingController _newDocumentTypeController =
      TextEditingController();
  List<Digitalizado> _documentosDigitalizados = [];

  @override
  void initState() {
    super.initState();
    _fetchDocumentosDigitalizados();
  }

  Future<void> _fetchDocumentosDigitalizados() async {
    try {
      final apiService = ApiService('https://api.testelab.me');
      final response = await apiService.fetchDigitalizados(widget.token);

      setState(() {
        _documentosDigitalizados = response;
      });
    } catch (e) {
      setState(() {
        _documentosDigitalizados = [];
      });
      // Não exibir o SnackBar quando houver erro
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'pdf',
        'doc',
        'docx',
        'txt',
        'rtf',
        'xls',
        'xlsx',
        'csv'
      ],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileLoaded = true;
      });
      _submitForm();
    } else {
      setState(() {
        _fileLoaded = false;
      });
    }
  }

  Widget _buildFileTypeIcon(String fileExtension) {
    IconData iconData;
    switch (fileExtension) {
      case 'pdf':
        iconData = Icons.picture_as_pdf_rounded;
        break;
      case 'doc':
      case 'docx':
      case 'txt':
      case 'rtf':
        iconData = Icons.description_rounded;
        break;
      case 'xls':
      case 'xlsx':
      case 'csv':
        iconData = Icons.table_chart_rounded;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
        iconData = Icons.image_rounded;
        break;
      default:
        iconData = Icons.insert_drive_file_rounded;
    }
    return Icon(
      iconData,
      color: const Color(0xFF2e604a),
      size: 24,
    );
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
        _fileLoaded = true;
      });
      _submitForm(); // Envio automático após tirar a foto
    } else {
      setState(() {
        _fileLoaded = false;
      });
    }
  }

  void _showFilePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          backgroundColor: Colors.white, // Fundo branco para o modal
          title: const Text(
            'Selecionar Arquivo ou Tirar Foto',
            textAlign: TextAlign.center, // Centralizar o título
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.0, // Tamanho da fonte ajustado
              color: Colors.black87, // Cor do texto em preto suave
            ),
          ),
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.attach_file,
                    color: Colors.black54, // Ícone em tom de cinza
                  ),
                  title: const Text(
                    'Selecionar Arquivo',
                    style: TextStyle(
                      color: Colors.black87, // Texto em preto suave
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickFile();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: Colors.black54, // Ícone em tom de cinza
                  ),
                  title: const Text(
                    'Tirar Foto',
                    style: TextStyle(
                      color: Colors.black87, // Texto em preto suave
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _takePhoto();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDocumentTypeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          backgroundColor: Colors.white, // Modal com fundo branco
          title: const Text(
            'Selecione o Tipo de Documento',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
              color: Colors.black87, // Cor do texto em preto suave
            ),
          ),
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  isExpanded: true,
                  dropdownColor: Colors.white, // Fundo branco para o dropdown
                  hint: const Text(
                    'Selecione um tipo de documento',
                    style: TextStyle(color: Colors.black54), // Texto em cinza
                  ),
                  value: _selectedDocumentType,
                  onChanged: (String? newValue) {
                    if (newValue == 'Outro') {
                      Navigator.of(context).pop();
                      _showCreateDocumentTypeDialog();
                    } else {
                      setState(() {
                        _selectedDocumentType = newValue;
                      });
                      Navigator.of(context).pop();
                      // Abrir automaticamente o modal "Selecionar Arquivo ou Tirar Foto"
                      _showFilePickerDialog();
                    }
                  },
                  icon: const Icon(Icons.arrow_drop_down,
                      color: Colors.black54), // Ícone de seta em cinza
                  underline: Container(),
                  style: const TextStyle(
                      color: Colors.black87), // Texto dos itens em preto suave
                  items: _documentTypes
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList()
                    ..add(const DropdownMenuItem<String>(
                      value: 'Outro',
                      child: Text('Outro'),
                    )),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateDocumentTypeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          backgroundColor: Colors.white, // Fundo branco para o modal
          title: const Text(
            'Criar Novo Tipo de Documento',
            textAlign: TextAlign.center, // Centralizar o título
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.0, // Tamanho da fonte menor
              color: Colors.black87, // Cor do texto em preto suave
            ),
          ),
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _newDocumentTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Novo Tipo de Documento',
                    labelStyle: TextStyle(
                      color: Colors.black54, // Cor do label em cinza
                      fontSize: 16.0, // Fonte menor para o campo de entrada
                    ),
                    border: OutlineInputBorder(), // Borda ao redor do campo
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.black54), // Texto em cinza
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Criar',
                style: TextStyle(color: Colors.black87), // Texto em preto suave
              ),
              onPressed: () {
                final newType = _newDocumentTypeController.text.trim();
                if (newType.isNotEmpty) {
                  setState(() {
                    _documentTypes.add(newType);
                    _selectedDocumentType = newType;
                  });
                  _newDocumentTypeController.clear();
                  Navigator.of(context).pop(); // Fechar o modal
                  // Abrir automaticamente o modal "Selecionar Arquivo ou Tirar Foto"
                  _showFilePickerDialog();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (_selectedFile == null || _selectedDocumentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos.')),
      );
      return;
    }

    try {
      final apiService = ApiService('https://api.testelab.me');
      final success = await apiService.enviarDigitalizados(
        file: _selectedFile!,
        fileName: _selectedDocumentType!,
        token: widget.token,
        documentType: _selectedDocumentType!,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arquivo enviado com sucesso!')),
        );
        _clearFields();
        _fetchDocumentosDigitalizados(); // Atualizar a lista após o envio
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao enviar arquivo.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  void _clearFields() {
    setState(() {
      _selectedFile = null;
      _fileLoaded = false;
      _selectedDocumentType = null;
      _newDocumentTypeController.clear();
    });
  }

  Future<void> _openFile(Digitalizado documento) async {
    final String fileExtension =
        documento.nomeArquivo.split('.').last.toLowerCase();
    final String url = 'https://api.testelab.me/${documento.imagem}';

    if (fileExtension == 'pdf') {
      _abrirArquivo(url);
    } else {
      _openImage(url, documento.nomeArquivo);
    }
  }

  Future<void> _abrirArquivo(String caminho) async {
    final Uri url = Uri.parse(caminho);

    if (caminho.toLowerCase().endsWith('.pdf')) {
      try {
        final tempDir = await getTemporaryDirectory();
        final tempPath =
            '${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.pdf';

        final response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer ${widget.token}',
          },
        );

        if (response.statusCode == 200) {
          final file = File(tempPath);
          await file.writeAsBytes(response.bodyBytes);

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PDFViewerPage(
                  path: tempPath,
                ),
              ),
            );
          }
        } else {
          Fluttertoast.showToast(
            msg: 'Erro ao baixar o PDF: ${response.statusCode}',
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Erro ao abrir o PDF: $e',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } else if (caminho.toLowerCase().endsWith('.jpg') ||
        caminho.toLowerCase().endsWith('.jpeg') ||
        caminho.toLowerCase().endsWith('.png')) {
      _openImage(caminho, caminho.split('/').last);
    } else {
      Fluttertoast.showToast(
        msg: 'Tipo de arquivo não suportado',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void _openImage(String url, String fileName) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ImageViewerPage(imageUrl: url, fileName: fileName),
      ),
    );
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
          'Documentos',
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selecione um documento para digitalizar:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16.0),
            InkWell(
              onTap: _showDocumentTypeDialog,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2e604a).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.document_scanner_rounded,
                        color: Color(0xFF2e604a),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _selectedDocumentType ?? 'Selecionar Tipo de Documento',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedDocumentType != null
                              ? const Color(0xFF2e604a)
                              : Colors.grey[600],
                        ),
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
            if (_selectedDocumentType != null) ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: _showFilePickerDialog,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2e604a).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.attach_file_rounded,
                          color: Color(0xFF2e604a),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Anexar Documento',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF2e604a),
                          ),
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
            ],
            if (_fileLoaded) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700]),
                    const SizedBox(width: 12),
                    Text(
                      'Arquivo carregado com sucesso!',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Documentos Digitalizados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _documentosDigitalizados.isNotEmpty
                  ? ListView.builder(
                      itemCount: _documentosDigitalizados.length,
                      itemBuilder: (context, index) {
                        final documento = _documentosDigitalizados[index];
                        final String fileExtension =
                            documento.nomeArquivo.split('.').last.toLowerCase();
                        final String url =
                            'https://api.testelab.me/${documento.imagem}';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _openFile(documento),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
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
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2e604a)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: fileExtension == 'pdf'
                                        ? const Icon(
                                            Icons.picture_as_pdf_rounded,
                                            color: Color(0xFF2e604a),
                                            size: 24,
                                          )
                                        : ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.network(
                                              url,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return const Icon(
                                                  Icons.broken_image_rounded,
                                                  color: Color(0xFF2e604a),
                                                );
                                              },
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      documento.nomeArquivo,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF2e604a),
                                      ),
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
                    )
                  : Center(
                      child: Text(
                        'Nenhum documento digitalizado encontrado.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),
          ],
        ),
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
      backgroundColor: const Color(0xFFF5F1ED),
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
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: true,
        pageFling: true,
      ),
    );
  }
}

class ImageViewerPage extends StatelessWidget {
  final String imageUrl;
  final String fileName;

  const ImageViewerPage(
      {super.key, required this.imageUrl, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1ED),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        title: Text(
          fileName,
          style: const TextStyle(
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
      body: PhotoView(
        imageProvider: NetworkImage(imageUrl),
        backgroundDecoration: const BoxDecoration(
          color: Color(0xFFF5F1ED),
        ),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
        initialScale: PhotoViewComputedScale.contained,
      ),
    );
  }
}
