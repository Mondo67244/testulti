import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_constants.dart';
import '../../services/activity_service.dart';
import '../../models/activity.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({Key? key}) : super(key: key);

  @override
  _ProfileCompletionScreenState createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedFunction = '';
  String _selectedDepartment = '';
  String _selectedLocation = '';

  bool _isLoading = false;

  List<String> _function = [
    'Administrateur',
    'Ravitailleur',
    'Démarcheur',
    'Livreur',
    'Réparateur',
    'Installateur',
    'Maintenancier',
    'Représentant entreprise',
    'Gestion Globale',
    'Coordonateur',
    'Recruteur',
    'Gestion de carrière',
    'Formateur',
    'Gestion des paies',
    'Relations Sociales',
    'Directeur Marketing',
    'Gestion de campagnes',
    'Gestion des ventes',
    'Gestion partenaires',
    'Chargé rel clients',
    'Directeur Production',
    'Gestion des chaines',
    'Contrôleur Qualité',
    'Directeur Logistique',
    'Gestion des stocks',
    'Gestion des transports',
    'Gestion des distributions',
    'Gestion des fournisseurs',
    'Directeur Informatique',
    'Gestion des systèmes',
    'Support technique',
    'Développeur',
    'Chargé des tests',
    'Directeur Innovation',
    'Gestion des projets',
    'Recherche marchés',
    'DRH clientele',
    'Gestion des clients',
    'Service apres vente',
    'Directeur Juridique',
    'Gestion des contrats',
    'Chargé des affaires',
    'Conseiller juridique',
    'Gestion des contrats',
    'Inspecteur conformité',
  ];

  List<String> _department = [
    'Direction Générale',
    'Ressources Humaines',
    'Finance',
    'Marketing',
    'Production',
    'Logistique',
    'Informatique',
    'Innovation',
    'Service Client',
    'Juridique',
    'Administration',
    'Maintenance',
    'QHSE',
    'Service client',
    'Logistique',
    'Informatique',
    'Commercial',
    'Livraison',
  ];

  List<String> _location = [
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

  Future<void> _checkUserRole() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    if (userDoc.exists && userDoc.data()?['role'] == 'Fournisseur') {
      setState(() {
        _function = ['Ravitailleur', 'Démarcheur', 'Livreur'];
        _department = ['Livraison', 'Logistique', 'Informatique'];
        _selectedDepartment = 'Livraison';
        _location = [
          'Entrepôt d\'équipements',
          'Magasin de fournitures',
          'Bureau du personnel',
          'Salle de présentation',
          'Atelier de formation',
          'Zone de production',
          'Zone d\'exposition',
        ];
        _selectedLocation = 'Entrepôt d\'équipements';
        _selectedFunction = 'Ravitailleur';
      });
    } else if (userDoc.exists && userDoc.data()?['role'] == 'Maintenancier') {
      setState(() {
        _function = ['Réparateur', 'Installateur', 'Maintenancier'];
        _department = ['Maintenance'];
        _selectedDepartment = 'Maintenance';
        _location = [
          'Entrepôt d\'équipements',
          'Zone de production',
          'Atelier de formation',
          'Zone d\'exposition'
        ];
        _selectedLocation = 'Entrepôt d\'équipements';
        _selectedFunction = 'Maintenancier';
      });
    } else if (userDoc.exists && userDoc.data()?['role'] == 'Admin') {
      setState(() {
        _function = ['Administrateur'];
        _department = ['Administration'];
        _selectedDepartment = 'Administration';
        _location = ['Bureau administratif'];
        _selectedLocation = 'Bureau administratif';
        _selectedFunction = 'Administrateur';
      });
    } else if (userDoc.exists && userDoc.data()?['role'] == 'Utilisateur') {
      setState(() {
        _department = [
          'Direction Générale',
          'Ressources Humaines',
          'Finance',
          'Marketing',
          'Production',
          'Logistique',
          'Informatique',
          'Innovation',
          'Service Client',
          'Juridique'
        ];
        _selectedDepartment = 'Direction Générale';
        _function = ['Représentant entreprise', 'Gestion Globale', 'Coordonateur'];
        _selectedFunction = 'Représentant entreprise';
        _location = [
          'Accueil',
          'Salle de réunion',
          'Salle de présentation'
        ];
        _selectedLocation = 'Accueil';
      });
    }
  }

  void _updateFunctions() {
    // Réinitialiser la fonction et la localisation si elles ne sont pas valides pour le nouveau département
    if (!isFunctionValidForDepartment(_selectedFunction, _selectedDepartment)) {
      _selectedFunction = '';
    }
    if (!isLocationValidForDepartment(_selectedLocation, _selectedDepartment)) {
      _selectedLocation = '';
    }

    if (_selectedDepartment == 'Direction Générale') {
      setState(() {
        _function = [
          'Représentant entreprise',
          'Gestion Globale',
          'Coordonateur'
        ];
        _location = [
          'Accueil',
          'Salle de réunion',
          'Salle de présentation',
          'Atelier de formation',
          'Salle d\'attente',
        ];
      });
    } else if (_selectedDepartment == 'Ressources Humaines') {
      setState(() {
        _function = [
          'Recruteur',
          'Gestion de carrière',
          'Formateur',
          'Gestion des paies',
          'Relations Sociales'
        ];
        _location = [
          'Bureau RH',
          'Accueil',
          'Salle de réunion',
          'Salle de présentation',
          'Atelier de formation',
          'Salle d\'attente',
        ];
      });
    } else if (_selectedDepartment == 'Finance') {
      setState(() {
        _function = ['Gestion de comptes', 'Trésorier', 'Auditeur'];
      });
    } else if (_selectedDepartment == 'Marketing') {
      setState(() {
        _function = [
          'Directeur Marketing',
          'Gestion de campagnes',
          'Gestion des ventes',
          'Gestion partenaires',
          'Chargé rel clients'
        ];
        _location = [
          'Accueil',
          'Salle de réunion',
          'Salle de présentation',
          'Atelier de formation',
          'Salle d\'attente',
          'Magasin de fournitures',
          'Bureau du personnel',
        ];
      });
    } else if (_selectedDepartment == 'Production') {
      setState(() {
        _function = [
          'Directeur Production',
          'Gestion des chaines',
          'Contrôleur Qualité'
        ];
        _location = [
          'Entrepôt d\'équipements',
          'Magasin de fournitures',
          'Bureau du personnel',
          'Salle de présentation',
          'Atelier de formation',
          'Zone de production',
          'Zone d\'exposition',
        ];
      });
    } else if (_selectedDepartment == 'Logistique') {
      setState(() {
        _function = [
          'Directeur Logistique',
          'Gestion des stocks',
          'Gestion des transports',
          'Gestion des distributions',
          'Gestion des fournisseurs'
        ];
        _location = [
          'Entrepôt d\'équipements',
          'Magasin de fournitures',
          'Bureau du personnel',
          'Salle de présentation',
          'Atelier de formation',
          'Zone de production',
          'Zone d\'exposition',
        ];
      });
    } else if (_selectedDepartment == 'Informatique') {
      setState(() {
        _function = [
          'Directeur Informatique',
          'Gestion des systèmes',
          'Support technique',
          'Développeur',
          'Chargé des tests'
        ];
        _location = [
          'Accueil',
          'Salle de réunion',
          'Salle de présentation',
          'Atelier de formation',
          'Salle d\'attente',
          'Zone d\'exposition',
          'Bureau du personnel'
        ];
      });
    } else if (_selectedDepartment == 'Innovation') {
      setState(() {
        _function = [
          'Directeur Innovation',
          'Gestion des projets',
          'Recherche marchés'
        ];
        _location = [
          'Accueil',
          'Salle de réunion',
          'Salle de présentation',
          'Atelier de formation',
          'Salle d\'attente',
          'Laboratoire recherche',
          'Zone d\'exposition',
          'Bureau du personnel'
        ];
      });
    } else if (_selectedDepartment == 'Service Client') {
      setState(() {
        _function = [
          'DRH clientele',
          'Gestion des clients',
          'Service apres vente'
        ];
        _location = [
          'Accueil',
          'Salle de réunion',
          'Salle de présentation',
          'Atelier de formation',
          'Salle d\'attente',
          'Bureau du personnel',
          'Zone d\'exposition',
          'Magasin de fournitures',
        ];
      });
    } else if (_selectedDepartment == 'Juridique') {
      setState(() {
        _function = [
          'Directeur Juridique',
          'Gestion des contrats',
          'Chargé des affaires',
          'Conseiller juridique',
          'Gestion des contrats',
          'Inspecteur conformité'
        ];
        _location = [
          'Accueil',
          'Salle de réunion',
          'Salle de présentation',
          'Atelier de formation',
          'Salle d\'attente',
          'Bureau Juridique',
          'Bureau du personnel',
        ];
      });
    }
  }

  bool isFunctionValidForDepartment(String function, String department) {
    // Logique pour vérifier si la fonction est valide pour le département sélectionné
    if (_selectedDepartment == 'Direction Générale') {
      return ['Représentant entreprise', 'Gestion Globale', 'Coordonateur']
          .contains(function);
    } else if (_selectedDepartment == 'Ressources Humaines') {
      return [
        'Recruteur',
        'Gestion de carrière',
        'Formateur',
        'Gestion des paies',
        'Relations Sociales'
      ].contains(function);
    } else if (_selectedDepartment == 'Finance') {
      return ['Gestion de comptes', 'Trésorier', 'Auditeur'].contains(function);
    } else if (_selectedDepartment == 'Marketing') {
      return [
        'Directeur Marketing',
        'Gestion de campagnes',
        'Gestion des ventes',
        'Gestion partenaires',
        'Chargé rel clients'
      ].contains(function);
    } else if (_selectedDepartment == 'Production') {
      return [
        'Directeur Production',
        'Gestion des chaines de production',
        'Contrôleur Qualité'
      ].contains(function);
    } else if (_selectedDepartment == 'Logistique') {
      return [
        'Directeur Logistique',
        'Gestion des stocks',
        'Gestion des transports',
        'Gestion des distributions',
        'Gestion des fournisseurs'
      ].contains(function);
    } else if (_selectedDepartment == 'Informatique') {
      return [
        'Directeur Informatique',
        'Gestion des systèmes',
        'Support technique',
        'Développeur',
        'Chargé des tests'
      ].contains(function);
    } else if (_selectedDepartment == 'Innovation') {
      return [
        'Directeur Innovation',
        'Gestion des projets',
        'Recherche marchés'
      ].contains(function);
    } else if (_selectedDepartment == 'Service Client') {
      return ['DRH clientele', 'Gestion des clients', 'Service apres vente']
          .contains(function);
    } else if (_selectedDepartment == 'Juridique') {
      return [
        'Directeur Juridique',
        'Gestion des contrats',
        'Chargé des affaires',
        'Conseiller juridique',
        'Gestion des contrats',
        'Inspecteur conformité'
      ].contains(function);
    } else {
      return false;
    }
  }

  bool isLocationValidForDepartment(String location, String department) {
    if (department == 'Direction Générale') {
      return ['Accueil', 'Salle de réunion', 'Salle de présentation']
          .contains(location);
    }
    // Ajouter d'autres départements et leurs localisations valides
    return false;
  }

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

  Future<void> _completeProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

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
            'department': _selectedDepartment,
            'function': _selectedFunction,
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
            if (role == 'Fournisseur') {
              Navigator.pushReplacementNamed(
                context,
                AppConstants.routeFournisseurDashboard,
              );
            } else if (role == 'Maintenancier') {
              Navigator.pushReplacementNamed(
                context,
                AppConstants.routeEmployeeDashboard,
              );
            } else if (role == 'Admin') {
              Navigator.pushReplacementNamed(
                context,
                AppConstants.routeAdminDashboard,
              );
            } else if (role == 'Utilisateur') {
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
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          backgroundColor: const Color.fromARGB(255, 240, 232, 255),
      appBar: AppBar(
        title: const Text("Compléter votre profil"),
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
                    'Bienvenue ! Veuillez compléter votre profil pour continuer.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Nom
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom de l\'employé ou entreprise',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
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
                      prefixIcon: Icon(Icons.email),
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
                      prefixIcon: Icon(Icons.phone),
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

                  // Département
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Département',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    value: _selectedDepartment.isEmpty
                        ? null
                        : _selectedDepartment,
                    hint: const Text('Sélectionnez votre département'),
                    items: _department.map((department) {
                      return DropdownMenuItem(
                        value: department,
                        child: Text(department),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDepartment = value!;
                        _updateFunctions();
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez sélectionner un département';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Fonction
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Fonction',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work_outline),
                    ),
                    value: _selectedFunction.isEmpty ? null : _selectedFunction,
                    hint: const Text('Sélectionnez votre fonction'),
                    items: _function.map((function) {
                      return DropdownMenuItem(
                        value: function,
                        child: Text(function),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFunction = value!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez sélectionner une fonction';
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
                      prefixIcon: Icon(Icons.location_pin),
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
