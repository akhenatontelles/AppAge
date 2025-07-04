import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:page_transition/page_transition.dart';
import 'cad2_page.dart';

class CadastroParteUm extends StatefulWidget {
  const CadastroParteUm({super.key});

  @override
  _CadastroParteUmState createState() => _CadastroParteUmState();
}

class _CadastroParteUmState extends State<CadastroParteUm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final phoneMaskFormatter = MaskTextInputFormatter(mask: "(##) # ####-####");
  final dateMaskFormatter = MaskTextInputFormatter(mask: "##/##/####");
  final cpfMaskFormatter = MaskTextInputFormatter(mask: "###.###.###-##");
  final rgMaskFormatter = MaskTextInputFormatter(mask: "#.###.###");

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _rgController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _celController = TextEditingController();

  bool _hasSubmitted = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _nomeController.dispose();
    _dataController.dispose();
    _rgController.dispose();
    _cpfController.dispose();
    _celController.dispose();
    super.dispose();
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
            Icons.person_add_rounded,
            size: 32,
            color: Color(0xFF2e604a),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Cadastro",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2e604a),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Informações Pessoais",
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
          Icons.person,
          "Nome Completo",
          TextInputType.text,
          _nomeController,
        ),
        const SizedBox(height: 16),
        _buildTextFieldWithIcon(
          Icons.calendar_today,
          "Data de Nascimento",
          TextInputType.number,
          _dataController,
          dateMaskFormatter,
        ),
        const SizedBox(height: 16),
        _buildTextFieldWithIcon(
          Icons.perm_identity,
          "RG",
          TextInputType.number,
          _rgController,
          rgMaskFormatter,
        ),
        const SizedBox(height: 16),
        _buildTextFieldWithIcon(
          Icons.credit_card,
          "CPF",
          TextInputType.number,
          _cpfController,
          cpfMaskFormatter,
        ),
        const SizedBox(height: 16),
        _buildTextFieldWithIcon(
          Icons.phone,
          "CEL",
          TextInputType.phone,
          _celController,
          phoneMaskFormatter,
        ),
      ],
    );
  }

  Widget _buildTextFieldWithIcon(
    IconData icon,
    String hintText,
    TextInputType inputType,
    TextEditingController controller, [
    MaskTextInputFormatter? maskFormatter,
  ]) {
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
            _navigateToNextScreen(context);
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

  void _navigateToNextScreen(BuildContext context) {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: CadastroParteDois(
          nome: _nomeController.text,
          nascimento: _dataController.text,
          rg: _rgController.text,
          cpf: _cpfController.text,
          cel: _celController.text,
        ),
        duration: const Duration(milliseconds: 300),
        reverseDuration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }
}
