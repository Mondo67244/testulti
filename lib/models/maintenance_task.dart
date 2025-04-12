import 'package:cloud_firestore/cloud_firestore.dart';

//cette page fournit les tâches de maintenance effectuées par les employés
class MaintenanceTask {
  final String id;
  final String title;
  final String description;
  final String equipmentId;
  final String assignedTo;
  final String status;
  final String type;
  final DateTime dueDate;
  final DateTime createdAt;
  final DateTime? completionDate;
  final String? notes;

  MaintenanceTask({
    required this.id,
    required this.title,
    required this.description,
    required this.equipmentId,
    required this.assignedTo,
    required this.status,
    required this.type,
    required this.dueDate,
    required this.createdAt,
    this.completionDate,
    this.notes,
  });

  factory MaintenanceTask.fromMap(Map<String, dynamic> map, String id) {
    return MaintenanceTask(
      id: id,
      title: map['title']?.toString() ?? 'Sans titre',
      description: map['description']?.toString() ?? 'Aucune description',
      equipmentId: map['equipmentId']?.toString() ?? '',
      assignedTo: map['assignedTo']?.toString() ?? 'Non assigné',
      status: map['status']?.toString() ?? 'En attente',
      type: map['type']?.toString() ?? 'Standard',
      dueDate: map['dueDate'] != null
          ? (map['dueDate'] as Timestamp).toDate()
          : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      completionDate: map['completionDate'] != null
          ? (map['completionDate'] as Timestamp).toDate()
          : null,
      notes: map['notes']?.toString(),
  );}

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'equipmentId': equipmentId,
      'assignedTo': assignedTo,
      'status': status,
      'type': type,
      'dueDate': dueDate,
      'createdAt': createdAt,
      'completionDate': completionDate,
      'notes': notes,
    };
  }

  MaintenanceTask copyWith({
    String? id,
    String? title,
    String? description,
    String? equipmentId,
    String? assignedTo,
    String? status,
    String? type,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? completionDate,
    String? notes,
  }) {
    return MaintenanceTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      equipmentId: equipmentId ?? this.equipmentId,
      assignedTo: assignedTo ?? this.assignedTo,
      status: status ?? this.status,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      completionDate: completionDate ?? this.completionDate,
      notes: notes ?? this.notes,
    );
  }

  bool get isOverdue =>
      DateTime.now().isAfter(dueDate) && status != 'completed';

  bool get isCompleted => status == 'completed';

  Duration get timeUntilDue => dueDate.difference(DateTime.now());

  Duration? get completionTime {
    if (completionDate == null) return null;
    return completionDate!.difference(createdAt);
  }
}
