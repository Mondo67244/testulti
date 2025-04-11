import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/employee.dart';
import '../constants/app_constants.dart';
import '../services/activity_service.dart';
import '../models/activity.dart';

class EmployeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ActivityService _activityService = ActivityService();

  // Récupérer tous les employés
  Stream<List<Employee>> getEmployees() {
    return _firestore
        .collection(AppConstants.usersCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Employee.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Ajouter un employé
  Future<void> addEmployee(Employee employee, String performedBy) async {
    // Générer un nouvel ID si l'ID est vide
    final docRef = employee.id.isEmpty 
        ? _firestore.collection(AppConstants.usersCollection).doc() 
        : _firestore.collection(AppConstants.usersCollection).doc(employee.id);
    
    // Mettre à jour l'ID de l'employé avec l'ID généré
    if (employee.id.isEmpty) {
      employee.id = docRef.id;
    }
    
    // Enregistrer l'employé
    await docRef.set(employee.toMap());
        
    // Enregistrer l'activité
    await _activityService.logEmployeeCreated(employee, performedBy);
  }

  // Mettre à jour un employé
  Future<void> updateEmployee(Employee employee, String performedBy, Map<String, dynamic> changedFields) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(employee.id)
        .update(employee.toMap());
        
    // Enregistrer l'activité
    await _activityService.logActivity(
      Activity(
        id: '',
        activityType: ActivityType.employeeUpdated.value,
        description: 'Modification de l\'employé "${employee.name}"',
        performedBy: performedBy,
        timestamp: DateTime.now(),
        targetId: employee.id,
        targetName: employee.name,
        details: {
          'changedFields': changedFields,
        },
      )
    );
  }

  // Supprimer un employé
  Future<void> deleteEmployee(String employeeId, String employeeName, String performedBy) async {
    await FirebaseFirestore.instance.collection(AppConstants.usersCollection).doc(employeeId).delete();
    await logEmployeeDeleted(employeeId, employeeName, performedBy);
  }

  Future<void> logEmployeeDeleted(String employeeId, String employeeName, String performedBy) async {
    await _activityService.logActivity(
        Activity(
          id: '',
          activityType: ActivityType.employeeDeleted.value,
          description: 'Suppression de l\'employé "$employeeName"',
          performedBy: performedBy,
          timestamp: DateTime.now(),
          targetId: employeeId,
          targetName: employeeName,
        )
      );
  }
} 