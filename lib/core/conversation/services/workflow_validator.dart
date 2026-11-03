import '../models/conversation_intent.dart';

/// Clinical domain validator ensuring data integrity before persistence.
class WorkflowValidator {
  const WorkflowValidator();

  /// Validate parameters for a given intent. Returns map of {field: errorMessage}.
  Map<String, String> validate(ConversationIntent intent, Map<String, dynamic> params) {
    final errors = <String, String>{};

    switch (intent) {
      case ConversationIntent.recordVitals:
        _validateVitals(params, errors);
        break;

      case ConversationIntent.createPatient:
        _validatePatientCreation(params, errors);
        break;

      case ConversationIntent.updatePatientInfo:
        _validatePatientUpdate(params, errors);
        break;

      case ConversationIntent.draftClinicalNote:
        _validateClinicalNote(params, errors);
        break;

      case ConversationIntent.manageAppointments:
        _validateAppointment(params, errors);
        break;

      default:
        break;
    }

    return errors;
  }

  void _validateVitals(Map<String, dynamic> params, Map<String, String> errors) {
    // Systolic
    if (params.containsKey('systolic') && params['systolic'] != null) {
      final sys = (params['systolic'] as num).toDouble();
      if (sys < 60 || sys > 300) {
        errors['systolic'] = 'Systolic blood pressure must be between 60 and 300 mmHg.';
      }
    }

    // Diastolic
    if (params.containsKey('diastolic') && params['diastolic'] != null) {
      final dia = (params['diastolic'] as num).toDouble();
      if (dia < 30 || dia > 200) {
        errors['diastolic'] = 'Diastolic blood pressure must be between 30 and 200 mmHg.';
      }
    }

    // Systolic vs Diastolic logic
    if (params['systolic'] != null && params['diastolic'] != null) {
      final sys = (params['systolic'] as num).toDouble();
      final dia = (params['diastolic'] as num).toDouble();
      if (sys <= dia) {
        errors['systolic'] = 'Systolic reading ($sys) must be higher than diastolic reading ($dia).';
      }
    }

    // Pulse Rate (optional)
    if (params.containsKey('pulseRate') && params['pulseRate'] != null) {
      final pulse = (params['pulseRate'] as num).toDouble();
      if (pulse < 30 || pulse > 250) {
        errors['pulseRate'] = 'Pulse rate must be between 30 and 250 bpm.';
      }
    }

    // Body Temperature (optional)
    if (params.containsKey('bodyTemperature') && params['bodyTemperature'] != null) {
      final temp = (params['bodyTemperature'] as num).toDouble();
      final unit = params['tempUnit']?.toString() ?? 'C';
      if (unit.toUpperCase() == 'F' || temp > 50) {
        if (temp < 85 || temp > 115) {
          errors['bodyTemperature'] = 'Temperature in Fahrenheit must be between 85°F and 115°F.';
        }
      } else {
        if (temp < 30 || temp > 45) {
          errors['bodyTemperature'] = 'Temperature in Celsius must be between 30°C and 45°C.';
        }
      }
    }
  }

  void _validatePatientCreation(Map<String, dynamic> params, Map<String, String> errors) {
    // Name
    if (params.containsKey('name')) {
      final name = params['name']?.toString().trim() ?? '';
      if (name.length < 2) {
        errors['name'] = 'Please enter a valid patient full name (at least 2 letters).';
      }
    }

    // Date of Birth
    if (params.containsKey('dateOfBirth') && params['dateOfBirth'] != null) {
      final dob = params['dateOfBirth'] is DateTime
          ? params['dateOfBirth'] as DateTime
          : DateTime.tryParse(params['dateOfBirth'].toString());
      if (dob == null) {
        errors['dateOfBirth'] = 'Invalid date format. Use "12 March 1998" or "YYYY-MM-DD".';
      } else if (dob.isAfter(DateTime.now())) {
        errors['dateOfBirth'] = 'Date of birth cannot be in the future.';
      }
    }

    // Phone
    if (params.containsKey('phone') && params['phone'] != null) {
      final raw = params['phone'].toString().replaceAll(RegExp(r'[^0-9+]'), '');
      if (raw.isNotEmpty && (raw.length < 7 || raw.length > 15)) {
        errors['phone'] = 'Please enter a valid telephone number (7-15 digits).';
      }
    }

    // Email
    if (params.containsKey('email') && params['email'] != null) {
      final email = params['email'].toString().trim();
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (email.isNotEmpty && !emailRegex.hasMatch(email)) {
        errors['email'] = 'Please enter a valid email address (e.g. patient@example.com).';
      }
    }
  }

  void _validatePatientUpdate(Map<String, dynamic> params, Map<String, String> errors) {
    if (!params.containsKey('updatedField') || params['updatedField'] == null) {
      errors['updatedField'] = 'Please select a field to update.';
    }
    if (!params.containsKey('newValue') || params['newValue']?.toString().trim().isEmpty == true) {
      errors['newValue'] = 'Updated value cannot be empty.';
    }
  }

  void _validateClinicalNote(Map<String, dynamic> params, Map<String, String> errors) {
    if (params.containsKey('content')) {
      final content = params['content']?.toString().trim() ?? '';
      if (content.length < 3) {
        errors['content'] = 'Clinical note must contain clinical observations or summary.';
      }
    }
  }

  void _validateAppointment(Map<String, dynamic> params, Map<String, String> errors) {
    if (params.containsKey('title')) {
      final title = params['title']?.toString().trim() ?? '';
      if (title.isEmpty) {
        errors['title'] = 'Please specify the appointment or reminder reason.';
      }
    }
    if (params.containsKey('time')) {
      final time = params['time']?.toString().trim() ?? '';
      if (time.isEmpty) {
        errors['time'] = 'Please specify the scheduled time.';
      }
    }
  }
}
