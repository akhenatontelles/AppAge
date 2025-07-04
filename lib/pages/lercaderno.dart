import 'package:flutter/material.dart';
import 'registro_semeadura.dart'; // Import da tela de Registro de Semeadura
import 'registro_aquisicao.dart'; // Import da tela de Registro de Aquisição de Insumos
import 'registro_insumos.dart'; // Import da tela de Registro de Insumos

void main() {
  runApp(const LerCadernoApp());
}

class LerCadernoApp extends StatelessWidget {
  const LerCadernoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LerCadernoScreen(token: 'your_token_here'), // Passe o token aqui
    );
  }
}

// ... imports permanecem os mesmos ...

class LerCadernoScreen extends StatelessWidget {
  final String token;

  const LerCadernoScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1ED),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        title: const Text(
          'Caderno de Campo',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registros Disponíveis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 20),
            _buildCourseCard(
              context: context,
              title: 'Registro de Semeadura',
              description: 'Detalhes sobre o processo de semeadura.',
              icon: Icons.grass_rounded,
              color: const Color(0xFF2e604a),
            ),
            const SizedBox(height: 16),
            _buildCourseCard(
              context: context,
              title: 'Registro de Aquisições de Insumos',
              description:
                  'Registro das aquisições de insumos para a produção.',
              icon: Icons.shopping_cart_rounded,
              color: const Color(0xFF2e604a),
            ),
            const SizedBox(height: 16),
            _buildCourseCard(
              context: context,
              title: 'Registro de Uso de Insumos',
              description: 'Uso de insumos durante a produção.',
              icon: Icons.inventory_2_rounded,
              color: const Color(0xFF2e604a),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        if (title == 'Registro de Semeadura') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegistroSemeadura(token: token),
            ),
          );
        } else if (title == 'Registro de Aquisições de Insumos') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegistroAquisicao(token: token),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegistroInsumos(token: token),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
