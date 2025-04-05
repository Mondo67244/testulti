import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';

class FirestoreInitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initializeCollections() async {
    print("Initialisation des collections Firestore...");

    // Vérifier si l'utilisateur est connecté
    if (_auth.currentUser == null) {
      print(
          "Aucun utilisateur connecté. Création d'un utilisateur temporaire pour l'initialisation...");
      try {
        await _auth.signInAnonymously();
        print("Connexion anonyme réussie pour l'initialisation");
      } catch (e) {
        print("Impossible de se connecter anonymement: $e");
        return;
      }
    }

    try {
      await _createCollection(AppConstants.equipmentCollection, {});

      await _createCollection(AppConstants.reportsCollection, {});

      print("Initialisation des collections terminée avec succès");
    } catch (e) {
      print("Erreur lors de l'initialisation des collections: $e");
    } finally {
      if (_auth.currentUser?.isAnonymous == true) {
        await _auth.signOut();
        print("Déconnexion de l'utilisateur anonyme");
      }
    }
  }

  Future<void> _createCollection(
      String collectionName, Map<String, dynamic> sampleData) async {
    try {
      print("Création/vérification de la collection: $collectionName");

      // Vérifier si la collection existe déjà
      final snapshot =
          await _firestore.collection(collectionName).limit(1).get();

      if (snapshot.docs.isEmpty) {
        print("Collection $collectionName vide, ajout d'un document exemple");
        await _firestore.collection(collectionName).doc('sample_doc').set({
          ...sampleData,
          'createdAt': FieldValue.serverTimestamp(),
          'isSystemGenerated': true,
        });
        print("Document exemple ajouté à $collectionName");
      } else {
        print(
            "Collection $collectionName existe déjà avec ${snapshot.docs.length} documents");
      }
    } catch (e) {
      print("Erreur lors de la création/vérification de $collectionName: $e");
    }
  }
}
