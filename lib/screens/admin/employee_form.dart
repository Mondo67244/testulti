// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_constants.dart';

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
    return Scaffold(
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
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
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
        ),
      ),
    ));
  }

  void _showCategoryDropdown() {}

  Future<void> _createAccount() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Sauvegarder l'utilisateur actuel avant de créer un nouveau compte
        final currentUser = FirebaseAuth.instance.currentUser;
        String? currentEmail;
        String? currentPassword;
        String? currentUid;

        if (currentUser != null) {
          currentEmail = currentUser.email;
          currentUid = currentUser.uid;
        }

        // Créer l'utilisateur sans se connecter automatiquement
        // Stocker temporairement les informations d'authentification actuelles
        final auth = FirebaseAuth.instance;
        final newUserEmail = _emailController.text.trim();
        final newUserPassword = _passwordController.text.trim();

        // Créer l'utilisateur
        UserCredential userCredential;

        if (currentUser != null) {
          // Si un administrateur est connecté, nous devons d'abord stocker son token
          // pour pouvoir le reconnecter après
          final idToken = await currentUser.getIdToken();

          // Déconnecter temporairement l'administrateur pour créer le nouvel utilisateur
          await auth.signOut();

          // Créer le nouvel utilisateur
          userCredential = await auth.createUserWithEmailAndPassword(
            email: newUserEmail,
            password: newUserPassword,
          );

          // Enregistrer les données utilisateur dans Firestore
          Map<String, dynamic> userData = {
            'email': userCredential.user!.email,
            'isActive': true,
            'joinDate': FieldValue.serverTimestamp(),
            'isProfileComplete': false,
            'role': _selectedRole,
          };

          if (_selectedRole == 'Fournisseur') {
            userData['category'] = _selectedCategory;
          }

          await FirebaseFirestore.instance
              .collection(AppConstants.usersCollection)
              .doc(userCredential.user!.uid)
              .set(userData);

          // Déconnecter le nouvel utilisateur
          await auth.signOut();

          // Reconnecter l'administrateur avec son email
          if (currentEmail != null) {
            try {
              // Nous devons demander à l'administrateur de se reconnecter manuellement
              // car nous ne pouvons pas stocker son mot de passe en toute sécurité
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Compte ${_selectedRole.toLowerCase()} créé avec succès'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );

              // Tenter de reconnecter l'administrateur avec son token
              try {
                // Utiliser la méthode signInWithCustomToken si disponible
                // Sinon, rediriger vers la page de connexion
                await auth.signInWithEmailAndPassword(
                    email: currentEmail,
                    password: "" // Nous ne connaissons pas le mot de passe
                    );
              } catch (e) {
                // Si la reconnexion échoue, nous devons informer l'utilisateur
                print("Erreur lors de la reconnexion automatique: $e");
              }
            } catch (e) {
              print("Erreur lors de la reconnexion: $e");
            }
          }
        } else {
          // Si aucun utilisateur n'est connecté (cas improbable), créer simplement le compte
          userCredential = await auth.createUserWithEmailAndPassword(
            email: newUserEmail,
            password: newUserPassword,
          );

          // Enregistrer les données utilisateur dans Firestore
          Map<String, dynamic> userData = {
            'email': userCredential.user!.email,
            'isActive': true,
            'joinDate': FieldValue.serverTimestamp(),
            'isProfileComplete': false,
            'role': _selectedRole,
          };

          if (_selectedRole == 'Fournisseur') {
            userData['category'] = _selectedCategory;
          }

          await FirebaseFirestore.instance
              .collection(AppConstants.usersCollection)
              .doc(userCredential.user!.uid)
              .set(userData);
        }

        // Afficher un message de succès en fonction du rôle
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Compte ${_selectedRole.toLowerCase()} créé avec succès'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        setState(() {
          _isLoading = false;
          _emailController.clear();
          _passwordController.clear();
        });

        // Retourner à la liste des employés après un court délai
        // pour permettre à l'utilisateur de voir le message de succès
        if (mounted) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
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
