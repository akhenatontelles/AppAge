import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../design/app_colors.dart';
import '../design/app_text_styles.dart';
import '../services/api_service.dart';
import 'painel_page.dart';
import 'cad1_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  // Controllers
  final _cpfController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService('https://api.testelab.me');

  // State variables
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  // Animation
  AnimationController? _animController;
  Animation<double>? _fadeAnimation;

  // Formatters
  final _cpfFormatter = MaskTextInputFormatter(
      mask: '###.###.###-##', filter: {'#': RegExp(r'[0-9]')});

  // Gradiente de fundo
  static const List<Color> _backgroundGradient = [
    AppColors.gradientStart,
    AppColors.gradientEnd,
  ];

  @override
  void initState() {
    super.initState();
    _loadCredentials();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController!,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _animController!.forward();
  }

  @override
  void dispose() {
    _animController?.dispose();
    _cpfController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('username');
    final savedPassword = prefs.getString('password');
    final rememberMe = prefs.getBool('rememberMe') ?? false;

    if (rememberMe) {
      setState(() {
        _cpfController.text = savedUsername ?? '';
        _passwordController.text = savedPassword ?? '';
        _rememberMe = rememberMe;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('username', _cpfController.text);
      await prefs.setString('password', _passwordController.text);
    } else {
      await prefs.remove('username');
      await prefs.remove('password');
    }
    await prefs.setBool('rememberMe', _rememberMe);
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final tokenModel = await _apiService.login(
        _cpfController.text,
        _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (tokenModel != null && tokenModel.token != null) {
        await _saveCredentials();
        _navigateToDashboard(
            tokenModel.token!, tokenModel.nome ?? 'Nome desconhecido');
      } else {
        _showErrorSnackbar('Falha no login: token não encontrado.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _handleLoginError(e);
    }
  }

  void _navigateToDashboard(String token, String nome) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PainelPage(token: token, nome: nome),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 0.3);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: offsetAnimation,
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _handleLoginError(dynamic error) {
    final errorMessage = error.toString();
    if (errorMessage.contains('401')) {
      _showErrorSnackbar('Senha incorreta. Tente novamente.');
    } else if (errorMessage.contains('404')) {
      _showErrorSnackbar('Usuário não encontrado.');
    } else if (errorMessage.contains('400')) {
      _showErrorSnackbar('CPF e senha são obrigatórios.');
    } else {
      _showErrorSnackbar('Erro inesperado. Por favor, tente novamente.');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _backgroundGradient,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                _buildLogo(),
                const SizedBox(height: 32),
                _buildTitle(),
                const SizedBox(height: 8),
                _buildSubtitle(),
                const SizedBox(height: 48),
                _buildLoginForm(),
                const SizedBox(height: 24),
                _buildRememberAndForgotRow(),
                const SizedBox(height: 32),
                _buildLoginButton(),
                const SizedBox(height: 24),
                _buildSignUpRow(),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isLoading) _buildLoadingIndicator(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return FadeTransition(
      opacity: _fadeAnimation ?? const AlwaysStoppedAnimation<double>(1.0),
      child: Hero(
        tag: 'logo',
        child: Image.asset(
          'assets/images/selo_opac2.png',
          width: 110,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return FadeTransition(
      opacity: _fadeAnimation ?? const AlwaysStoppedAnimation<double>(1.0),
      child: Text(
        'Bem-vindo ao OPAC',
        textAlign: TextAlign.center,
        style: AppTextStyles.headline1.copyWith(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return FadeTransition(
      opacity: _fadeAnimation ?? const AlwaysStoppedAnimation<double>(1.0),
      child: Text(
        'Faça login para continuar',
        textAlign: TextAlign.center,
        style: AppTextStyles.subtitle.copyWith(
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return FadeTransition(
      opacity: _fadeAnimation ?? const AlwaysStoppedAnimation<double>(1.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CPF field
          _buildInputField(
            controller: _cpfController,
            hintText: 'CPF',
            icon: Icons.person_outline,
            inputFormatter: _cpfFormatter,
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 20),

          // Password field
          _buildInputField(
            controller: _passwordController,
            hintText: 'Senha',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            keyboardType: TextInputType.number,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey.shade600,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRememberAndForgotRow() {
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: _rememberMe,
            onChanged: (value) => setState(() => _rememberMe = value!),
            activeColor: Colors.white,
            checkColor: AppColors.primary,
            side: const BorderSide(color: Colors.white70),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Lembrar senha',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () {
            // Lógica para redefinir a senha
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
          child: const Text(
            'Esqueci minha senha',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return FadeTransition(
      opacity: _fadeAnimation ?? const AlwaysStoppedAnimation<double>(1.0),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          'ENTRAR',
          style: AppTextStyles.button.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpRow() {
    return FadeTransition(
      opacity: _fadeAnimation ?? const AlwaysStoppedAnimation<double>(1.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Não tem uma conta?',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CadastroParteUm(),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text(
              'Cadastre-se',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputFormatter? inputFormatter,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatter != null ? [inputFormatter] : null,
        style: AppTextStyles.body1.copyWith(
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.body1.copyWith(
            color: AppColors.textLight,
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(
                width: 45,
                height: 45,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeWidth: 5,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Entrando...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
