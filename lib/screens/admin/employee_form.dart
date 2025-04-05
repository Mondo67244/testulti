import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmployeeForm extends StatefulWidget {
  const EmployeeForm({Key? key}) : super(key: key);

  @override
  State<EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends State<EmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Maintenancier';
  String _selectedCategory = 'Sécurité';

  final List<String> _roles = [
    'Maintenancier',
    'Fournisseur',
    'Utilisateur',
    'Admin'
  ];
  
  final List<String> _categories = ['Sécurité', 'Bureau', 'Échange', 'Réseau'];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 240, 232, 255),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Créer un utilisateur'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(
                height: 50,
              ),
              const Text(
                'Veuillez entrer les informations du nouvel utilisateur',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 50,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Veuillez entrer l'email";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un mot de passe';
                  }
                  if (value.length < 6) {
                    return 'Le mot de passe doit contenir au moins 6 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rôle',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                ),
                items: _roles.map((role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                    // Afficher le dropdown de catégorie si le rôle est Fournisseur
                    if (_selectedRole == 'Fournisseur') {
                      _showCategoryDropdown();
                    }
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner un rôle';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_selectedRole == 'Fournisseur') ...[
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Choix de catégorie',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez sélectionner une catégorie';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                  onPressed: _isLoading ? null : _createAccount,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Créer le compte')),
            ],
          ),
        ),
      ),
    ),);
  }

  void _showCategoryDropdown() {}

  Future<void> _createAccount() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Sauvegarder les informations de l'utilisateur administrateur actuel
        final FirebaseAuth auth = FirebaseAuth.instance;
        final User? adminUser = auth.currentUser;
        
        if (adminUser == null) {
          throw Exception('Aucun administrateur connecté');
        }

        // Stocker les informations d'authentification de l'administrateur
        final String adminEmail = adminUser.email!;
        final prefs = await SharedPreferences.getInstance();
        final String? adminPassword = await prefs.getString('admin_password');
        
        // Créer le nouvel utilisateur avec un autre instance de FirebaseAuth
        final newUserCredential = await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Récupérer l'UID du nouvel utilisateur pour l'utiliser dans Firestore
        final String newUserUid = newUserCredential.user!.uid;

        Map<String, dynamic> userData = {
          'email': newUserCredential.user!.email,
          'isActive': true,
          'joinDate': FieldValue.serverTimestamp(),
          'isProfileComplete': false,
          'role': _selectedRole,
        };

        if (_selectedRole == 'Fournisseur') {
          userData['category'] = _selectedCategory;
        }

        // Enregistrer les données utilisateur dans Firestore
        await FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .doc(newUserUid)
            .set(userData);

        // Déconnecter immédiatement le nouvel utilisateur
        await auth.signOut();

        // Reconnecter l'administrateur
        if (adminPassword != null) {
          try {
            await auth.signInWithEmailAndPassword(
              email: adminEmail,
              password: adminPassword,
            );
            
            // Afficher le message de succès approprié
            String roleMessage = '';
            switch (_selectedRole) {
              case 'Fournisseur':
                roleMessage = 'Compte fournisseur créé avec succès';
                break;
              case 'Maintenancier':
                roleMessage = 'Compte maintenancier créé avec succès';
                break;
              case 'Utilisateur':
                roleMessage = 'Compte utilisateur créé avec succès';
                break;
              case 'Admin':
                roleMessage = 'Compte administrateur créé avec succès';
                break;
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(roleMessage),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          } catch (e) {
            // Si la reconnexion échoue, afficher un message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Veuillez vous reconnecter en tant qu\'administrateur'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
            Navigator.of(context).pop(); // Retourner à l'écran de connexion
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Compte créé avec succès. Veuillez vous reconnecter.'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 5),
            ),
          );
          Navigator.of(context).pop(); // Retourner à l'écran de connexion
        }

        setState(() {
          _isLoading = false;
          _emailController.clear();
          _passwordController.clear();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création du compte: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
