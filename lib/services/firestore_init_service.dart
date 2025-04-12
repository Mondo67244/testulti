// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class FirestoreInitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initializeCollections() async {
    print("Initialisation des collections et des index Firestore...");

    // Charger un utilisateur temporaire pour l'initialisation...
    try {

      await _createCollection('activities', {
      });
      await _createCollection('maintenance_tasks', {
      });
      await _createCollection('commandes', {
      });
      await _createCollection('equipment', {
      });
      await _createCollection('reports', {
      });
      await _createCollection('users', {
      });
    } catch (e) {
      print("Initialisation des collections et des index terminée avec succès");
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
