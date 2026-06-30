import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class SettingsLoadRequested extends SettingsEvent {}

class ThemeChanged extends SettingsEvent {
  final ThemeMode themeMode;
  final bool isHighContrast;

  const ThemeChanged({required this.themeMode, required this.isHighContrast});

  @override
  List<Object?> get props => [themeMode, isHighContrast];
}

class TemperatureUnitChanged extends SettingsEvent {
  final String unit; // 'C' or 'F'

  const TemperatureUnitChanged(this.unit);

  @override
  List<Object?> get props => [unit];
}

class GlucoseUnitChanged extends SettingsEvent {
  final String unit; // 'mg/dL' or 'mmol/L'

  const GlucoseUnitChanged(this.unit);

  @override
  List<Object?> get props => [unit];
}

class WeightUnitChanged extends SettingsEvent {
  final String unit; // 'kg' or 'lbs'

  const WeightUnitChanged(this.unit);

  @override
  List<Object?> get props => [unit];
}

class LanguageChanged extends SettingsEvent {
  final String languageCode;

  const LanguageChanged(this.languageCode);

  @override
  List<Object?> get props => [languageCode];
}

class AiConsentToggled extends SettingsEvent {
  final bool consentGranted;

  const AiConsentToggled(this.consentGranted);

  @override
  List<Object?> get props => [consentGranted];
}

class ApiKeyUpdated extends SettingsEvent {
  final String apiKey;

  const ApiKeyUpdated(this.apiKey);

  @override
  List<Object?> get props => [apiKey];
}
