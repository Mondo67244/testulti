import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String status;
  final String assignedTo;
  final List<String> comments;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    required this.assignedTo,
    this.comments = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      status: map['status'] as String,
      assignedTo: map['assignedTo'] as String,
      comments: List<String>.from(map['comments'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status,
      'assignedTo': assignedTo,
      'comments': comments,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? status,
    String? assignedTo,
    List<String>? comments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
