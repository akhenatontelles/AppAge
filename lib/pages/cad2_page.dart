import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:page_transition/page_transition.dart';
import 'cad3_page.dart';

class CadastroParteDois extends StatefulWidget {
  final String nome;
  final String nascimento;
  final String rg;
  final String cpf;
  final String cel;

  const CadastroParteDois({
    super.key,
    required this.nome,
    required this.nascimento,
    required this.rg,
    required this.cpf,
    required this.cel,
  });

  @override
  _CadastroParteDoisState createState() => _CadastroParteDoisState();
}

class _CadastroParteDoisState extends State<CadastroParteDois>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _enderecoController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _nomePropController = TextEditingController();
  final TextEditingController _atividadeController = TextEditingController();
  String? _selectedGrupo;
  bool _hasSubmitted = false;
  bool _isLoadingLocation = false;
  bool _locationSuccess = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<String> grupos = [
    'Grupo Agua e Vida',
    'Grupo Aroeira',
    'Grupo Jatobá',
    'Grupo Raiz Encantada',
    'Grupo Viver Produzir e Preservar',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _enderecoController.dispose();
    _cepController.dispose();
    _nomePropController.dispose();
    _atividadeController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationSuccess = false;
    });

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _cepController.text = 'Serviço de localização desativado';
        _isLoadingLocation = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _cepController.text = 'Permissão de localização negada';
          _isLoadingLocation = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _cepController.text = 'Permissão negada permanentemente';
        _isLoadingLocation = false;
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _cepController.text =
          'Lat: ${position.latitude}, Lng: ${position.longitude}';
      _isLoadingLocation = false;
      _locationSuccess = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1ED),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildFormFields(),
                  const SizedBox(height: 40),
                  _buildNextButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2e604a).withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.location_on_rounded,
            size: 32,
            color: Color(0xFF2e604a),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Localização",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2e604a),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Informações da Propriedade",
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xFF2e604a).withOpacity(0.7),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _buildTextFieldWithIcon(
          Icons.home,
          "Endereço",
          TextInputType.text,
          _enderecoController,
        ),
        const SizedBox(height: 16),
        _buildLocationButton(),
        const SizedBox(height: 16),
        _buildTextFieldWithIcon(
          Icons.business,
          "Nome da Propriedade",
          TextInputType.text,
          _nomePropController,
        ),
        const SizedBox(height: 16),
        _buildTextFieldWithIcon(
          Icons.nature_people,
          "Atividade",
          TextInputType.text,
          _atividadeController,
        ),
        const SizedBox(height: 16),
        _buildGrupoField(),
      ],
    );
  }

  Widget _buildLocationButton() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF2e604a),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2e604a).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoadingLocation ? null : _getCurrentLocation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoadingLocation
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : _locationSuccess
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Localização Obtida',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Obter Localização',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
      ),
    );
  }

  Widget _buildTextFieldWithIcon(
    IconData icon,
    String hintText,
    TextInputType inputType,
    TextEditingController controller, {
    MaskTextInputFormatter? maskFormatter,
    bool optional = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2e604a).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF2e604a),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: inputType,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2e604a),
                  ),
                  inputFormatters: maskFormatter != null ? [maskFormatter] : [],
                  decoration: InputDecoration(
                    hintText: _hasSubmitted && controller.text.isEmpty
                        ? 'Por favor, insira $hintText'
                        : hintText,
                    hintStyle: TextStyle(
                      color: _hasSubmitted && controller.text.isEmpty
                          ? Colors.red.withOpacity(0.6)
                          : const Color(0xFF2e604a).withOpacity(0.4),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    errorStyle: const TextStyle(height: 0),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  validator: (value) {
                    if (!optional && (value == null || value.isEmpty)) {
                      return '';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrupoField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showGrupoModal,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2e604a).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.group,
                    color: Color(0xFF2e604a),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _selectedGrupo ?? "Selecione um Grupo",
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedGrupo == null
                          ? const Color(0xFF2e604a).withOpacity(0.4)
                          : const Color(0xFF2e604a),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: const Color(0xFF2e604a).withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGrupoModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: grupos.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final grupo = grupos[index];
                    return ListTile(
                      title: Text(
                        grupo,
                        style: const TextStyle(
                          color: Color(0xFF2e604a),
                          fontSize: 16,
                        ),
                      ),
                      trailing: _selectedGrupo == grupo
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFF8EC63F),
                            )
                          : null,
                      onTap: () {
                        setState(() => _selectedGrupo = grupo);
                        Navigator.pop(context);
                      },
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

  Widget _buildNextButton() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF8EC63F), Color(0xFF7AB52D)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8EC63F).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _hasSubmitted = true;
          });
          if (_formKey.currentState?.validate() == true) {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: CadastroParteTres(
                  nome: widget.nome,
                  nascimento: widget.nascimento,
                  rg: widget.rg,
                  cpf: widget.cpf,
                  cel: widget.cel,
                  endereco: _enderecoController.text,
                  cep: _cepController.text,
                  nomePropriedade: _nomePropController.text,
                  atividade: _atividadeController.text,
                  grupo: _selectedGrupo ?? '',
                ),
                duration: const Duration(milliseconds: 300),
                reverseDuration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Próximo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
