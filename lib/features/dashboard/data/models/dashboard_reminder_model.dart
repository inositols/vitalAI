import 'package:flutter/material.dart';

class DashboardReminderModel {
  final String id;
  final String title;
  final String time;
  final IconData icon;
  final bool isCompleted;

  const DashboardReminderModel({
    required this.id,
    required this.title,
    required this.time,
    required this.icon,
    this.isCompleted = false,
  });

  DashboardReminderModel copyWith({
    String? id,
    String? title,
    String? time,
    IconData? icon,
    bool? isCompleted,
  }) {
    return DashboardReminderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      icon: icon ?? this.icon,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
