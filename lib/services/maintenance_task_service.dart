import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/maintenance_task.dart';
import '../constants/app_constants.dart';
import '../services/activity_service.dart';
import '../models/activity.dart';

class MaintenanceTaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ActivityService _activityService = ActivityService();

  // Récupérer toutes les tâches
  Stream<List<MaintenanceTask>> getTasks() {
    return _firestore
        .collection(AppConstants.maintenanceTasksCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaintenanceTask.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Récupérer les tâches d'un employé spécifique
  Stream<List<MaintenanceTask>> getTasksByEmployee(String employeeId) {
    return _firestore
        .collection(AppConstants.maintenanceTasksCollection)
        .where('assignedTo', isEqualTo: employeeId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaintenanceTask.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Récupérer les tâches d'un employé par statut
  Stream<List<MaintenanceTask>> getTasksByStatusAndEmployee(String status, String employeeId) {
    print("DEBUG SERVICE: Requête Firestore avec status='$status' et employeeId='$employeeId'");
    return _firestore
        .collection(AppConstants.maintenanceTasksCollection)
        .where('assignedTo', isEqualTo: employeeId)
        .where('status', isEqualTo: status)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) {
          print("DEBUG SERVICE: Nombre de tâches récupérées: ${snapshot.docs.length}");
          if (snapshot.docs.isEmpty) {
            print("DEBUG SERVICE: Aucune tâche trouvée pour ces critères");
          } else {
            for (var doc in snapshot.docs) {
              print("DEBUG SERVICE: Tâche trouvée - ID: ${doc.id}, Titre: ${doc.data()['title'] ?? 'Sans titre'}, Status: ${doc.data()['status'] ?? 'Status inconnu'}");
            }
          }
          return snapshot.docs
              .map((doc) => MaintenanceTask.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Récupérer toutes les tâches d'un employé, pour des raisons de débogage
  Stream<List<MaintenanceTask>> getAllTasksForEmployee(String employeeId) {
    print("DEBUG SERVICE: Requête Firestore pour toutes les tâches avec employeeId='$employeeId'");
    return _firestore
        .collection(AppConstants.maintenanceTasksCollection)
        .where('assignedTo', isEqualTo: employeeId)
        .snapshots()
        .map((snapshot) {
          print("DEBUG SERVICE: Nombre total de tâches pour l'employé: ${snapshot.docs.length}");
          if (snapshot.docs.isEmpty) {
            print("DEBUG SERVICE: Aucune tâche trouvée pour cet employé");
          } else {
            for (var doc in snapshot.docs) {
              print("DEBUG SERVICE: Tâche trouvée - ID: ${doc.id}, Titre: ${doc.data()['title'] ?? 'Sans titre'}, Status: ${doc.data()['status'] ?? 'Status inconnu'}");
            }
          }
          return snapshot.docs
              .map((doc) => MaintenanceTask.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Ajouter une tâche
  Future<void> addTask(MaintenanceTask task, String performedBy) async {
    await _firestore
        .collection(AppConstants.maintenanceTasksCollection)
        .doc(task.id)
        .set(task.toMap());
        
    // Enregistrer l'activité
    await _activityService.logTaskCreated(task, performedBy);
  }

  // Mettre à jour une tâche
  Future<void> updateTask(MaintenanceTask task, String performedBy, MaintenanceTask oldTask) async {
    await _firestore
        .collection(AppConstants.maintenanceTasksCollection)
        .doc(task.id)
        .update(task.toMap());
        
    // Vérifier si le statut a changé
    if (oldTask.status != task.status) {
      await _activityService.logTaskStatusChanged(
        task, 
        performedBy, 
        oldTask.status, 
        task.status
      );
    }
    
    // Vérifier si l'assignation a changé
    if (oldTask.assignedTo != task.assignedTo) {
      await _activityService.logTaskAssigned(
        task, 
        performedBy, 
        oldTask.assignedTo, 
        task.assignedTo
      );
    }
  }

  // Supprimer une tâche
  Future<void> deleteTask(String id, String performedBy) async {
    // Récupérer la tâche avant de la supprimer
    final docSnapshot = await _firestore
        .collection(AppConstants.maintenanceTasksCollection)
        .doc(id)
        .get();
        
    if (docSnapshot.exists) {
      final task = MaintenanceTask.fromMap(docSnapshot.data()!, id);
      
      // Supprimer la tâche
      await _firestore
          .collection(AppConstants.maintenanceTasksCollection)
          .doc(id)
          .delete();
          
      // Enregistrer l'activité
      await _activityService.logActivity(
        Activity(
          id: '',
          activityType: ActivityType.taskDeleted.value,
          description: 'Suppression de la tâche "${task.title}"',
          performedBy: performedBy,
          timestamp: DateTime.now(),
          targetId: task.id,
          targetName: task.title,
        )
      );
    }
  }
  
  // Changer le statut d'une tâche
  Future<void> changeTaskStatus(String id, String newStatus, String performedBy) async {
    // Récupérer la tâche avant la mise à jour
    final docSnapshot = await _firestore
        .collection(AppConstants.maintenanceTasksCollection)
        .doc(id)
        .get();
        
    if (docSnapshot.exists) {
      final task = MaintenanceTask.fromMap(docSnapshot.data()!, id);
      final oldStatus = task.status;
      
      // Mettre à jour le statut
      await _firestore
          .collection(AppConstants.maintenanceTasksCollection)
          .doc(id)
          .update({'status': newStatus});
          
      // Mettre à jour la date d'achèvement si la tâche est terminée
      if (newStatus == 'completed') {
        await _firestore
            .collection(AppConstants.maintenanceTasksCollection)
            .doc(id)
            .update({'completionDate': FieldValue.serverTimestamp()});
      }
      
      // Enregistrer l'activité
      await _activityService.logTaskStatusChanged(
        task.copyWith(status: newStatus), 
        performedBy, 
        oldStatus, 
        newStatus
      );
    }
  }
  
  // Assigner une tâche à un employé
  Future<void> assignTask(String id, String employeeId, String performedBy) async {
    // Récupérer la tâche avant la mise à jour
    final docSnapshot = await _firestore
        .collection(AppConstants.maintenanceTasksCollection)
        .doc(id)
        .get();
        
    if (docSnapshot.exists) {
      final task = MaintenanceTask.fromMap(docSnapshot.data()!, id);
      final oldAssignee = task.assignedTo;
      
      // Mettre à jour l'assignation
      await _firestore
          .collection(AppConstants.maintenanceTasksCollection)
          .doc(id)
          .update({'assignedTo': employeeId});
          
      // Enregistrer l'activité
      await _activityService.logTaskAssigned(
        task.copyWith(assignedTo: employeeId), 
        performedBy, 
        oldAssignee, 
        employeeId
      );
    }
  }
} 