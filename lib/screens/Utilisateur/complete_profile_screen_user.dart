import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_constants.dart';
import '../../services/activity_service.dart';
import '../../models/activity.dart';

class ProfileCompletionScreen extends StatefulWidget {
  ProfileCompletionScreen({Key? key}) : super(key: key);

  @override
  _ProfileCompletionScreenState createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedLocation = '';

  bool _isLoading = false;

  final List<String> _location = [
    'Accueil',
    'Salle de réunion',
    'Bureau RH',
    'Salle de présentation',
    'Atelier de formation',
    'Zone de production',
    'Zone d\'exposition',
    'Laboratoire recherche',
    'Salle d\'attente',
    'Bureau Juridique',
    'Entrepôt d\'équipements',
    'Magasin de fournitures',
    'Bureau du personnel',
  ];

  @override
  void initState() {
    super.initState();
    // Pré-remplir l'email avec celui de l'utilisateur connecté
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      _emailController.text = user.email!;
    }
    _checkUserRole();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    // ignore: unused_local_variable
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
  }

  Future<void> _completeProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Récupérer le rôle de l'utilisateur
          final userDoc = await FirebaseFirestore.instance
              .collection(AppConstants.usersCollection)
              .doc(user.uid)
              .get();
          final role = userDoc.data()?['role'] ?? '';

          // Mettre à jour le document utilisateur
          await FirebaseFirestore.instance
              .collection(AppConstants.usersCollection)
              .doc(user.uid)
              .update({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'location': _selectedLocation,
            'phoneNumber': _phoneController.text.trim(),
            'isActive': true,
            'joinDate': Timestamp.now(),
            'isProfileComplete': true,
            'role': role, // Conserver le rôle
          });

          // Enregistrer l'activité
          final activityService = ActivityService();
          await activityService.logActivity(Activity(
            id: '',
            activityType: ActivityType.employeeCreated.value,
            description:
                'L\'utilisateur ${_nameController.text.trim()} a complété son profil',
            performedBy: user.uid,
            timestamp: DateTime.now(),
            targetId: user.uid,
            targetName: _nameController.text.trim(),
          ));

          // Rediriger vers le tableau de bord approprié
          if (mounted) {
            if (role == 'Utilisateur') {
              Navigator.pushReplacementNamed(
                  context, AppConstants.routeUtilisateurDashboard);
            }
          }
        }
      } catch (e) {
        print('Erreur lors de la complétion du profil: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          backgroundColor: const Color.fromARGB(255, 240, 232, 255),
      appBar: AppBar(
        title: const Text("Modifier votre profil"),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  const Text(
                    'Renseigner les informations à modifier.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const Text(
                    '(La fonction et le département ne sont pas modifiables)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Nom
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom de l\'employé ou entreprise',
                      border: OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer votre nom';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email (non modifiable)
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.email),
                    ),
                    enabled: false, // Non modifiable
                  ),
                  const SizedBox(height: 16),

                  // Numéro de téléphone
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de téléphone',
                      border: OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer votre numéro de téléphone';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  //localisation
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Localisation',
                      border: OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.location_pin),
                    ),
                    value: _selectedLocation.isEmpty ? null : _selectedLocation,
                    hint: const Text('Sélectionnez votre localisation'),
                    items: _location.map((location) {
                      return DropdownMenuItem(
                        value: location,
                        child: Text(location),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLocation = value!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez sélectionner votre localisation';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Bouton de soumission
                  ElevatedButton(
                    onPressed: _isLoading ? null : _completeProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'Envoyer',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}
