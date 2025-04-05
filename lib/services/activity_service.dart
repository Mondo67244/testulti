import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity.dart';
import '../constants/app_constants.dart';
import '../models/equipment.dart';
import '../models/employee.dart';
import '../models/maintenance_task.dart';

class ActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupérer toutes les activités récentes
  Stream<List<Activity>> getActivities() {
    return _firestore
        .collection(AppConstants.activitiesCollection)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          final activities = snapshot.docs
              .map((doc) => Activity.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
          
          print('Activités récupérées: ${activities.length}');
          if (activities.isNotEmpty) {
            print('Première activité: ${activities.first.description}');
          }
          
          return activities;
        });
  }

  // Récupérer les activités par catégorie
  Stream<List<Activity>> getActivitiesByCategory(String category) {
    return _firestore
        .collection(AppConstants.activitiesCollection)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          final allActivities = snapshot.docs
              .map((doc) => Activity.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
          
          // Filtrer les activités par catégorie après les avoir récupérées
          return allActivities.where((activity) => activity.category == category).toList();
        });
  }

  // Récupérer les activités liées à un objet spécifique
  Stream<List<Activity>> getActivitiesByTargetId(String targetId) {
    return _firestore
        .collection(AppConstants.activitiesCollection)
        .where('targetId', isEqualTo: targetId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Activity.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Ajouter une nouvelle activité
  Future<void> logActivity(Activity activity) async {
    try {
      print("Tentative d'enregistrement d'activité: ${activity.description}");
      print("Données de l'activité: ${activity.toJson()}");
      
      // Ajouter un timestamp serveur pour garantir la cohérence
      final activityData = activity.toJson();
      activityData['timestamp'] = FieldValue.serverTimestamp();
      
      final docRef = await _firestore
        .collection(AppConstants.activitiesCollection)
        .add(activityData)
        .timeout(const Duration(seconds: 5));
      
      print("Activité enregistrée avec succès, ID: ${docRef.id}");
    } catch (e, stackTrace) {
      print("Erreur lors de l'enregistrement de l'activité: $e");
      print("Stack trace: $stackTrace");
    }
  }

  // Équipements
  Future<void> logEquipmentCreated(Equipment equipment, String performedBy) async {
    print("Tentative d'enregistrement de la création d'équipement: ${equipment.name}");
    final activity = Activity(
      id: '',
      activityType: ActivityType.equipmentCreated.value,
      description: 'Création de l\'équipement "${equipment.name}"',
      performedBy: performedBy,
      timestamp: DateTime.now(),
      targetId: equipment.id,
      targetName: equipment.name,
      details: {
        'category': equipment.category,
        'state': equipment.state,
        'status': equipment.status,
      },
    );
    await logActivity(activity);
  }

  Future<void> logEquipmentUpdated(Equipment equipment, String performedBy, Map<String, dynamic> changedFields) async {
    final activity = Activity(
      id: '',
      activityType: ActivityType.equipmentUpdated.value,
      description: 'Modification de l\'équipement "${equipment.name}"',
      performedBy: performedBy,
      timestamp: DateTime.now(),
      targetId: equipment.id,
      targetName: equipment.name,
      details: {
        'changedFields': changedFields,
      },
    );
    await logActivity(activity);
  }

  Future<void> logEquipmentDeleted(Equipment equipment, String performedBy) async {
    final activity = Activity(
      id: '',
      activityType: ActivityType.equipmentDeleted.value,
      description: 'Suppression de l\'équipement "${equipment.name}"',
      performedBy: performedBy,
      timestamp: DateTime.now(),
      targetId: equipment.id,
      targetName: equipment.name,
    );
    await logActivity(activity);
  }

  Future<void> logEquipmentStateChanged(Equipment equipment, String performedBy, String oldState, String newState) async {
    final activity = Activity(
      id: '',
      activityType: ActivityType.equipmentStateChanged.value,
      description: 'Changement d\'état de l\'équipement "${equipment.name}" de "$oldState" à "$newState"',
      performedBy: performedBy,
      timestamp: DateTime.now(),
      targetId: equipment.id,
      targetName: equipment.name,
      details: {
        'oldState': oldState,
        'newState': newState,
      },
    );
    await logActivity(activity);
  }

  // Employés
  Future<void> logEmployeeCreated(Employee employee, String performedBy) async {
    final activity = Activity(
      id: '',
      activityType: ActivityType.employeeCreated.value,
      description: 'Création de l\'employé "${employee.name}"',
      performedBy: performedBy,
      timestamp: DateTime.now(),
      targetId: employee.id,
      targetName: employee.name,
      details: {
        'function': employee.function,
        'department': employee.department,
        'role': employee.role,
      },
    );
    await logActivity(activity);
  }

  Future<void> logEmployeeLogin(Employee employee) async {
    final activity = Activity(
      id: '',
      activityType: ActivityType.employeeLogin.value,
      description: 'Connexion de l\'employé "${employee.name}"',
      performedBy: employee.name,
      timestamp: DateTime.now(),
      targetId: employee.id,
      targetName: employee.name,
    );
    await logActivity(activity);
  }

  Future<void> logEmployeeLogout(Employee employee) async {
    final activity = Activity(
      id: '',
      activityType: ActivityType.employeeLogout.value,
      description: 'Déconnexion de l\'employé "${employee.name}"',
      performedBy: employee.name,
      timestamp: DateTime.now(),
      targetId: employee.id,
      targetName: employee.name,
    );
    await logActivity(activity);
  }

  // Tâches
  Future<void> logTaskCreated(MaintenanceTask task, String performedBy) async {
    final activity = Activity(
      id: '',
      activityType: ActivityType.taskCreated.value,
      description: 'Création de la tâche "${task.title}"',
      performedBy: performedBy,
      timestamp: DateTime.now(),
      targetId: task.id,
      targetName: task.title,
      details: {
        'status': task.status,
        'assignedTo': task.assignedTo,
        'dueDate': task.dueDate.toIso8601String(),
      },
    );
    await logActivity(activity);
  }

  Future<void> logTaskAssigned(MaintenanceTask task, String performedBy, String oldAssignee, String newAssignee) async {
    final activity = Activity(
      id: '',
      activityType: ActivityType.taskAssigned.value,
      description: 'Assignation de la tâche "${task.title}" de "$oldAssignee" à "$newAssignee"',
      performedBy: performedBy,
      timestamp: DateTime.now(),
      targetId: task.id,
      targetName: task.title,
      details: {
        'oldAssignee': oldAssignee,
        'newAssignee': newAssignee,
      },
    );
    await logActivity(activity);
  }

  Future<void> logTaskStatusChanged(MaintenanceTask task, String performedBy, String oldStatus, String newStatus) async {
    final activity = Activity(
      id: '',
      activityType: ActivityType.taskStatusChanged.value,
      description: 'Changement de statut de la tâche "${task.title}" de "$oldStatus" à "$newStatus"',
      performedBy: performedBy,
      timestamp: DateTime.now(),
      targetId: task.id,
      targetName: task.title,
      details: {
        'oldStatus': oldStatus,
        'newStatus': newStatus,
      },
    );
    await logActivity(activity);
  }

  // Rapports
  Future<void> logReportSubmitted(String reportId, String reportTitle, String performedBy) async {
    final activity = Activity(
      id: '',
      activityType: ActivityType.reportSubmitted.value,
      description: 'Soumission du rapport "$reportTitle"',
      performedBy: performedBy,
      timestamp: DateTime.now(),
      targetId: reportId,
      targetName: reportTitle,
    );
    await logActivity(activity);
  }

  Future<void> logReportStatusChanged(String reportId, String reportTitle, String performedBy, String oldStatus, String newStatus) async {
    final activity = Activity(
      id: '',
      activityType: ActivityType.reportStatusChanged.value,
      description: 'Changement de statut du rapport "$reportTitle" de "$oldStatus" à "$newStatus"',
      performedBy: performedBy,
      timestamp: DateTime.now(),
      targetId: reportId,
      targetName: reportTitle,
      details: {
        'oldStatus': oldStatus,
        'newStatus': newStatus,
      },
    );
    await logActivity(activity);
  }

  // Supprimer une activité
  Future<void> deleteActivity(String id) async {
    await _firestore
        .collection(AppConstants.activitiesCollection)
        .doc(id)
        .delete();
  }

  // Supprimer toutes les activités liées à un objet
  Future<void> deleteActivitiesByTargetId(String targetId) async {
    final activities = await _firestore
        .collection(AppConstants.activitiesCollection)
        .where('targetId', isEqualTo: targetId)
        .get();
    
    final batch = _firestore.batch();
    for (var doc in activities.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  // Récupérer toutes les activités récentes (version Future)
  Future<List<Activity>> getActivitiesFuture() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.activitiesCollection)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();
      
      final activities = snapshot.docs
          .map((doc) => Activity.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      
      print('Future - Activités récupérées: ${activities.length}');
      if (activities.isNotEmpty) {
        print('Future - Première activité: ${activities.first.description}');
      }
      
      return activities;
    } catch (e) {
      print('Erreur lors de la récupération des activités: $e');
      rethrow;
    }
  }

  // Récupérer les activités par catégorie (version Future)
  Future<List<Activity>> getActivitiesByCategoryFuture(String category) async {
    try {
      print('Début de getActivitiesByCategoryFuture pour la catégorie: $category');
      
      final snapshot = await _firestore
          .collection(AppConstants.activitiesCollection)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();
      
      print('Nombre de documents récupérés: ${snapshot.docs.length}');
      
      // Vérifier si les documents sont valides
      for (var doc in snapshot.docs) {
        print('Document ID: ${doc.id}');
        print('Document data: ${doc.data()}');
      }
      
      final allActivities = snapshot.docs
          .map((doc) {
            try {
              return Activity.fromJson({...doc.data(), 'id': doc.id});
            } catch (e) {
              print('Erreur lors de la conversion du document ${doc.id}: $e');
              // Retourner une activité par défaut en cas d'erreur
              return Activity(
                id: doc.id,
                activityType: 'systemAction',
                description: 'Erreur lors du chargement de l\'activité',
                performedBy: 'Système',
                timestamp: DateTime.now(),
                targetId: null,
                targetName: null,
                details: {'error': e.toString()},
              );
            }
          })
          .toList();
      
      print('Nombre d\'activités converties: ${allActivities.length}');
      
      // Filtrer les activités par catégorie après les avoir récupérées
      final filteredActivities = category == 'all'
          ? allActivities
          : allActivities.where((activity) => activity.category == category).toList();
      
      print('Future - Activités filtrées ($category): ${filteredActivities.length}');
      
      return filteredActivities;
    } catch (e) {
      print('Erreur lors de la récupération des activités par catégorie: $e');
      // Retourner une liste vide en cas d'erreur
      return [];
    }
  }
} 