import 'package:uuid/uuid.dart';

/// Category filter for clinical activities
enum ActivityCategory {
  all,
  notes,
  vitals,
  patients,
}

/// Clinical activity record representing provider interactions and actions.
class ActivityItem {
  final String id;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final ActivityCategory category;
  final String? statusBadge;
  final int? patientId;
  final String? patientName;
  final String? actionRoute;

  ActivityItem({
    String? id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.category,
    this.statusBadge,
    this.patientId,
    this.patientName,
    this.actionRoute,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'timestamp': timestamp.toIso8601String(),
      'category': category.name,
      'statusBadge': statusBadge,
      'patientId': patientId,
      'patientName': patientName,
      'actionRoute': actionRoute,
    };
  }

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      category: _categoryFromString(json['category'] as String?),
      statusBadge: json['statusBadge'] as String?,
      patientId: json['patientId'] as int?,
      patientName: json['patientName'] as String?,
      actionRoute: json['actionRoute'] as String?,
    );
  }

  static ActivityCategory _categoryFromString(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'notes':
        return ActivityCategory.notes;
      case 'vitals':
        return ActivityCategory.vitals;
      case 'patients':
        return ActivityCategory.patients;
      default:
        return ActivityCategory.all;
    }
  }
}
