import '../../../../features/patients/data/models/patient_model.dart';
import '../models/conversation_intent.dart';

/// Natural language and slot extraction engine for clinical voice & text interactions.
class IntentResolver {
  const IntentResolver();

  /// Classifies user utterance into a supported ConversationIntent.
  ConversationIntent classify(String query) {
    final lower = query.toLowerCase().trim();

    // 1. Patient creation
    if (lower.contains('create a new patient') ||
        lower.contains('create patient') ||
        lower.contains('create a patient') ||
        lower.contains('add a new patient') ||
        lower.contains('add a patient') ||
        lower.contains('register a patient') ||
        lower.contains('register patient') ||
        lower.contains('start creating a patient') ||
        lower.contains('record for someone i just saw') ||
        (lower.startsWith('add ') && lower.contains('patient')) ||
        (lower.startsWith('create ') &&
            !lower.contains('note') &&
            !lower.contains('chart') &&
            !lower.contains('appointment') &&
            !lower.contains('reminder'))) {
      return ConversationIntent.createPatient;
    }

    // 2. Compare Vital Readings / Trend analysis
    if (lower.contains('compare') ||
        lower.contains('trend') ||
        lower.contains('last week to this week') ||
        lower.contains('last seven days') ||
        lower.contains('7 days vs') ||
        lower.contains('compare readings')) {
      return ConversationIntent.compareVitals;
    }

    // 3. Appointments & Follow-up reminders
    if (lower.contains('appointment') ||
        lower.contains('schedule') ||
        lower.contains('reminder') ||
        lower.contains('set follow up') ||
        lower.contains('follow-up visit') ||
        lower.contains('reschedule') ||
        lower.contains('cancel appointment') ||
        lower.contains('book a visit')) {
      return ConversationIntent.manageAppointments;
    }

    // 4. Clinical Note drafting & encounter documentation
    if (lower.contains('draft a note') ||
        lower.contains('draft note') ||
        lower.contains('clinical note') ||
        lower.contains('visit note') ||
        lower.contains('soap note') ||
        lower.contains('add a note') ||
        lower.contains('add note') ||
        lower.contains('document visit') ||
        lower.contains('encounter note')) {
      return ConversationIntent.draftClinicalNote;
    }

    // 5. Patient history, timeline & summaries
    if (lower.contains('history') ||
        lower.contains('medical history') ||
        lower.contains('patient summary') ||
        lower.contains('timeline') ||
        lower.contains('review visits') ||
        lower.contains('past records') ||
        lower.contains('encounter history')) {
      return ConversationIntent.queryPatientHistory;
    }

    // 6. Record Vital Signs (blood pressure, pulse, temp, glucose)
    if ((lower.contains('record') ||
            lower.contains('log') ||
            lower.contains('add') ||
            lower.contains('take')) &&
        (lower.contains('blood pressure') ||
            lower.contains('bp') ||
            lower.contains('reading') ||
            lower.contains('heart rate') ||
            lower.contains('pulse') ||
            lower.contains('temperature') ||
            lower.contains('glucose') ||
            RegExp(r'\d{2,3}\s*(over|/)\s*\d{2,3}').hasMatch(lower))) {
      return ConversationIntent.recordVitals;
    }

    // Direct BP pattern: "118 over 76", "120/80"
    if (RegExp(r'\d{2,3}\s*(over|/)\s*\d{2,3}').hasMatch(lower)) {
      return ConversationIntent.recordVitals;
    }

    // 7. Update patient info
    if ((lower.contains('update') || lower.contains('change') || lower.contains('edit')) &&
        (lower.contains('phone') ||
            lower.contains('contact') ||
            lower.contains('email') ||
            lower.contains('address') ||
            lower.contains('details'))) {
      return ConversationIntent.updatePatientInfo;
    }

    // 8. Open patient details / vitals chart
    if (lower.contains('open ') ||
        lower.contains('show ') ||
        lower.contains('view ') ||
        lower.contains('latest vitals') ||
        lower.contains('patient chart')) {
      return ConversationIntent.openPatientDetails;
    }

    // 9. Search / find patient
    if (lower.contains('find patient') ||
        lower.contains('search patient') ||
        lower.contains('look up patient') ||
        lower.contains('search for ')) {
      return ConversationIntent.findPatient;
    }

    return ConversationIntent.generalQuery;
  }

  /// Extracts structured parameters from natural language for a target intent.
  ExtractionResult extractParameters(
    String query,
    ConversationIntent intent, {
    List<PatientModel>? existingPatients,
    PatientModel? currentActivePatient,
  }) {
    final params = <String, dynamic>{};
    final candidates = <PatientModel>[];
    PatientModel? resolvedPatient = currentActivePatient;

    // 1. Resolve Patient Identity from utterance
    if (existingPatients != null && existingPatients.isNotEmpty) {
      final nameMatches = _matchPatientInQuery(query, existingPatients);
      if (nameMatches.length == 1) {
        resolvedPatient = nameMatches.first;
        params['patientId'] = resolvedPatient.id;
        params['patientName'] = resolvedPatient.name;
      } else if (nameMatches.length > 1) {
        candidates.addAll(nameMatches);
        params['isPatientAmbiguous'] = true;
      } else if (currentActivePatient != null) {
        resolvedPatient = currentActivePatient;
        params['patientId'] = resolvedPatient.id;
        params['patientName'] = resolvedPatient.name;
      }
    } else if (currentActivePatient != null) {
      resolvedPatient = currentActivePatient;
      params['patientId'] = resolvedPatient.id;
      params['patientName'] = resolvedPatient.name;
    }

    // 2. Extract Intent-Specific Parameters
    switch (intent) {
      case ConversationIntent.recordVitals:
        _extractVitalsSlots(query, params);
        break;

      case ConversationIntent.compareVitals:
        _extractComparisonSlots(query, params);
        break;

      case ConversationIntent.createPatient:
        _extractPatientCreationSlots(query, params);
        break;

      case ConversationIntent.draftClinicalNote:
        _extractClinicalNoteSlots(query, params);
        break;

      case ConversationIntent.manageAppointments:
        _extractAppointmentSlots(query, params);
        break;

      case ConversationIntent.queryPatientHistory:
        _extractHistorySlots(query, params);
        break;

      case ConversationIntent.updatePatientInfo:
        _extractUpdatePatientSlots(query, params);
        break;

      default:
        break;
    }

    return ExtractionResult(
      parameters: params,
      resolvedPatient: resolvedPatient,
      candidatePatients: candidates,
    );
  }

  List<PatientModel> _matchPatientInQuery(String query, List<PatientModel> patients) {
    final lower = query.toLowerCase();
    final matches = <PatientModel>[];

    for (final p in patients) {
      final fullName = p.name.toLowerCase();
      final firstName = fullName.split(' ').first;
      final lastName = fullName.split(' ').length > 1 ? fullName.split(' ').last : '';

      if (lower.contains(fullName) ||
          lower.contains("$fullName's") ||
          (firstName.length > 2 && (lower.contains(firstName) || lower.contains("$firstName's"))) ||
          (lastName.length > 2 && (lower.contains(lastName) || lower.contains("$lastName's")))) {
        matches.add(p);
      }
    }

    return matches;
  }

  void _extractVitalsSlots(String query, Map<String, dynamic> params) {
    final lower = query.toLowerCase();

    // Blood pressure: "118 over 76", "118/76", "118 76"
    final slashRegex = RegExp(r'(\d{2,3})\s*/\s*(\d{2,3})');
    final overRegex = RegExp(r'(\d{2,3})\s*(?:over)\s*(\d{2,3})', caseSensitive: false);

    final match = overRegex.firstMatch(query) ?? slashRegex.firstMatch(query);
    if (match != null) {
      final sys = double.tryParse(match.group(1)!);
      final dia = double.tryParse(match.group(2)!);
      if (sys != null && dia != null) {
        params['systolic'] = sys;
        params['diastolic'] = dia;
      }
    } else {
      // Check if only systolic was provided: "record systolic 130" or "bp 120"
      final sysOnlyRegex = RegExp(r'(?:systolic|bp|blood pressure)\s*(?:is|as)?\s*(\d{2,3})', caseSensitive: false);
      final sysMatch = sysOnlyRegex.firstMatch(query);
      if (sysMatch != null) {
        params['systolic'] = double.tryParse(sysMatch.group(1)!);
      }
    }

    // Pulse / Heart Rate
    final pulseRegex = RegExp(r'(?:pulse|heart rate|hr)\s*(?:is|as|of)?\s*(\d{2,3})(?:\s*bpm)?', caseSensitive: false);
    final pulseMatch = pulseRegex.firstMatch(query);
    if (pulseMatch != null) {
      params['pulseRate'] = double.tryParse(pulseMatch.group(1)!);
    }

    // Temperature
    final tempRegex = RegExp(r'(?:temp|temperature)\s*(?:is|as|of)?\s*(\d{2,3}(?:\.\d)?)\s*(c|f|degrees)?', caseSensitive: false);
    final tempMatch = tempRegex.firstMatch(query);
    if (tempMatch != null) {
      params['bodyTemperature'] = double.tryParse(tempMatch.group(1)!);
      final unit = tempMatch.group(2)?.toLowerCase();
      if (unit == 'f') {
        params['tempUnit'] = 'F';
      } else if (unit == 'c') {
        params['tempUnit'] = 'C';
      }
    }

    // Observation Date
    if (lower.contains("today's visit") || lower.contains('today') || lower.contains('this morning')) {
      params['date'] = DateTime.now();
      params['dateLabel'] = 'Today';
    } else if (lower.contains('yesterday')) {
      params['date'] = DateTime.now().subtract(const Duration(days: 1));
      params['dateLabel'] = 'Yesterday';
    }
  }

  void _extractComparisonSlots(String query, Map<String, dynamic> params) {
    final lower = query.toLowerCase();
    if (lower.contains('last week to this week') || lower.contains('last week') || lower.contains('7 days')) {
      params['dateRange'] = '7_days';
      params['rangeLabel'] = 'Last 7 Days vs Previous 7 Days';
    } else if (lower.contains('30 days') || lower.contains('month')) {
      params['dateRange'] = '30_days';
      params['rangeLabel'] = 'Last 30 Days';
    } else {
      params['dateRange'] = '7_days';
      params['rangeLabel'] = 'Last 7 Days vs Previous 7 Days';
    }
  }

  void _extractPatientCreationSlots(String query, Map<String, dynamic> params) {
    final lower = query.toLowerCase();

    // Name extraction
    final namePattern = RegExp(r'(?:patient|named|create|register|add)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)');
    final nameMatch = namePattern.firstMatch(query);
    if (nameMatch != null) {
      params['name'] = nameMatch.group(1)!.trim();
    }

    // Email
    final emailRegex = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
    final emailMatch = emailRegex.firstMatch(query);
    if (emailMatch != null) {
      params['email'] = emailMatch.group(0);
    }

    // Phone
    final phoneRegex = RegExp(r'(?:phone(?:\s*number)?(?:\s*is)?\s*)?(\+?[0-9][0-9\s-]{7,15}[0-9])', caseSensitive: false);
    final phoneMatch = phoneRegex.firstMatch(query);
    if (phoneMatch != null) {
      params['phone'] = phoneMatch.group(1)!.replaceAll(RegExp(r'[\s-]'), '');
    }

    // Biological sex
    if (lower.contains(' female') || lower.contains('woman') || lower.contains('girl')) {
      params['gender'] = 'Female';
    } else if (lower.contains(' male') || lower.contains(' man ') || lower.contains('boy')) {
      params['gender'] = 'Male';
    }

    // Date of birth
    final dob = _parseDate(query);
    if (dob != null) {
      params['dateOfBirth'] = dob;
    }
  }

  void _extractClinicalNoteSlots(String query, Map<String, dynamic> params) {
    final lower = query.toLowerCase();

    // Visit type
    if (lower.contains('soap')) {
      params['visitType'] = 'SOAP Note';
    } else if (lower.contains('follow-up') || lower.contains('follow up')) {
      params['visitType'] = 'Follow-up Consultation';
    } else if (lower.contains('urgent') || lower.contains('emergency')) {
      params['visitType'] = 'Urgent Care';
    } else if (lower.contains('routine') || lower.contains('annual')) {
      params['visitType'] = 'Routine Checkup';
    } else if (lower.contains('general consultation') || lower.contains('general consult')) {
      params['visitType'] = 'General Consultation';
    }

    // Extract content if provider dictation includes observations
    final forIndex = lower.indexOf('note:');
    if (forIndex != -1 && forIndex + 5 < query.length) {
      params['content'] = query.substring(forIndex + 5).trim();
    } else {
      final thatIndex = lower.indexOf('saying ');
      if (thatIndex != -1 && thatIndex + 7 < query.length) {
        params['content'] = query.substring(thatIndex + 7).trim();
      }
    }
  }

  void _extractAppointmentSlots(String query, Map<String, dynamic> params) {
    final lower = query.toLowerCase();

    // Title / Reason
    if (lower.contains('blood pressure') || lower.contains('bp check')) {
      params['title'] = 'Blood Pressure Check';
    } else if (lower.contains('medication') || lower.contains('refill')) {
      params['title'] = 'Medication Review';
    } else if (lower.contains('lab') || lower.contains('test')) {
      params['title'] = 'Lab Results Review';
    } else if (lower.contains('routine') || lower.contains('checkup')) {
      params['title'] = 'Routine Consultation';
    }

    // Time
    final timeRegex = RegExp(r'(\d{1,2}(?::\d{2})?\s*(?:am|pm))', caseSensitive: false);
    final timeMatch = timeRegex.firstMatch(query);
    if (timeMatch != null) {
      params['time'] = timeMatch.group(1)!.toUpperCase();
    } else if (lower.contains('morning')) {
      params['time'] = '09:00 AM';
    } else if (lower.contains('afternoon')) {
      params['time'] = '02:00 PM';
    } else if (lower.contains('evening')) {
      params['time'] = '05:00 PM';
    }
  }

  void _extractHistorySlots(String query, Map<String, dynamic> params) {
    final lower = query.toLowerCase();

    // Timeframe
    if (lower.contains('last 7 days') || lower.contains('past week')) {
      params['timeframe'] = '7_days';
    } else if (lower.contains('last 30 days') || lower.contains('past month')) {
      params['timeframe'] = '30_days';
    } else {
      params['timeframe'] = 'all_time';
    }

    // Categories
    final categories = <String>[];
    if (lower.contains('vitals') || lower.contains('bp') || lower.contains('readings')) categories.add('vitals');
    if (lower.contains('notes') || lower.contains('soap')) categories.add('notes');
    if (lower.contains('visits') || lower.contains('encounters')) categories.add('visits');
    if (lower.contains('meds') || lower.contains('medications')) categories.add('medications');
    if (categories.isNotEmpty) {
      params['categories'] = categories;
    }
  }

  void _extractUpdatePatientSlots(String query, Map<String, dynamic> params) {
    final lower = query.toLowerCase();

    if (lower.contains('phone')) {
      params['updatedField'] = 'phone';
      final phoneRegex = RegExp(r'(\+?[0-9][0-9\s-]{7,15}[0-9])');
      final match = phoneRegex.firstMatch(query);
      if (match != null) {
        params['newValue'] = match.group(1)!.replaceAll(RegExp(r'[\s-]'), '');
      }
    } else if (lower.contains('email')) {
      params['updatedField'] = 'email';
      final emailRegex = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
      final match = emailRegex.firstMatch(query);
      if (match != null) {
        params['newValue'] = match.group(0);
      }
    } else if (lower.contains('emergency')) {
      params['updatedField'] = 'emergencyContact';
    }
  }

  DateTime? _parseDate(String input) {
    final lower = input.toLowerCase();
    // Format: 12 March 1998
    final monthNames = [
      'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december'
    ];
    for (int i = 0; i < monthNames.length; i++) {
      final m = monthNames[i];
      if (lower.contains(m)) {
        final regex = RegExp('(\\d{1,2})\\s+$m\\s+(\\d{4})');
        final match = regex.firstMatch(lower);
        if (match != null) {
          final day = int.tryParse(match.group(1)!);
          final year = int.tryParse(match.group(2)!);
          if (day != null && year != null) {
            return DateTime(year, i + 1, day);
          }
        }
      }
    }
    // Format: YYYY-MM-DD
    final isoRegex = RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})');
    final isoMatch = isoRegex.firstMatch(input);
    if (isoMatch != null) {
      final year = int.tryParse(isoMatch.group(1)!);
      final month = int.tryParse(isoMatch.group(2)!);
      final day = int.tryParse(isoMatch.group(3)!);
      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }
}

class ExtractionResult {
  final Map<String, dynamic> parameters;
  final PatientModel? resolvedPatient;
  final List<PatientModel> candidatePatients;

  const ExtractionResult({
    required this.parameters,
    this.resolvedPatient,
    this.candidatePatients = const [],
  });

  bool get isPatientAmbiguous => candidatePatients.length > 1;
}
