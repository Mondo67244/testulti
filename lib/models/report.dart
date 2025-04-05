import 'package:cloud_firestore/cloud_firestore.dart';

//cette page fournit les rapports effectués par les employés
class Report {
  final String id;
  final String equipmentId;
  final String title;
  final String description;
  final String urgencyLevel;
  final String impact;
  final String status;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  Report({
    required this.id,
    required this.equipmentId,
    required this.title,
    required this.description,
    required this.urgencyLevel,
    required this.impact,
    required this.status,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String? ?? '',
      equipmentId: json['equipmentId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      urgencyLevel: json['urgencyLevel'] as String? ?? 'low',
      impact: json['impact'] as String? ?? 'low',
      status: json['status'] as String? ?? 'pending',
      date: json['date'] != null
          ? (json['date'] is Timestamp
              ? (json['date'] as Timestamp).toDate()
              : DateTime.parse(json['date'].toString()))
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.parse(json['createdAt'].toString()))
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is Timestamp
              ? (json['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(json['updatedAt'].toString()))
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'equipmentId': equipmentId,
      'title': title,
      'description': description,
      'urgencyLevel': urgencyLevel,
      'impact': impact,
      'status': status,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Report copyWith({
    String? id,
    String? equipmentId,
    String? title,
    String? description,
    String? urgencyLevel,
    String? impact,
    String? status,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Report(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      title: title ?? this.title,
      description: description ?? this.description,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      impact: impact ?? this.impact,
      status: status ?? this.status,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
