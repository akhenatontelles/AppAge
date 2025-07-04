import 'package:flutter/material.dart';
import '../models/profile_model.dart';

class VisitItem extends StatelessWidget {
  final Visit visit;
  final VoidCallback onTap;

  const VisitItem({super.key, required this.visit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(visit.descricao),
      subtitle: Text('ID: ${visit.id}'),
      onTap: onTap,
    );
  }
}
