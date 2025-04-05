import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/equipment.dart';
import '../constants/app_constants.dart';
import '../services/activity_service.dart';
import '../models/activity.dart';

class EquipmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ActivityService _activityService = ActivityService();

  // Récupérer tous les équipements
  Stream<List<Equipment>> getEquipments() {
    return _firestore
        .collection(AppConstants.equipmentCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Equipment.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Ajouter un équipement
  Future<void> addEquipment(Equipment equipment, String performedBy) async {
    // Créer une référence de document avec un ID généré automatiquement
    final docRef = _firestore.collection(AppConstants.equipmentCollection).doc();
    
    // Créer un nouvel équipement avec l'ID généré
    final newEquipment = equipment.copyWith(id: docRef.id);
    
    // Enregistrer l'équipement dans Firestore
    await docRef.set(newEquipment.toJson());
    
    // Enregistrer l'activité
    await _activityService.logEquipmentCreated(newEquipment, performedBy);
  }

  // Mettre à jour un équipement
  Future<void> updateEquipment(Equipment equipment, String performedBy, Map<String, dynamic> changedFields) async {
    await _firestore
        .collection(AppConstants.equipmentCollection)
        .doc(equipment.id)
        .update(equipment.toJson());
        
    // Enregistrer l'activité
    await _activityService.logEquipmentUpdated(equipment, performedBy, changedFields);
  }

  // Supprimer un équipement
  Future<void> deleteEquipment(String id, String performedBy) async {
    // Récupérer l'équipement avant de le supprimer
    final docSnapshot = await _firestore
        .collection(AppConstants.equipmentCollection)
        .doc(id)
        .get();
        
    if (docSnapshot.exists) {
      final equipment = Equipment.fromJson({...docSnapshot.data()!, 'id': id});
      
      // Supprimer l'équipement
      await _firestore
          .collection(AppConstants.equipmentCollection)
          .doc(id)
          .delete();
          
      // Enregistrer l'activité
      await _activityService.logEquipmentDeleted(equipment, performedBy);
    }
  }

  // Mettre à jour l'état d'un équipement
  Future<void> updateEquipmentState(String id, String newState, String performedBy) async {
    // Récupérer l'équipement avant la mise à jour
    final docSnapshot = await _firestore
        .collection(AppConstants.equipmentCollection)
        .doc(id)
        .get();
        
    if (docSnapshot.exists) {
      final equipment = Equipment.fromJson({...docSnapshot.data()!, 'id': id});
      final oldState = equipment.state;
      
      // Mettre à jour l'état
      await _firestore
          .collection(AppConstants.equipmentCollection)
          .doc(id)
          .update({'state': newState});
          
      // Enregistrer l'activité
      await _activityService.logEquipmentStateChanged(
        equipment.copyWith(state: newState), 
        performedBy, 
        oldState, 
        newState
      );
    }
  }
  
  // Mettre à jour le statut d'un équipement
  Future<void> updateEquipmentStatus(String id, String newStatus, String performedBy) async {
    // Récupérer l'équipement avant la mise à jour
    final docSnapshot = await _firestore
        .collection(AppConstants.equipmentCollection)
        .doc(id)
        .get();
        
    if (docSnapshot.exists) {
      final equipment = Equipment.fromJson({...docSnapshot.data()!, 'id': id});
      final oldStatus = equipment.status;
      
      // Mettre à jour le statut
      await _firestore
          .collection(AppConstants.equipmentCollection)
          .doc(id)
          .update({'status': newStatus});
          
      // Enregistrer l'activité
      await _activityService.logActivity(
        Activity(
          id: '',
          activityType: ActivityType.equipmentStatusChanged.value,
          description: 'Changement de statut de l\'équipement "${equipment.name}" de "$oldStatus" à "$newStatus"',
          performedBy: performedBy,
          timestamp: DateTime.now(),
          targetId: equipment.id,
          targetName: equipment.name,
          details: {
            'oldStatus': oldStatus,
            'newStatus': newStatus,
          },
        )
      );
    }
  }
} 


