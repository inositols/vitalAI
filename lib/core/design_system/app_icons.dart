import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Centralized Icon system mapping all application actions and health vitals
/// to crisp, modern native vector icons.
abstract class AppIcons {
  // Navigation & System Core
  static const IconData dashboard = Icons.grid_view_rounded;
  static const IconData vitals = Icons.favorite_rounded;
  static const IconData aiAssistant = Icons.auto_awesome_rounded;
  static const IconData patients = Icons.people_alt_rounded;
  static const IconData caregiver = Icons.health_and_safety_rounded;
  static const IconData settings = Icons.settings_rounded;
  static const IconData syncStatus = Icons.sync_rounded;
  static const IconData add = Icons.add_rounded;
  static const IconData check = Icons.check_circle_rounded;
  static const IconData warning = Icons.warning_amber_rounded;
  static const IconData info = Icons.info_outline_rounded;
  static const IconData chevronRight = Icons.chevron_right_rounded;
  static const IconData filter = Icons.tune_rounded;
  static const IconData mic = Icons.mic_rounded;
  static const IconData send = Icons.send_rounded;
  static const IconData share = Icons.share_rounded;
  static const IconData pdf = Icons.picture_as_pdf_rounded;
  static const IconData history = Icons.history_rounded;
  static const IconData chart = Icons.show_chart_rounded;
  static const IconData reminder = Icons.notifications_active_rounded;
  static const IconData medication = Icons.medication_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData edit = Icons.edit_outlined;
  static const IconData delete = Icons.delete_outline_rounded;
  static const IconData logout = Icons.logout_rounded;
  static const IconData calendar = Icons.calendar_today_rounded;
  static const IconData lock = Icons.lock_outline_rounded;

  // Health Vital Metrics Icons
  static const IconData bloodPressure = CupertinoIcons.heart_fill;
  static const IconData glucose = Icons.water_drop_rounded;
  static const IconData pulse = Icons.monitor_heart_rounded;
  static const IconData spo2 = Icons.air_rounded;
  static const IconData temperature = Icons.thermostat_rounded;
  static const IconData weight = Icons.scale_rounded;
  static const IconData height = Icons.straighten_rounded;
  static const IconData bmi = Icons.boy_rounded;

  /// Resolves the appropriate vector icon for any vital metric string identifier.
  static IconData getVitalIcon(String metricType) {
    switch (metricType.toLowerCase().trim()) {
      case 'blood_pressure':
      case 'blood pressure':
      case 'bp':
        return bloodPressure;
      case 'glucose':
      case 'blood_glucose':
        return glucose;
      case 'pulse':
      case 'heart_rate':
      case 'pulse_rate':
        return pulse;
      case 'spo2':
      case 'oximetry':
      case 'oxygen':
        return spo2;
      case 'temperature':
      case 'body_temperature':
      case 'temp':
        return temperature;
      case 'weight':
        return weight;
      case 'height':
        return height;
      case 'bmi':
        return bmi;
      default:
        return Icons.medical_services_rounded;
    }
  }
}
