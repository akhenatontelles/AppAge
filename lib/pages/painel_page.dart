// ignore_for_file: unnecessary_import

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';
import 'profile_page.dart';
import 'caderno_page.dart';
import 'chat_screen.dart';
import 'digitalizados.dart';
import 'lercaderno.dart';
import 'login_page.dart';
import '../services/api_service.dart';
import 'package:flutter/services.dart';
import '../design/app_colors.dart';
import '../design/app_text_styles.dart';
import '../design/widgets/app_card.dart';

class PainelPage extends StatefulWidget {
  final String token;
  final String nome;

  const PainelPage({super.key, required this.token, required this.nome});

  @override
  _PainelPageState createState() => _PainelPageState();
}

class _PainelPageState extends State<PainelPage>
    with SingleTickerProviderStateMixin {
  final ApiService apiService = ApiService('https://api.testelab.me');
  int _unreadMessagesCount = 0;
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
    _fetchUnreadMessages();
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Bem-vindo,",
                style: AppTextStyles.subtitle.copyWith(
                  color: AppColors.primary.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _getFirstAndSecondName(widget.nome),
                style: AppTextStyles.headline2.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildHeaderButton(
                icon: Icons.lock_outline_rounded,
                onTap: _openEditPasswordModal,
              ),
              const SizedBox(width: 8),
              _buildHeaderButton(
                icon: Icons.logout_rounded,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    PageTransition(
                      type: PageTransitionType.fade,
                      child: const LoginPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
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
      ),
    );
  }

  String _getFirstAndSecondName(String fullName) {
    List<String> nameParts = fullName.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0]} ${nameParts[1]}';
    } else {
      return nameParts[0];
    }
  }

  Future<void> _fetchUnreadMessages() async {
    try {
      final messages = await apiService.fetchMessages(widget.token);
      if (mounted) {
        setState(() {
          _unreadMessagesCount =
              messages.where((message) => !message.isRead).length;
        });
      }
    } catch (e) {
      debugPrint("Error fetching unread messages: $e");
    }
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _fetchUnreadMessages();
      }
    });
  }

  void _openChatScreen() {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: ChatScreen(token: widget.token),
        duration: const Duration(milliseconds: 300),
      ),
    ).then((_) {
      if (mounted) {
        _fetchUnreadMessages();
      }
    });
  }

  void _openEditPasswordModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: EditPasswordForm(token: widget.token),
        );
      },
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        _buildGridSection(),
                        const SizedBox(height: 32),
                        _buildActionsList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridSection() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildGridItem(
          'Perfil',
          Icons.person_outline_rounded,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(token: widget.token),
            ),
          ),
        ),
        _buildGridItem(
          'Caderno Digital',
          Icons.book_outlined,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CadernoPage(),
            ),
          ),
        ),
        _buildGridItem(
          'Mensagens',
          Icons.chat_outlined,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(token: widget.token),
            ),
          ),
        ),
        _buildGridItem(
          'Documentos',
          Icons.folder_outlined,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DigitalizadosPage(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridItem(String title, IconData icon, VoidCallback onTap) {
    return AppCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.button.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ações rápidas',
          style: AppTextStyles.headline2.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LerCadernoPage(),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.menu_book_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ler caderno',
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Visualize seus cadernos digitais',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textLight,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    int notificationCount = 0,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 24,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          if (notificationCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                notificationCount.toString(),
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }
}

// EditPasswordForm class
class EditPasswordForm extends StatefulWidget {
  final String token;

  const EditPasswordForm({super.key, required this.token});

  @override
  State<EditPasswordForm> createState() => _EditPasswordFormState();
}

class _EditPasswordFormState extends State<EditPasswordForm> {
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Alterar Senha',
            style: AppTextStyles.headline1.copyWith(
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildPasswordField(
            controller: oldPasswordController,
            label: 'Senha Atual',
            obscureText: _obscureOldPassword,
            onToggleVisibility: () =>
                setState(() => _obscureOldPassword = !_obscureOldPassword),
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            controller: newPasswordController,
            label: 'Nova Senha',
            obscureText: _obscureNewPassword,
            onToggleVisibility: () =>
                setState(() => _obscureNewPassword = !_obscureNewPassword),
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            controller: confirmPasswordController,
            label: 'Confirmar Nova Senha',
            obscureText: _obscureConfirmPassword,
            onToggleVisibility: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.background,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancelar',
                    style: AppTextStyles.button,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Salvar',
                          style: AppTextStyles.button.copyWith(
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: AppTextStyles.body1,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.body1.copyWith(
          color: AppColors.textLight,
        ),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: AppColors.textLight,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (newPasswordController.text != confirmPasswordController.text) {
      _showError('As senhas não coincidem');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _updatePassword(
        oldPassword: oldPasswordController.text,
        newPassword: newPasswordController.text,
      );

      if (success) {
        Navigator.pop(context);
        _showSuccess('Senha alterada com sucesso!');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.testelab.me/update_senha.php'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200 || data['success'] == null) {
        _showError(data['error'] ?? 'Erro ao atualizar senha');
        return false;
      }

      return true;
    } catch (e) {
      _showError('Erro de conexão: $e');
      return false;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
