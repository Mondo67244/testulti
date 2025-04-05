import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String title;
  final String description;
  final String supplierId;
  final String supplierName;
  final String adminId;
  final DateTime createdAt;
  final String status;

  Order({
    required this.id,
    required this.title,
    required this.description,
    required this.supplierId,
    required this.supplierName,
    required this.adminId,
    required this.createdAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'adminId': adminId,
      'createdAt': createdAt,
      'status': status,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      supplierId: map['supplierId'] ?? '',
      supplierName: map['supplierName'] ?? '',
      adminId: map['adminId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
    );
  }
}
