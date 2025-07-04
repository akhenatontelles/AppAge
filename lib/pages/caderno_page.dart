import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../services/api_service.dart';
import '../models/semeadura_model.dart';

// Cores do sistema atualizadas
const Color kPrimaryColor = Color(0xFF2C3E50);
const Color kAccentColor = Color(0xFF16A085);
const Color kBackgroundColor = Color(0xFFF5F6FA);
const Color kCardColor = Colors.white;
const Color kTextColor = Color(0xFF2C3E50);
const Color kErrorColor = Color(0xFFE57373);

class CadernoPage extends StatefulWidget {
  final String token;
  const CadernoPage({super.key, required this.token});

  @override
  _CadernoPageState createState() => _CadernoPageState();
}

class _CadernoPageState extends State<CadernoPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<TextEditingController> _dataControllers =
      List.generate(3, (_) => TextEditingController());
  final TextEditingController _tipoInsumoController = TextEditingController();
  final TextEditingController _quantidadeController = TextEditingController();
  final TextEditingController _origemController = TextEditingController();
  final TextEditingController _notaFiscalController = TextEditingController();

  final _dateMaskFormatter = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  File? _file;
  bool _fileLoaded = false;
  bool _isSubmitting = false;

  final List<String> _tabTitles = [
    'Registro de Semeadura e Plantio',
    'Registro de Aquisição de Insumos',
    'Registro de Uso de Insumo',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var c in _dataControllers) {
      c.dispose();
    }
    _tipoInsumoController.dispose();
    _quantidadeController.dispose();
    _origemController.dispose();
    _notaFiscalController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    setState(() {
      if (result != null) {
        _file = File(result.files.single.path!);
        _fileLoaded = true;
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _file = File(pickedFile.path);
        _fileLoaded = true;
      }
    });
  }

  void _showFilePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Adicionar Arquivo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
                const SizedBox(height: 32),
                _buildFilePickerOption(
                  icon: Icons.attach_file_rounded,
                  title: 'Selecionar Arquivo',
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile();
                  },
                ),
                const SizedBox(height: 16),
                _buildFilePickerOption(
                  icon: Icons.camera_alt_rounded,
                  title: 'Tirar Foto',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilePickerOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kAccentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: kAccentColor, size: 28),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: kTextColor,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: onTap,
    );
  }

  Future<void> _submitForm() async {
    if (_isSubmitting) return;

    if (!_validateForm()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await _sendFormData();
      _handleSubmitResponse(success);
    } catch (e) {
      _handleSubmitError(e);
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  bool _validateForm() {
    // Removido a verificação de campos obrigatórios
    return true;
  }

  Future<bool> _sendFormData() async {
    final semeadura = Semeadura(
      tipo: _tabTitles[_tabController.index],
      data: _dataControllers[_tabController.index].text,
      atividade: _tipoInsumoController.text,
      quantidade: int.tryParse(_quantidadeController.text) ?? 0,
      especie: _origemController.text,
      local: _notaFiscalController.text,
      arquivo: _file?.path ?? '',
    );

    final apiService = ApiService('https://api.testelab.me');
    return await apiService.enviarSemeadura(semeadura, widget.token);
  }

  void _handleSubmitResponse(bool success) {
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro enviado com sucesso!'),
          backgroundColor: kAccentColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _clearFields();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falha ao enviar registro.'),
          backgroundColor: kErrorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleSubmitError(dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erro: $error'),
        backgroundColor: kErrorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearFields() {
    setState(() {
      _tipoInsumoController.clear();
      _quantidadeController.clear();
      _origemController.clear();
      _notaFiscalController.clear();
      for (var controller in _dataControllers) {
        controller.clear();
      }
      _file = null;
      _fileLoaded = false;
    });
  }

  Widget _buildDateField(int tabIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _dataControllers[tabIndex],
        keyboardType: TextInputType.number,
        inputFormatters: [_dateMaskFormatter],
        style: const TextStyle(
          fontSize: 16,
          color: kTextColor,
        ),
        decoration: InputDecoration(
          labelText: 'Data *',
          labelStyle: TextStyle(
            color: kTextColor.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          hintText: 'dd/MM/aaaa',
          hintStyle: TextStyle(
            color: kTextColor.withOpacity(0.5),
            fontSize: 14,
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today_rounded, color: kAccentColor),
            onPressed: () => _selectDate(context, tabIndex),
          ),
          filled: true,
          fillColor: kCardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.1),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(
              color: kAccentColor,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, int tabIndex) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kAccentColor,
              onPrimary: Colors.white,
              surface: kCardColor,
              onSurface: kTextColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dataControllers[tabIndex].text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Widget _buildGenericForm(int tabIndex) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDateField(tabIndex),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _tipoInsumoController,
            label: 'Atividade *',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _quantidadeController,
            label: 'Quantidade *',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _origemController,
            label: 'Espécie',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _notaFiscalController,
            label: 'Local',
          ),
          const SizedBox(height: 24),
          _buildFileSection(),
          const SizedBox(height: 32),
          _buildSubmitButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType ?? TextInputType.text,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 16,
          color: kTextColor,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: kTextColor.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: kCardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.1),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: kAccentColor,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildFileSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch, // Ajuste para evitar overflow
        children: [
          if (_fileLoaded)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kAccentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: kAccentColor, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    // Usar Expanded para evitar overflow
                    child: Text(
                      'Arquivo carregado com sucesso',
                      style: TextStyle(
                        color: kAccentColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center, // Centralizar texto
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showFilePickerDialog,
            icon: const Icon(Icons.add_rounded, size: 24),
            label: const Text(
              'Adicionar Arquivo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: kAccentColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: kPrimaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Cadastrar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildTabContent(String title, Widget content) {
    return SingleChildScrollView(
      // Alterado para permitir rolagem
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18, // Diminuído para evitar overflow
              fontWeight: FontWeight.w700,
              color: kPrimaryColor,

              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          content, // Removido Expanded para permitir rolagem
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          title: const Text(
            'Caderno de Registro',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(65),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 40, 109, 79),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                dividerColor: Colors.transparent,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                tabs: [
                  Tab(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.spa_outlined, size: 24),
                          SizedBox(height: 4),
                          Text(
                            'Semeadura',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 24),
                          SizedBox(height: 4),
                          Text(
                            'Insumos',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_florist_outlined, size: 24),
                          SizedBox(height: 4),
                          Text(
                            'Uso',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
        body: Container(
          // Removido a margem superior
          decoration: BoxDecoration(
            color: const Color(0xFFF5F1ED),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent(
                  'Registro de Semeadura e Plantio',
                  _buildGenericForm(0),
                ),
                _buildTabContent(
                  'Registro de Aquisição de Insumos',
                  _buildGenericForm(1),
                ),
                _buildTabContent(
                  'Registro de Uso de Insumo',
                  _buildGenericForm(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
