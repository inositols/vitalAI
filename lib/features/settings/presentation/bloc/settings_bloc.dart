import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final FlutterSecureStorage _secureStorage;

  SettingsBloc({required this._secureStorage})
      : super(const SettingsState()) {
    on<SettingsLoadRequested>(_onSettingsLoadRequested);
    on<ThemeChanged>(_onThemeChanged);
    on<TemperatureUnitChanged>(_onTemperatureUnitChanged);
    on<GlucoseUnitChanged>(_onGlucoseUnitChanged);
    on<WeightUnitChanged>(_onWeightUnitChanged);
    on<LanguageChanged>(_onLanguageChanged);
    on<AiConsentToggled>(_onAiConsentToggled);
    on<ApiKeyUpdated>(_onApiKeyUpdated);
  }

  Future<void> _onSettingsLoadRequested(
      SettingsLoadRequested event, Emitter<SettingsState> emit) async {
    final themeStr = await _secureStorage.read(key: 'theme_mode');
    final hcStr = await _secureStorage.read(key: 'is_high_contrast');
    final tempUnit = await _secureStorage.read(key: 'temp_unit') ?? 'C';
    final glucoseUnit = await _secureStorage.read(key: 'glucose_unit') ?? 'mg/dL';
    final weightUnit = await _secureStorage.read(key: 'weight_unit') ?? 'kg';
    final lang = await _secureStorage.read(key: 'language_code') ?? 'en';
    final consentStr = await _secureStorage.read(key: 'ai_consent');
    final apiKey = await _secureStorage.read(key: 'api_key') ?? '';

    ThemeMode themeMode = ThemeMode.system;
    if (themeStr == 'light') themeMode = ThemeMode.light;
    if (themeStr == 'dark') themeMode = ThemeMode.dark;

    final isHighContrast = hcStr == 'true';
    final aiConsent = consentStr == 'true';

    emit(SettingsState(
      themeMode: themeMode,
      isHighContrast: isHighContrast,
      tempUnit: tempUnit,
      glucoseUnit: glucoseUnit,
      weightUnit: weightUnit,
      languageCode: lang,
      aiConsent: aiConsent,
      apiKey: apiKey,
    ));
  }

  Future<void> _onThemeChanged(
      ThemeChanged event, Emitter<SettingsState> emit) async {
    String themeStr = 'system';
    if (event.themeMode == ThemeMode.light) themeStr = 'light';
    if (event.themeMode == ThemeMode.dark) themeStr = 'dark';

    await _secureStorage.write(key: 'theme_mode', value: themeStr);
    await _secureStorage.write(
        key: 'is_high_contrast', value: event.isHighContrast.toString());

    emit(state.copyWith(
      themeMode: event.themeMode,
      isHighContrast: event.isHighContrast,
    ));
  }

  Future<void> _onTemperatureUnitChanged(
      TemperatureUnitChanged event, Emitter<SettingsState> emit) async {
    await _secureStorage.write(key: 'temp_unit', value: event.unit);
    emit(state.copyWith(tempUnit: event.unit));
  }

  Future<void> _onGlucoseUnitChanged(
      GlucoseUnitChanged event, Emitter<SettingsState> emit) async {
    await _secureStorage.write(key: 'glucose_unit', value: event.unit);
    emit(state.copyWith(glucoseUnit: event.unit));
  }

  Future<void> _onWeightUnitChanged(
      WeightUnitChanged event, Emitter<SettingsState> emit) async {
    await _secureStorage.write(key: 'weight_unit', value: event.unit);
    emit(state.copyWith(weightUnit: event.unit));
  }

  Future<void> _onLanguageChanged(
      LanguageChanged event, Emitter<SettingsState> emit) async {
    await _secureStorage.write(key: 'language_code', value: event.languageCode);
    emit(state.copyWith(languageCode: event.languageCode));
  }

  Future<void> _onAiConsentToggled(
      AiConsentToggled event, Emitter<SettingsState> emit) async {
    await _secureStorage.write(
        key: 'ai_consent', value: event.consentGranted.toString());
    emit(state.copyWith(aiConsent: event.consentGranted));
  }

  Future<void> _onApiKeyUpdated(
      ApiKeyUpdated event, Emitter<SettingsState> emit) async {
    await _secureStorage.write(key: 'api_key', value: event.apiKey);
    emit(state.copyWith(apiKey: event.apiKey));
  }
}
