import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import '../services/api_service.dart';
import '../models/visit_model.dart';

class VisitDetailsPage extends StatefulWidget {
  final int visitaId;
  final String token;
  final String descricao;
  final String dataVisita;

  const VisitDetailsPage({
    super.key,
    required this.visitaId,
    required this.token,
    required this.descricao,
    required this.dataVisita,
  });

  @override
  _VisitDetailsPageState createState() => _VisitDetailsPageState();
}

class _VisitDetailsPageState extends State<VisitDetailsPage> {
  late Future<List<Upload>> _uploads;
  final ApiService apiService = ApiService('https://api.testelab.me');
  File? _file;
  String _legenda = '';

  @override
  void initState() {
    super.initState();
    _uploads = apiService.fetchUploads(widget.visitaId, widget.token);
  }

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      PlatformFile platformFile = result.files.first;
      if (platformFile.path != null) {
        _showLegendaDialog(platformFile.path!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Erro ao selecionar arquivo. Caminho não encontrado.'),
            backgroundColor: Color(0xFF2e604a),
          ),
        );
      }
    }
  }

  void _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      _showLegendaDialog(pickedFile.path);
    }
  }

  void _showLegendaDialog(String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Adicionar Legenda',
            style: TextStyle(
              color: Color(0xFF2e604a),
              fontWeight: FontWeight.w600,
            ),
          ),
          content: TextField(
            onChanged: (value) {
              setState(() {
                _legenda = value;
              });
            },
            decoration: InputDecoration(
              hintText: "Digite uma legenda",
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF2e604a)),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                "Cancelar",
                style: TextStyle(color: Colors.grey[600]),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2e604a),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Salvar"),
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await apiService.uploadFile(
                  widget.visitaId,
                  filePath,
                  widget.token,
                  _legenda,
                );
                if (success) {
                  setState(() {
                    _uploads =
                        apiService.fetchUploads(widget.visitaId, widget.token);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Arquivo carregado com sucesso!'),
                      backgroundColor: Color(0xFF2e604a),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Falha ao adicionar arquivo'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _viewImagesFullScreen(List<Upload> uploads, int initialIndex) {
    final PageController pageController =
        PageController(initialPage: initialIndex);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.black,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: PageView.builder(
                  controller: pageController,
                  itemCount: uploads.length,
                  itemBuilder: (context, index) {
                    final upload = uploads[index];
                    final imageUrl = upload.fileType == 'pdf'
                        ? 'https://api.testelab.me/uploads/pdf.png'
                        : 'https://api.testelab.me/uploads/${upload.filePath.split('/').last}';

                    return Center(
                      child: InteractiveViewer(
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          width: MediaQuery.of(context).size.width,
                          loadingBuilder: (BuildContext context, Widget child,
                              ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF2e604a),
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: pageController,
                  builder: (context, child) {
                    int currentPage = pageController.hasClients
                        ? pageController.page?.round() ?? initialIndex
                        : initialIndex;
                    final upload = uploads[currentPage];
                    final legenda = upload.legenda ?? 'Sem legenda';
                    final data =
                        DateFormat('dd/MM/yyyy').format(upload.uploadDatetime);

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            legenda,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.descricao,
              style: const TextStyle(
                color: Color(0xFF2e604a),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.dataVisita,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF2e604a),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Upload>>(
        future: _uploads,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2e604a),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
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
                    'Erro ao carregar os arquivos',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum arquivo carregado',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final uploads = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: uploads.length,
            itemBuilder: (context, index) {
              final upload = uploads[index];
              final imageUrl = upload.fileType == 'pdf'
                  ? 'https://api.testelab.me/uploads/pdf.png'
                  : 'https://api.testelab.me/uploads/${upload.filePath.split('/').last}';
              final formattedDate =
                  DateFormat('dd/MM/yyyy').format(upload.uploadDatetime);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () => _viewImagesFullScreen(uploads, index),
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: const Color(0xFF2e604a),
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                upload.legenda ?? 'Sem legenda',
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
                                formattedDate,
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
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _takePhoto,
            heroTag: 'camera',
            backgroundColor: const Color(0xFF2e604a),
            child: const Icon(Icons.camera_alt_rounded),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _pickFile,
            heroTag: 'attach',
            backgroundColor: const Color(0xFF2e604a),
            child: const Icon(Icons.attach_file_rounded),
          ),
        ],
      ),
    );
  }
}
// ... código anterior ...

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
