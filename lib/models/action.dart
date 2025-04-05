//cette page fournit les actions effectuées par les employés qui devront être enregistrées dans la page des actions recemment effectuées
class MaintenanceAction {
  final String id;
  final String equipmentId;
  final String employeeId;
  final String reportId;
  final String type;
  final String description;
  final String status;
  final DateTime scheduledDate;
  final DateTime? completedAt;
  final double? actualDuration;
  final Map<String, bool> checkList;
  final String priority;

  MaintenanceAction({
    required this.id,
    required this.equipmentId,
    required this.employeeId,
    this.reportId = '',
    required this.type,
    required this.description,
    required this.status,
    required this.scheduledDate,
    this.completedAt,
    this.actualDuration,
    this.checkList = const {},
    required this.priority,
  });

  factory MaintenanceAction.fromJson(Map<String, dynamic> json) {
    return MaintenanceAction(
      id: json['id'] ?? '',
      equipmentId: json['equipmentId'] ?? '',
      employeeId: json['employeeId'] ?? '',
      reportId: json['reportId'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? '',
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'])
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      actualDuration: json['actualDuration']?.toDouble(),
      checkList: Map<String, bool>.from(json['checkList'] ?? {}),
      priority: json['priority'] ?? 'normal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'equipmentId': equipmentId,
      'employeeId': employeeId,
      'reportId': reportId,
      'type': type,
      'description': description,
      'status': status,
      'scheduledDate': scheduledDate.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'actualDuration': actualDuration,
      'checkList': checkList,
      'priority': priority,
    };
  }

  MaintenanceAction copyWith({
    String? id,
    String? equipmentId,
    String? employeeId,
    String? reportId,
    String? type,
    String? description,
    String? status,
    DateTime? scheduledDate,
    DateTime? completedAt,
    double? estimatedDuration,
    double? actualDuration,
    List<String>? requiredQualifications,
    List<String>? requiredTools,
    List<String>? requiredParts,
    double? estimatedCost,
    double? actualCost,
    List<String>? steps,
    List<String>? notes,
    Map<String, bool>? checkList,
    String? priority,
  }) {
    return MaintenanceAction(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      employeeId: employeeId ?? this.employeeId,
      reportId: reportId ?? this.reportId,
      type: type ?? this.type,
      description: description ?? this.description,
      status: status ?? this.status,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completedAt: completedAt ?? this.completedAt,
      actualDuration: actualDuration ?? this.actualDuration,
      checkList: checkList ?? this.checkList,
      priority: priority ?? this.priority,
    );
  }

  bool get isLate {
    if (status == 'completed') return false;
    return DateTime.now().isAfter(scheduledDate);
  }

  double get progress {
    if (checkList.isEmpty) return 0.0;
    final completedItems = checkList.values.where((v) => v).length;
    return completedItems / checkList.length;
  }

  bool get isCritical => priority == 'high' || priority == 'critical';
}
