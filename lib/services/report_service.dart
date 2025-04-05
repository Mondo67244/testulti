import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// **Récupérer tous les rapports**
  Future<List<Map<String, dynamic>>> fetchReports() async {
    try {
      final querySnapshot = await _firestore.collection('reports').get();

      List<Map<String, dynamic>> reports = querySnapshot.docs.map((doc) {
        return {
          'reportId': doc.id,
          'employeeId': doc['reportedBy'] ?? 'Inconnu',
          'date': doc['timestamp']?.toDate().toString() ?? 'Inconnu',
          'report': doc['description'] ?? 'Aucune description',
          'issueType': doc['issueType'] ?? 'Inconnu',
          'location': doc['location'] ?? 'Inconnu',
          'actionType': doc['actionType'] ?? 'Inconnu',
          'equipmentId': doc['equipmentId'] ?? 'Inconnu',
          'status': doc['status'] ?? 'Non défini',
        };
      }).toList();

      // Récupérer les noms des équipements et des employés en parallèle pour améliorer la performance
      await Future.wait(reports.map((report) async {
        // Récupérer le nom de l'équipement
        if (report['equipmentId'] != 'Inconnu') {
          var equipmentDoc = await _firestore
              .collection('equipment')
              .doc(report['equipmentId'])
              .get();
          report['equipmentName'] =
              equipmentDoc.exists ? equipmentDoc['name'] : 'Inconnu';
        } else {
          report['equipmentName'] = 'Inconnu';
        }

        // Récupérer le nom de l'employé
        if (report['employeeId'] != 'Inconnu') {
          var employeeDoc = await _firestore
              .collection('users')
              .doc(report['employeeId'])
              .get();
          report['employeeName'] =
              employeeDoc.exists ? employeeDoc['name'] : 'Inconnu';
        } else {
          report['employeeName'] = 'Inconnu';
        }
      }));

      return reports;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des rapports : $e');
    }
  }

  /// **Créer un nouveau rapport**
  Future<String> createReport({
    required String equipmentId,
    required String description,
    required String status,
    required String location,
    required String issueType,
    required String actionType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non authentifié');

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userName = userDoc.exists
          ? userDoc['name'] ?? 'Utilisateur inconnu'
          : 'Utilisateur inconnu';

      final reportRef = await _firestore.collection('reports').add({
        'equipmentId': equipmentId,
        'description': description,
        'status': status,
        'issueType': issueType,
        'actionType': actionType,
        'location': location,
        'reportedBy': user.uid,
        'reportedByName': userName,
        'timestamp': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return reportRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création du rapport : $e');
    }
  }
}
