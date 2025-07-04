import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';
import 'dart:convert';
import '../main.dart';

class CadastroParteTres extends StatefulWidget {
  final String nome;
  final String nascimento;
  final String rg;
  final String cpf;
  final String cel;
  final String endereco;
  final String cep;
  final String nomePropriedade;
  final String atividade;
  final String grupo;

  const CadastroParteTres({
    super.key,
    required this.nome,
    required this.nascimento,
    required this.rg,
    required this.cpf,
    required this.cel,
    required this.endereco,
    required this.cep,
    required this.nomePropriedade,
    required this.atividade,
    required this.grupo,
  });

  @override
  _CadastroParteTresState createState() => _CadastroParteTresState();
}

class _CadastroParteTresState extends State<CadastroParteTres>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _outraCertificacaoController =
      TextEditingController();

  String? _certificacaoOrg = 'OPAC-AGE';
  String? _situacaoFundiaria = 'Escritura Definitiva';
  bool mostraCampoOutraCertificacao = false;
  bool _hasSubmitted = false;
  bool _enviadoComSucesso = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<String> certificacoesOrg = ['OPAC-AGE', 'Outra'];
  List<String> situacoesFundiarias = [
    'Escritura Definitiva',
    'Arrendamento',
    'Parceria',
    'Posse',
    'Protocolo de assentado'
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
    _outraCertificacaoController.dispose();
    super.dispose();
  }

  Future<void> _enviarDados() async {
    setState(() {
      _hasSubmitted = true;
    });

    if (_formKey.currentState!.validate()) {
      String certificacaoOrganicaFinal = _certificacaoOrg == 'Outra'
          ? _outraCertificacaoController.text
          : _certificacaoOrg ?? '';

      final data = {
        'nome': widget.nome,
        'nascimento': widget.nascimento,
        'rg': widget.rg,
        'cpf': widget.cpf,
        'cel': widget.cel,
        'endereco': widget.endereco,
        'cep': widget.cep,
        'nomePropriedade': widget.nomePropriedade,
        'atividade': widget.atividade,
        'grupo': widget.grupo,
        'certificacao_org': certificacaoOrganicaFinal,
        'situacaoFundiaria': _situacaoFundiaria,
      };

      try {
        final response = await http.post(
          Uri.parse('https://api.testelab.me/register.php'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(data),
        );

        if (response.statusCode == 200) {
          setState(() {
            _enviadoComSucesso = true;
          });
        } else {
          _showErrorSnackBar('Falha ao enviar dados. Tente novamente.');
        }
      } catch (e) {
        _showErrorSnackBar('Erro de conexão. Verifique sua internet.');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_enviadoComSucesso) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F1ED),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8EC63F).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 100,
                      color: Color(0xFF8EC63F),
                    ),
                  ),
                  const SizedBox(height: 32),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: 'Ótimo ter você conosco\n',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Color(0xFF2e604a),
                        height: 1.5,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: '${widget.nome}!',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(
                          text:
                              '\n\nEm breve, entraremos em contato para finalizar seu cadastro. Fique atento!',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildHomeButton(),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
                  _buildFinishButton(),
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
            Icons.verified_user_rounded,
            size: 32,
            color: Color(0xFF2e604a),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Certificação",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2e604a),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Informações Legais",
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
        _buildRadioField(
            'Certificação Orgânica', certificacoesOrg, _certificacaoOrg),
        const SizedBox(height: 20),
        if (_certificacaoOrg == 'Outra')
          Column(
            children: [
              _buildTextFieldWithIcon(
                Icons.verified_rounded,
                'Nome da Certificação',
                TextInputType.text,
                _outraCertificacaoController,
              ),
              const SizedBox(height: 20),
            ],
          ),
        _buildRadioField(
            'Situação Fundiária', situacoesFundiarias, _situacaoFundiaria),
      ],
    );
  }

  Widget _buildTextFieldWithIcon(IconData icon, String hintText,
      TextInputType inputType, TextEditingController controller) {
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
                    if (value == null || value.isEmpty) {
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

  Widget _buildRadioField(
      String title, List<String> options, String? selectedValue) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2e604a),
              ),
            ),
          ),
          const Divider(height: 1),
          ...options.map((option) => RadioListTile<String>(
                title: Text(
                  option,
                  style: const TextStyle(
                    color: Color(0xFF2e604a),
                    fontSize: 15,
                  ),
                ),
                value: option,
                groupValue: selectedValue,
                activeColor: const Color(0xFF8EC63F),
                onChanged: (value) {
                  setState(() {
                    if (title == 'Certificação Orgânica') {
                      _certificacaoOrg = value;
                      mostraCampoOutraCertificacao = value == 'Outra';
                    } else if (title == 'Situação Fundiária') {
                      _situacaoFundiaria = value;
                    }
                  });
                },
              )),
        ],
      ),
    );
  }

  Widget _buildFinishButton() {
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
        onPressed: _enviarDados,
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
              'Finalizar Cadastro',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeButton() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF2e604a), Color(0xFF235038)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2e604a).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            PageTransition(
              type: PageTransitionType.fade,
              child: const MyApp(),
              duration: const Duration(milliseconds: 300),
              reverseDuration: const Duration(milliseconds: 300),
            ),
          );
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
            Icon(
              Icons.home_rounded,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Voltar para o Início',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
