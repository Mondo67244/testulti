import 'package:cloud_firestore/cloud_firestore.dart';

//cette page fournit les informations des employés
class Employee {
  String id;
  final String name;
  final String email;
  final String role;
  final String function;
  final String department;
  final String phoneNumber;
  final bool isActive;
  final DateTime joinDate;
  final bool _isAvailable;
  final String location;
  Employee({
    this.id = '',
    required this.name,
    required this.email,
    required this.role,
    required this.function,
    required this.location,
    required this.department,
    required this.phoneNumber,
    required this.isActive,
    required this.joinDate,
    bool isAvailable = true,
  }) : _isAvailable = isAvailable;

  factory Employee.fromMap(Map<String, dynamic> map) {
    try {
      print("Désérialisation Employee.fromMap: ${map.toString()}");

      // Log the type of each field
      print("Type of id: ${map['id']?.runtimeType}");
      print("Type of name: ${map['name']?.runtimeType}");
      print("Type of email: ${map['email']?.runtimeType}");
      print("Type of role: ${map['role']?.runtimeType}");
      print("Type of location: ${map['location']?.runtimeType}");
      print("Type of function: ${map['function']?.runtimeType}");
      print("Type of department: ${map['department']?.runtimeType}");
      print("Type of phoneNumber: ${map['phoneNumber']?.runtimeType}");
      print("Type of isActive: ${map['isActive']?.runtimeType}");
      print("Type of joinDate: ${map['joinDate']?.runtimeType}");
      print("Type of isAvailable: ${map['isAvailable']?.runtimeType}");

      // Extraire et valider les champs
      final String id = map['id']?.toString() ?? '';
      final String name = map['name']?.toString() ?? '';
      final String email = map['email']?.toString() ?? '';
      final String role = map['role']?.toString() ?? '';
      final String location = map['location']?.toString() ?? '';
      final String function = map['function']?.toString() ?? '';
      final String department = map['department']?.toString() ?? '';
      final String phoneNumber = map['phoneNumber']?.toString() ?? '';
      final bool isActive = map['isActive'] == true;

      // Traitement spécial pour la date
      DateTime joinDate;
      try {
        if (map['joinDate'] is DateTime) {
          joinDate = map['joinDate'] as DateTime;
        } else if (map['joinDate'] is Timestamp) {
          joinDate = (map['joinDate'] as Timestamp).toDate();
        } else if (map['joinDate'] is String) {
          joinDate = DateTime.parse(map['joinDate']);
        } else {
          joinDate = DateTime.now();
        }
      } catch (e) {
        print("Erreur lors du parsing de la date: $e");
        joinDate = DateTime.now();
      }

      final bool isAvailable = map['isAvailable'] == true;

      print("Employee désérialisé: $name, $role");

      return Employee(
        id: id,
        name: name,
        email: email,
        role: role,
        function: function,
        location: location,
        department: department,
        phoneNumber: phoneNumber,
        isActive: isActive,
        joinDate: joinDate,
        isAvailable: isAvailable,
      );
    } catch (e) {
      print("Erreur lors de la désérialisation de Employee: $e");
      // Retourner un employé par défaut en cas d'erreur
      return Employee(
        id: map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? 'Utilisateur inconnu',
        email: map['email']?.toString() ?? '',
        role: map['role']?.toString() ?? 'user',
        location: map['location']?.toString() ?? 'user',
        function: map['function']?.toString() ?? '',
        department: map['department']?.toString() ?? '',
        phoneNumber: map['phoneNumber']?.toString() ?? '',
        isActive: true,
        joinDate: DateTime.now(),
        isAvailable: true,
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'location': location,
      'function': function,
      'department': department,
      'phoneNumber': phoneNumber,
      'isActive': isActive,
      'joinDate': Timestamp.fromDate(joinDate),
      'isAvailable': _isAvailable,
    };
  }

  bool get isAvailable => _isAvailable && isActive;
}
