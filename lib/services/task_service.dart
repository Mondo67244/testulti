import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';
import 'package:flutter/foundation.dart';

class TaskService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Task>> getTasksByStatusAndEmployee(String status, String employeeId) {
    return _firestore
        .collection('tasks')
        .where('status', isEqualTo: status)
        .where('assignedTo', isEqualTo: employeeId)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Task.fromMap(data);
      }).toList();
    });
  }

  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addTaskComment(String taskId, String comment) async {
    final taskRef = _firestore.collection('tasks').doc(taskId);
    final taskDoc = await taskRef.get();
    
    if (taskDoc.exists) {
      final currentComments = List<String>.from(taskDoc.data()?['comments'] ?? []);
      currentComments.add(comment);
      
      await taskRef.update({
        'comments': currentComments,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<List<Task>> getTasks() async {
    return [];
  }
} 