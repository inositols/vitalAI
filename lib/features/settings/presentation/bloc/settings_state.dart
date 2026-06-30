import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final bool isHighContrast;
  final String tempUnit;
  final String glucoseUnit;
  final String weightUnit;
  final String languageCode;
  final bool aiConsent;
  final String apiKey;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.isHighContrast = false,
    this.tempUnit = 'C',
    this.glucoseUnit = 'mg/dL',
    this.weightUnit = 'kg',
    this.languageCode = 'en',
    this.aiConsent = false,
    this.apiKey = '',
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? isHighContrast,
    String? tempUnit,
    String? glucoseUnit,
    String? weightUnit,
    String? languageCode,
    bool? aiConsent,
    String? apiKey,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      isHighContrast: isHighContrast ?? this.isHighContrast,
      tempUnit: tempUnit ?? this.tempUnit,
      glucoseUnit: glucoseUnit ?? this.glucoseUnit,
      weightUnit: weightUnit ?? this.weightUnit,
      languageCode: languageCode ?? this.languageCode,
      aiConsent: aiConsent ?? this.aiConsent,
      apiKey: apiKey ?? this.apiKey,
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        isHighContrast,
        tempUnit,
        glucoseUnit,
        weightUnit,
        languageCode,
        aiConsent,
        apiKey,
      ];
}
