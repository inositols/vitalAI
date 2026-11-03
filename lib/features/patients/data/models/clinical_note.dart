import 'package:uuid/uuid.dart';

/// Clinical Note model representing doctor's visit notes and SOAP summaries.
class ClinicalNote {
  final String id;
  final int patientId;
  final String visitType;
  final String content;
  final String authorName;
  final DateTime date;
  final bool isDraft;

  ClinicalNote({
    String? id,
    required this.patientId,
    required this.visitType,
    required this.content,
    this.authorName = 'Dr. Adeyemi',
    DateTime? date,
    this.isDraft = false,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'visitType': visitType,
      'content': content,
      'authorName': authorName,
      'date': date.toIso8601String(),
      'isDraft': isDraft,
    };
  }

  factory ClinicalNote.fromJson(Map<String, dynamic> json) {
    return ClinicalNote(
      id: json['id'] as String?,
      patientId: json['patientId'] as int? ?? 0,
      visitType: json['visitType'] as String? ?? 'General Consultation',
      content: json['content'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Dr. Adeyemi',
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      isDraft: json['isDraft'] as bool? ?? false,
    );
  }
}
