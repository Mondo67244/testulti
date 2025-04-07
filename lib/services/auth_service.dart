// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/employee.dart';
import '../constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/activity_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ActivityService _activityService = ActivityService();

  User? get currentUser => _auth.currentUser;

  // Récupérer l'employé actuellement connecté
  // Convertir le User Firebase en notre modèle Employee
  Future<Employee?> _userFromFirebase(User? firebaseUser) async {
    if (firebaseUser == null) return null;

    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(firebaseUser.uid)
        .get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    final role = data['role'] ?? '';

    // Logique pour maintenir le rôle de l'utilisateur
    if (role == AppConstants.roleAdmin) {
      // Logique pour l'administrateur
    } else if (role == AppConstants.roleTechnician) {
      // Logique pour le technicien
    } else if (role == AppConstants.roleSupplier) {
    } else if (role == AppConstants.roleUtilisateur) {}

    return Employee(
      id: firebaseUser.uid,
      name: data['name'] ?? '',
      email: firebaseUser.email ?? '',
      role: role,
      location: data['location'] ?? '',
      function: data['function'] ?? '',
      department: data['department'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      isActive: data['isActive'] ?? true,
      joinDate: (data['joinDate'] as Timestamp).toDate(),
    );
  }

// Récupérer l'employé actuellement connecté
  Future<Employee?> getCurrentEmployee() async {
    return await getCurrentUser();
  }
  
  // Créer un utilisateur sans se connecter automatiquement
  Future<UserCredential> createUserWithoutSigningIn(String email, String password) async {
    // Sauvegarder l'utilisateur actuel
    final currentUser = _auth.currentUser;
    
    // Créer le nouvel utilisateur
    final UserCredential newUserCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Si un utilisateur était connecté avant, le reconnecter
    if (currentUser != null) {
      // Déconnecter le nouvel utilisateur
      await _auth.signOut();
      
      // Reconnecter l'utilisateur précédent
      try {
        // Nous ne pouvons pas nous reconnecter avec le mot de passe car il n'est pas stocké
        // Nous utilisons donc un token de persistance pour maintenir la session
        await _auth.signInWithCustomToken(await _getCustomToken(currentUser.uid));
      } catch (e) {
        print("Erreur lors de la reconnexion: $e");
        // En cas d'échec, nous informons l'utilisateur qu'il doit se reconnecter manuellement
      }
    }
    
    return newUserCredential;
  }
  
  // Méthode pour obtenir un token personnalisé (cette méthode nécessiterait une fonction Cloud)
  Future<String> _getCustomToken(String uid) async {
    // Cette méthode devrait appeler une fonction Cloud Firebase pour générer un token
    // Pour l'instant, nous retournons une chaîne vide car cela nécessite une configuration côté serveur
    // Dans une implémentation réelle, vous devriez appeler une fonction Cloud
    throw UnimplementedError('Cette fonctionnalité nécessite une fonction Cloud Firebase');
  }

// Stream de l'état d'authentification
  Stream<Employee?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return await _userFromFirebase(user);
    });
  }

// Connexion avec email et mot de passe
  Future<void> signInWithEmailPassword(
    String email,
    String password,
    BuildContext context,
  ) async {
    try {
      print("Attempting login with: $email");

      if (!context.mounted) {
        print("Context not mounted before login");
        return;
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Check if user document exists in Firestore
        try {
          final userDoc = await _firestore
              .collection(AppConstants.usersCollection)
              .doc(userCredential.user!.uid)
              .get();

          if (!userDoc.exists) {
            // First time login - redirect to complete profile
            if (context.mounted) {
              Navigator.pushReplacementNamed(
                context,
                AppConstants.routeCompleteProfile,
              );
            }
            return; // Exit early to prevent further processing
          }

          // User document exists, check if name field is present
          final userData = userDoc.data();
          if (userData == null || userData['name'] == null) {
            // Name field missing, redirect to complete profile
            if (context.mounted) {
              Navigator.pushReplacementNamed(
                context,
                AppConstants.routeCompleteProfile,
              );
            }
            return; // Exit early to prevent further processing
          }

          // Get user role and redirect accordingly
          final role = userData['role']?.toString() ?? '';
          print("User role: $role");

          if (role.isEmpty) {
            throw Exception('User role missing in Firestore document');
          }

          if (context.mounted) {
            if (role == AppConstants.roleAdmin) {
              Navigator.pushReplacementNamed(
                context,
                AppConstants.routeAdminDashboard,
              );
            } else if (role == AppConstants.roleSupplier) {
              Navigator.pushReplacementNamed(
                context,
                AppConstants.routeFournisseurDashboard,
              );
            } else if (role == AppConstants.roleTechnician) {
              Navigator.pushReplacementNamed(
                context,
                AppConstants.routeEmployeeDashboard,
              );
            } else if (role == AppConstants.roleUtilisateur) {
              Navigator.pushReplacementNamed(
                context,
                AppConstants.routeUtilisateurDashboard,
              );
            }
          }

          // Log login activity
          try {
            final employee = await _userFromFirebase(userCredential.user!);
            if (employee != null) {
              await _logLoginActivityInBackground(employee);
            }
          } catch (e) {
            print("Error logging login activity: $e");
          }
        } catch (e) {
          print("Error checking user document: $e");
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error checking user profile: $e')),
            );
          }
        }
      }
    } catch (e) {
      print("Login error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      rethrow; // Rethrow to be caught by the login screen
    }
  }

  // Méthode pour enregistrer l'activité de connexion en arrière-plan
  Future<void> _logLoginActivityInBackground(Employee user) async {
    try {
      await _activityService.logEmployeeLogin(user);
      print("Activité de connexion enregistrée pour: ${user.name}");
    } catch (e) {
      print("Erreur lors de l'enregistrement de l'activité de connexion: $e");
      // Ignorer l'erreur pour ne pas bloquer le flux principal
    }
  }

  // Déconnexion
  // ...

  Future<void> signOut(BuildContext context) async {
    await _auth.signOut();
    // Optionally, clear user data from SharedPreferences
    await SharedPreferences.getInstance().then((prefs) {
      prefs.remove('user_data');
    });
    // Redirect to login page
    Navigator.pushReplacementNamed(context, AppConstants.routeLogin);
  }

  // Récupérer l'utilisateur actuellement connecté
  Future<Employee?> getCurrentUser() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        print("getCurrentUser: Aucun utilisateur Firebase connecté");
        return null;
      }

      print(
          "getCurrentUser: Utilisateur Firebase connecté: ${firebaseUser.email}, UID: ${firebaseUser.uid}");

      // Essayer de récupérer l'utilisateur depuis Firestore
      Employee? employee = await _userFromFirebase(firebaseUser);

      // Si l'utilisateur n'existe pas dans Firestore mais est authentifié
      if (employee == null) {
        print(
            "getCurrentUser: Utilisateur authentifié mais document Firestore non trouvé");
      }

      return employee;
    } catch (e) {
      print("Erreur dans getCurrentUser: $e");
      print("Stack trace: ${StackTrace.current}");
      return null;
    }
  }

  Future<String> createUserWithEmailAndPasswordRest({
    required String email,
    required String password,
    required String name,
    required String role,
    required String location,
    required String function,
    required String department,
    required String phoneNumber,
  }) async {
    try {
      print('Début de la création du compte');

      // Créer le compte avec Firebase Auth
      UserCredential userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (userCredential.user == null) {
          throw Exception('Échec de la création du compte utilisateur');
        }
      } catch (e) {
        print('Erreur lors de la création du compte Firebase Auth: $e');
        rethrow;
      }

      if (userCredential.user == null) {
        throw Exception('Échec de la création du compte utilisateur');
      }

      final uid = userCredential.user!.uid;
      print('Compte Firebase Auth créé avec succès, UID: $uid');

      // Stocker les informations dans la collection pending_users
      final pendingUserData = {
        'id': uid,
        'name': name,
        'email': email,
        'role': role,
        'location': location,
        'function': function,
        'department': department,
        'phoneNumber': phoneNumber,
        'isActive': true,
        'isAvailable': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'Admin',
      };

      print('Stockage des informations dans pending_users...');
      print('Données utilisateur: $pendingUserData');

      try {
        await _firestore
            .collection(AppConstants.pendingUsersCollection)
            .doc(uid)
            .set(pendingUserData);
        print('Informations stockées avec succès dans pending_users');
      } catch (e) {
        print('Erreur lors du stockage dans pending_users: $e');
        // Supprimer le compte Firebase Auth si le stockage échoue
        await userCredential.user?.delete();
        rethrow;
      }

      return uid;
    } catch (e, stackTrace) {
      print('Erreur lors de la création du compte: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Méthode pour créer le document utilisateur lors de la première connexion
  Future<void> createUserDocumentOnFirstLogin(User firebaseUser) async {
    try {
      print(
          'Vérification des informations en attente pour: ${firebaseUser.uid}');

      // Vérifier si l'utilisateur existe dans pending_users
      final pendingDoc = await _firestore
          .collection(AppConstants.pendingUsersCollection)
          .doc(firebaseUser.uid)
          .get();

      if (pendingDoc.exists) {
        print(
            'Informations en attente trouvées, création du document utilisateur');

        // Récupérer les données en attente
        final pendingData = pendingDoc.data()!;

        // Créer le document dans la collection users
        final userData = {
          ...pendingData,
          'joinDate': FieldValue.serverTimestamp(),
          'isActive': true,
          'isAvailable': true
        };

        // Créer le document dans users
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(firebaseUser.uid)
            .set(userData);

        // Supprimer le document de pending_users
        await pendingDoc.reference.delete();

        print(
            'Document utilisateur créé avec succès et document pending supprimé');
      } else {
        print('Aucune information en attente trouvée pour cet utilisateur');
      }
    } catch (e, stackTrace) {
      print('Erreur lors de la création du document utilisateur: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Erreur de connexion: $e');
      return null;
    }
  }

  Future<void> checkUserRole() async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Logique pour vérifier le role
    }
  }
}