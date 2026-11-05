import '../models/genui_component.dart';
import '../models/genui_response.dart';

class GenUiValidationResult {
  final bool isValid;
  final List<String> errors;
  final GenUiComponent? sanitizedComponent;

  const GenUiValidationResult({
    required this.isValid,
    this.errors = const [],
    this.sanitizedComponent,
  });

  factory GenUiValidationResult.success([GenUiComponent? component]) =>
      GenUiValidationResult(isValid: true, sanitizedComponent: component);

  factory GenUiValidationResult.failure(List<String> errors) =>
      GenUiValidationResult(isValid: false, errors: errors);
}

/// Validates GenUI responses and component payloads against clinical safety schemas.
class GenUiValidator {
  const GenUiValidator();

  /// Validates an entire [GenUiResponse] and cleans any invalid components.
  GenUiResponse validateResponse(GenUiResponse response) {
    final List<String> allErrors = [];
    final List<GenUiComponent> validatedComponents = [];

    for (final component in response.components) {
      final result = validateComponent(component);
      if (result.isValid) {
        validatedComponents.add(result.sanitizedComponent ?? component);
      } else {
        allErrors.addAll(result.errors);
      }
    }

    return response.copyWith(
      components: validatedComponents,
      isValid: allErrors.isEmpty,
      errors: allErrors,
    );
  }

  /// Validates a single [GenUiComponent].
  GenUiValidationResult validateComponent(GenUiComponent component) {
    final type = component.type;
    final List<String> errors = [];

    if (!GenUiComponentTypes.all.contains(type) && type != 'unknown') {
      errors.add('Unrecognized GenUI component type: "$type". Must match registered schema.');
      return GenUiValidationResult.failure(errors);
    }

    switch (type) {
      case GenUiComponentTypes.vitalInputCard:
        return _validateVitalInput(component);

      case GenUiComponentTypes.editablePatientCard:
        return _validateEditablePatient(component);

      case GenUiComponentTypes.chartCard:
        return _validateChart(component);

      case GenUiComponentTypes.confirmationCard:
        return _validateConfirmation(component);

      case GenUiComponentTypes.patientCard:
      case GenUiComponentTypes.patientSelection:
        return _validatePatientCard(component);

      case GenUiComponentTypes.choiceCard:
      case GenUiComponentTypes.singleChoice:
      case GenUiComponentTypes.multipleChoice:
        return _validateChoiceCard(component);

      default:
        // By default, generic cards pass if type is known
        return GenUiValidationResult.success(component);
    }
  }

  GenUiValidationResult _validateVitalInput(GenUiComponent component) {
    final data = component.data;
    final errors = <String>[];

    // Systolic & Diastolic validation
    final systolic = _tryParseNum(data['systolic'] ?? data['bp_systolic']);
    final diastolic = _tryParseNum(data['diastolic'] ?? data['bp_diastolic']);

    if (systolic != null) {
      if (systolic < 50 || systolic > 300) {
        errors.add('Systolic reading ($systolic mmHg) is outside physiological boundaries (50-300 mmHg).');
      }
    }

    if (diastolic != null) {
      if (diastolic < 30 || diastolic > 200) {
        errors.add('Diastolic reading ($diastolic mmHg) is outside physiological boundaries (30-200 mmHg).');
      }
    }

    if (systolic != null && diastolic != null) {
      if (systolic <= diastolic) {
        errors.add('Systolic reading ($systolic mmHg) must be strictly greater than diastolic reading ($diastolic mmHg).');
      }
    }

    // Heart Rate validation
    final pulse = _tryParseNum(data['pulse'] ?? data['heartRate'] ?? data['hr']);
    if (pulse != null && (pulse < 20 || pulse > 300)) {
      errors.add('Heart rate ($pulse bpm) is outside physiological range (20-300 bpm).');
    }

    // Temperature validation
    final temp = _tryParseNum(data['temperature'] ?? data['temp']);
    if (temp != null && (temp < 28 || temp > 45)) {
      errors.add('Temperature ($temp °C) is outside physiological range (28-45 °C).');
    }

    // SpO2 validation
    final spo2 = _tryParseNum(data['spo2'] ?? data['oxygenSaturation']);
    if (spo2 != null && (spo2 < 40 || spo2 > 100)) {
      errors.add('Oxygen saturation ($spo2%) is outside physiological range (40-100%).');
    }

    if (errors.isNotEmpty) {
      return GenUiValidationResult.failure(errors);
    }
    return GenUiValidationResult.success(component);
  }

  GenUiValidationResult _validateEditablePatient(GenUiComponent component) {
    final data = component.data;
    final errors = <String>[];

    final age = _tryParseNum(data['age']);
    if (age != null && (age < 0 || age > 130)) {
      errors.add('Patient age ($age) is invalid. Must be between 0 and 130 years.');
    }

    if (errors.isNotEmpty) {
      return GenUiValidationResult.failure(errors);
    }
    return GenUiValidationResult.success(component);
  }

  GenUiValidationResult _validateChart(GenUiComponent component) {
    // Insufficient historical data is explicitly permitted and will be handled by the widget
    return GenUiValidationResult.success(component);
  }

  GenUiValidationResult _validateConfirmation(GenUiComponent component) {
    final data = component.data;
    if (!data.containsKey('action') && !data.containsKey('title') && component.actions.isEmpty) {
      return GenUiValidationResult.failure(['Confirmation component must specify target action or title.']);
    }
    return GenUiValidationResult.success(component);
  }

  GenUiValidationResult _validatePatientCard(GenUiComponent component) {
    return GenUiValidationResult.success(component);
  }

  GenUiValidationResult _validateChoiceCard(GenUiComponent component) {
    if (component.options.isEmpty && component.data['options'] == null && component.data['choices'] == null) {
      return GenUiValidationResult.failure(['Choice card must provide at least one option.']);
    }
    return GenUiValidationResult.success(component);
  }

  num? _tryParseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    final str = value.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    return num.tryParse(str);
  }
}

