import 'package:flutter/material.dart';
import 'package:gestion_parc_informatique/screens/Fournisseur/fournisseur_dashboard.dart';
import '../../constants/app_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Equipment {
  String name;
  String description;
  String serialNumber;
  String type;
  String manufacturer;
  String model;

  Equipment({
    required this.name,
    required this.description,
    required this.serialNumber,
    required this.type,
    required this.manufacturer,
    required this.model,
  });
}

class EquipmentForm extends StatefulWidget {
  const EquipmentForm({Key? key}) : super(key: key);

  @override
  State<EquipmentForm> createState() => _EquipmentFormState();
}

class _EquipmentFormState extends State<EquipmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _modelController = TextEditingController();

  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    // Récupérer l'ID du fournisseur connecté
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  String _selectedType = AppConstants.materials.first;

  bool _isLoading = false;
  String _fabricants = AppConstants.fabricants.first;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _serialNumberController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var children = [
      // Informations générales
      Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: const Text(
          'Informations générales',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4E15C0),
          ),
        ),
      ),
      const SizedBox(height: 16),

      // Nom
      TextFormField(
        controller: _nameController,
        decoration: InputDecoration(
          labelText: 'Nom de l\'équipement *',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          prefixIcon: const Icon(Icons.computer, size: 20),
          labelStyle: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        style: const TextStyle(fontSize: 14),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer un nom';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),

      // Description
      TextFormField(
        controller: _descriptionController,
        decoration: const InputDecoration(
          labelText: 'Description *',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.description),
        ),
        maxLines: 3,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer une description';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),

      // Numéro de série
      TextFormField(
        controller: _serialNumberController,
        decoration: const InputDecoration(
          labelText: 'Numéro de série *',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.qr_code),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer un numéro de série';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),

      const SizedBox(height: 16),

      // Genre
      DropdownButtonFormField<String>(
        value: _selectedType,
        decoration: const InputDecoration(
          labelText: 'Genre *',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.merge_type),
        ),
        items: AppConstants.materials
            .map((material) => DropdownMenuItem(
                  value: material,
                  child: Text(material),
                ))
            .toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedType = value;
            });
          }
        },
      ),
      const SizedBox(height: 16),

      // Informations techniques
      Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: const Text(
          'Informations techniques',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4E15C0),
          ),
        ),
      ),
      const SizedBox(height: 16),

      // Fabriquants
      DropdownButtonFormField<String>(
        value: _fabricants,
        decoration: const InputDecoration(
          labelText: 'Fabricant *',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.maps_home_work_outlined),
        ),
        items: AppConstants.fabricants
            .map((fabricants) => DropdownMenuItem(
                  value: fabricants,
                  child: Text(fabricants),
                ))
            .toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _fabricants = value;
            });
          }
        },
      ),
      const SizedBox(height: 16),

      // Modèle
      TextFormField(
        controller: _modelController,
        decoration: const InputDecoration(
          labelText: 'Modèle *',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.devices),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer un modèle';
          }
          return null;
        },
      ),

      const SizedBox(height: 20,),
      // Bouton de soumission
      ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
        child: const Text(
          'Enregistrer l\'équipement',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      const SizedBox(height: 16),
    ];
    return Scaffold(
          backgroundColor: const Color.fromARGB(255, 240, 232, 255),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Nouvel équipement',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Vérifier si l'utilisateur est connecté
        if (_currentUserId == null) {
          throw Exception('Utilisateur non connecté');
        }

        print('Début de la création de l\'équipement');
        // Créer un nouvel équipement avec l'ID du fournisseur
        final equipmentData = {
          'name': _nameController.text,
          'description': _descriptionController.text,
          'serialNumber': _serialNumberController.text,
          'type': _selectedType,
          'manufacturer': _fabricants,
          'model': _modelController.text,
          'fournisseurId': _currentUserId,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': 'Fournisseur'
        };

        // Ajouter l'équipement à la collection stock
        await FirebaseFirestore.instance.collection('stock').add(equipmentData);
        print('Équipement enregistré avec succès dans la collection stock');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Équipement créé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const FournisseurDashboard()),
            );
          }
        }
      } catch (e, stackTrace) {
        print('Erreur lors de la création de l\'équipement: $e');
        print('Stack trace: $stackTrace');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      print('Formulaire invalide');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
