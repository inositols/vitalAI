import 'package:flutter/material.dart';

class ReminderModel {
  final String id;
  final int patientId;
  final String title;
  final String time;
  final int hour;
  final int minute;
  final int iconCodePoint;
  final bool isCompleted;
  final bool isEnabled;
  final DateTime createdAt;

  const ReminderModel({
    required this.id,
    required this.patientId,
    required this.title,
    required this.time,
    required this.hour,
    required this.minute,
    this.iconCodePoint = 0xe0b2, // default alarm icon
    this.isCompleted = false,
    this.isEnabled = true,
    required this.createdAt,
  });

  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  ReminderModel copyWith({
    String? id,
    int? patientId,
    String? title,
    String? time,
    int? hour,
    int? minute,
    int? iconCodePoint,
    bool? isCompleted,
    bool? isEnabled,
    DateTime? createdAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      title: title ?? this.title,
      time: time ?? this.time,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      isCompleted: isCompleted ?? this.isCompleted,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'title': title,
      'time': time,
      'hour': hour,
      'minute': minute,
      'iconCodePoint': iconCodePoint,
      'isCompleted': isCompleted,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] as String,
      patientId: json['patientId'] as int? ?? 0,
      title: json['title'] as String? ?? 'Reminder',
      time: json['time'] as String? ?? '08:00 AM',
      hour: json['hour'] as int? ?? 8,
      minute: json['minute'] as int? ?? 0,
      iconCodePoint: json['iconCodePoint'] as int? ?? 0xe0b2,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isEnabled: json['isEnabled'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
