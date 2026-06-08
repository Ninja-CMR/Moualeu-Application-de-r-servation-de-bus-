import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/agency_model.dart';

class AddAgencyScreen extends StatefulWidget {
  const AddAgencyScreen({super.key});

  @override
  State<AddAgencyScreen> createState() => _AddAgencyScreenState();
}

class _AddAgencyScreenState extends State<AddAgencyScreen> {
  final _db = DatabaseService();
  final _nameController = TextEditingController();
  final _logoUrlController = TextEditingController();

  void _saveAgency() async {
    final agency = AgencyModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Simple ID generator
      name: _nameController.text.trim(),
      logoUrl: _logoUrlController.text.trim().isEmpty ? null : _logoUrlController.text.trim(),
    );

    try {
      await _db.addAgency(agency);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Agence créée")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter une Agence")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Nom de l'agence")),
            TextField(controller: _logoUrlController, decoration: const InputDecoration(labelText: "URL du Logo")),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: _saveAgency, child: const Text("Créer l'agence")),
          ],
        ),
      ),
    );
  }
}
