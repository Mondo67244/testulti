import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_constants.dart';

//cette page fournit les événements de l'historique des équipements
class HistoryEvent {
  final DateTime date;
  final String description;

  HistoryEvent({
    required this.date,
    required this.description,
  });

  factory HistoryEvent.fromJson(Map<String, dynamic> json) {
    return HistoryEvent(
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'description': description,
    };
  }
}

class Equipment {    
  final String id;
  final String name;
  final String description;
  final String serialNumber;
  final String category;
  final String location;
  final String status;
  final String state;
  final String type;
  final String manufacturer;
  final String model;
  final String supplier;
  final String responsibleDepartment;
  final DateTime purchaseDate;
  final DateTime installationDate;
  final DateTime? lastMaintenanceDate;
  final DateTime? nextMaintenanceDate;
  final List<HistoryEvent> errorHistory;
  final List<HistoryEvent> maintenanceHistory;
  final Map<String, dynamic> specifications;

  Equipment({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.serialNumber,
    required this.category,
    required this.location,
    required this.status,
    required this.state,
    required this.manufacturer,
    required this.model,
    required this.supplier,
    required this.responsibleDepartment,
    required this.purchaseDate,
    required this.installationDate,
    this.lastMaintenanceDate,
    this.nextMaintenanceDate,
    this.errorHistory = const [],
    this.maintenanceHistory = const [],
    this.specifications = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'serialNumber': serialNumber,
      'category': category,
      'type': type,
      'location': location,
      'status': status,
      'state': state,
      'manufacturer': manufacturer,
      'model': model,
      'supplier': supplier,
      'responsibleDepartment': responsibleDepartment,
      'purchaseDate': purchaseDate.toIso8601String(),
      'installationDate': installationDate.toIso8601String(),
      'lastMaintenanceDate': lastMaintenanceDate?.toIso8601String(),
      'nextMaintenanceDate': nextMaintenanceDate?.toIso8601String(),
      'errorHistory': errorHistory.map((e) => e.toJson()).toList(),
      'maintenanceHistory': maintenanceHistory.map((e) => e.toJson()).toList(),
      'specifications': specifications,
    };
  }

  factory Equipment.fromJson(Map<String, dynamic> json) {
    try {
      print('Conversion JSON en Equipment: ${json.toString()}');
      return Equipment(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        serialNumber: json['serialNumber'] ?? '',
        category: json['category'] ?? '',
        type: json['type'] ?? '',
        location: json['location'] ?? '',
        status: json['status'] ?? AppConstants.equipmentStatuses[0],
        state: json['state'] ?? AppConstants.equipmentStates[0],
        manufacturer: json['manufacturer'] ?? '',
        model: json['model'] ?? '',
        supplier: json['supplier'] ?? '',
        responsibleDepartment: json['responsibleDepartment'] ?? '',
        purchaseDate: json['purchaseDate'] != null
            ? (json['purchaseDate'] is Timestamp
                ? (json['purchaseDate'] as Timestamp).toDate()
                : DateTime.parse(json['purchaseDate'].toString()))
            : DateTime.now(),
        installationDate: json['installationDate'] != null
            ? (json['installationDate'] is Timestamp
                ? (json['installationDate'] as Timestamp).toDate()
                : DateTime.parse(json['installationDate'].toString()))
            : DateTime.now(),
        lastMaintenanceDate: json['lastMaintenanceDate'] != null
            ? (json['lastMaintenanceDate'] is Timestamp
                ? (json['lastMaintenanceDate'] as Timestamp).toDate()
                : DateTime.parse(json['lastMaintenanceDate'].toString()))
            : null,
        nextMaintenanceDate: json['nextMaintenanceDate'] != null
            ? (json['nextMaintenanceDate'] is Timestamp
                ? (json['nextMaintenanceDate'] as Timestamp).toDate()
                : DateTime.parse(json['nextMaintenanceDate'].toString()))
            : null,
        errorHistory: (json['errorHistory'] as List<dynamic>?)
                ?.map((e) => HistoryEvent.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        maintenanceHistory: (json['maintenanceHistory'] as List<dynamic>?)
                ?.map((e) => HistoryEvent.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        specifications: Map<String, dynamic>.from(json['specifications'] ?? {}),
      );
    } catch (e) {
      print('Erreur lors de la conversion JSON en Equipment: $e');
      print('JSON reçu: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'serialNumber': serialNumber,
      'category': category,
      'location': location,
      'status': status,
      'state': state,
      'type': type,
      'manufacturer': manufacturer,
      'model': model,
      'supplier': supplier,
      'responsibleDepartment': responsibleDepartment,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'installationDate': Timestamp.fromDate(installationDate),
      'lastMaintenanceDate': lastMaintenanceDate != null
          ? Timestamp.fromDate(lastMaintenanceDate!)
          : null,
      'nextMaintenanceDate': nextMaintenanceDate != null
          ? Timestamp.fromDate(nextMaintenanceDate!)
          : null,
      'errorHistory': errorHistory.map((e) => e.toJson()).toList(),
      'maintenanceHistory': maintenanceHistory.map((e) => e.toJson()).toList(),
      'specifications': specifications,
    };
  }

  Equipment copyWith({
    String? id,
    String? name,
    String? description,
    String? serialNumber,
    String? category,
    String? location,
    String? status,
    String? type,
    String? state,
    String? manufacturer,
    String? model,
    String? supplier,
    String? responsibleDepartment,
    DateTime? purchaseDate,
    DateTime? installationDate,
    DateTime? lastMaintenanceDate,
    DateTime? nextMaintenanceDate,
    List<HistoryEvent>? errorHistory,
    List<HistoryEvent>? maintenanceHistory,
    Map<String, dynamic>? specifications,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      serialNumber: serialNumber ?? this.serialNumber,
      category: category ?? this.category,
      type: type ?? this.type,
      location: location ?? this.location,
      status: status ?? this.status,
      state: state ?? this.state,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      supplier: supplier ?? this.supplier,
      responsibleDepartment:
          responsibleDepartment ?? this.responsibleDepartment,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      installationDate: installationDate ?? this.installationDate,
      lastMaintenanceDate: lastMaintenanceDate ?? this.lastMaintenanceDate,
      nextMaintenanceDate: nextMaintenanceDate ?? this.nextMaintenanceDate,
      errorHistory: errorHistory ?? this.errorHistory,
      maintenanceHistory: maintenanceHistory ?? this.maintenanceHistory,
      specifications: specifications ?? this.specifications,
    );
  }
}