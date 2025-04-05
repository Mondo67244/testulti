import 'package:cloud_firestore/cloud_firestore.dart';
//cette page fournit les activités effectuées par les employésqui devront être enregistrées dans la page des activités recemment effectuées

// Types d'activités possibles
enum ActivityType {
  // Équipements
  equipmentCreated,
  equipmentUpdated,
  equipmentDeleted,
  equipmentStateChanged,
  equipmentStatusChanged,

  // Employés
  employeeCreated,
  employeeUpdated,
  employeeDeleted,
  employeeLogin,
  employeeLogout,

  // Tâches
  taskCreated,
  taskUpdated,
  taskDeleted,
  taskAssigned,
  taskStatusChanged,

  // Rapports
  reportSubmitted,
  reportUpdated,
  reportStatusChanged,

  // Système
  systemAction,
}

// Extension pour convertir l'enum en string et vice versa
extension ActivityTypeExtension on ActivityType {
  String get value {
    return toString().split('.').last;
  }

  String get category {
    if (toString().startsWith('ActivityType.equipment')) {
      return 'equipment';
    } else if (toString().startsWith('ActivityType.employee')) {
      return 'employee';
    } else if (toString().startsWith('ActivityType.task')) {
      return 'task';
    } else if (toString().startsWith('ActivityType.report')) {
      return 'report';
    } else {
      return 'system';
    }
  }

  String get displayName {
    switch (this) {
      // Équipements
      case ActivityType.equipmentCreated:
        return 'Création d\'équipement';
      case ActivityType.equipmentUpdated:
        return 'Modification d\'équipement';
      case ActivityType.equipmentDeleted:
        return 'Suppression d\'équipement';
      case ActivityType.equipmentStateChanged:
        return 'Changement d\'état d\'équipement';
      case ActivityType.equipmentStatusChanged:
        return 'Changement de statut d\'équipement';

      // Employés
      case ActivityType.employeeCreated:
        return 'Création d\'employé';
      case ActivityType.employeeUpdated:
        return 'Modification d\'employé';
      case ActivityType.employeeDeleted:
        return 'Suppression d\'employé';
      case ActivityType.employeeLogin:
        return 'Connexion d\'employé';
      case ActivityType.employeeLogout:
        return 'Déconnexion d\'employé';

      // Tâches
      case ActivityType.taskCreated:
        return 'Création de tâche';
      case ActivityType.taskUpdated:
        return 'Modification de tâche';
      case ActivityType.taskDeleted:
        return 'Suppression de tâche';
      case ActivityType.taskAssigned:
        return 'Assignation de tâche';
      case ActivityType.taskStatusChanged:
        return 'Changement de statut de tâche';

      // Rapports
      case ActivityType.reportSubmitted:
        return 'Soumission de rapport';
      case ActivityType.reportUpdated:
        return 'Modification de rapport';
      case ActivityType.reportStatusChanged:
        return 'Changement de statut de rapport';

      // Système
      case ActivityType.systemAction:
        return 'Action système';
    }
  }
}

// Fonction pour convertir une string en ActivityType
ActivityType stringToActivityType(String value) {
  return ActivityType.values.firstWhere(
    (type) => type.value == value,
    orElse: () => ActivityType.systemAction,
  );
}

class Activity {
  final String id;
  final String activityType; // Stocké comme string dans Firestore
  final String description;
  final String performedBy;
  final DateTime timestamp;
  final String?
      targetId; // ID de l'objet concerné (équipement, employé, tâche, etc.)
  final String? targetName; // Nom de l'objet concerné
  final Map<String, dynamic>?
      details; // Détails supplémentaires (avant/après pour les changements, etc.)

  Activity({
    required this.id,
    required this.activityType,
    required this.description,
    required this.performedBy,
    required this.timestamp,
    this.targetId,
    this.targetName,
    this.details,
  });

  // Getter pour obtenir l'enum ActivityType
  ActivityType get type => stringToActivityType(activityType);

  // Getter pour obtenir la catégorie (equipment, employee, task, report, system)
  String get category => type.category;

  factory Activity.fromJson(Map<String, dynamic> json) {
    try {
      // Vérifier que les champs requis ne sont pas null
      final String id = json['id']?.toString() ?? '';

      final String activityType =
          json['activityType']?.toString() ?? 'systemAction';

      final String description =
          json['description']?.toString() ?? 'Activité inconnue';

      final String performedBy =
          json['performedBy']?.toString() ?? 'Utilisateur inconnu';

      // Gestion du timestamp qui peut être de différents types
      DateTime timestamp;
      try {
        if (json['timestamp'] is Timestamp) {
          timestamp = (json['timestamp'] as Timestamp).toDate();
        } else if (json['timestamp'] is DateTime) {
          timestamp = json['timestamp'] as DateTime;
        } else if (json['timestamp'] is String) {
          timestamp = DateTime.parse(json['timestamp'] as String);
        } else {
          print(
              'Format de timestamp non reconnu: ${json['timestamp']?.runtimeType}');
          timestamp = DateTime.now();
        }
      } catch (e) {
        print('Erreur lors du parsing du timestamp: $e');
        timestamp = DateTime.now();
      }

      // Gestion des champs optionnels
      String? targetId;
      if (json['targetId'] != null) {
        targetId = json['targetId'].toString();
      }

      String? targetName;
      if (json['targetName'] != null) {
        targetName = json['targetName'].toString();
      }

      Map<String, dynamic>? details;
      if (json['details'] != null && json['details'] is Map) {
        details = Map<String, dynamic>.from(json['details'] as Map);
      }

      final activity = Activity(
        id: id,
        activityType: activityType,
        description: description,
        performedBy: performedBy,
        timestamp: timestamp,
        targetId: targetId,
        targetName: targetName,
        details: details,
      );

      return activity;
    } catch (e) {
      print('Erreur lors de la désérialisation: $e');
      print('JSON: $json');

      // Créer une activité par défaut en cas d'erreur
      return Activity(
        id: json['id']?.toString() ?? '',
        activityType: 'systemAction',
        description: 'Erreur lors du chargement de l\'activité',
        performedBy: 'Système',
        timestamp: DateTime.now(),
        targetId: null,
        targetName: null,
        details: {'error': e.toString(), 'originalJson': json.toString()},
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'activityType': activityType,
      'description': description,
      'performedBy': performedBy,
      'timestamp': Timestamp.fromDate(timestamp),
      'targetId': targetId,
      'targetName': targetName,
      'details': details,
      'category': category,
    };
  }

  // Méthode pour créer une copie avec des modifications
  Activity copyWith({
    String? id,
    String? activityType,
    String? description,
    String? performedBy,
    DateTime? timestamp,
    String? targetId,
    String? targetName,
    Map<String, dynamic>? details,
  }) {
    return Activity(
      id: id ?? this.id,
      activityType: activityType ?? this.activityType,
      description: description ?? this.description,
      performedBy: performedBy ?? this.performedBy,
      timestamp: timestamp ?? this.timestamp,
      targetId: targetId ?? this.targetId,
      targetName: targetName ?? this.targetName,
      details: details ?? this.details,
    );
  }
}
