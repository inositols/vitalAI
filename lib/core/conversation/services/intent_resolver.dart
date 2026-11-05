import '../../../../features/patients/data/models/patient_model.dart';
import '../models/conversation_intent.dart';

/// Natural language and slot extraction engine for clinical voice & text interactions.
class IntentResolver {
  const IntentResolver();

  /// Classifies user utterance into a supported ConversationIntent.
  ConversationIntent classify(String query) {
    final lower = query.toLowerCase().trim();

    // 0. Patient switching / Context selection
    if (lower.startsWith('switch to ') ||
        lower.startsWith("let's work on ") ||
        lower.startsWith('lets work on ') ||
        lower.startsWith('work on ') ||
        lower.startsWith('select patient ') ||
        lower.startsWith('go back to ') ||
        lower == 'switch patient' ||
        lower == 'switch patients' ||
        lower == 'change patient' ||
        lower.startsWith('switch patient to ') ||
        lower.startsWith('change patient to ')) {
      return ConversationIntent.switchPatient;
    }

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
        lower.startsWith('new patient ') ||
        (lower.startsWith('add ') && lower.contains('patient')) ||
        (lower.startsWith('register ') && !lower.contains('appointment')) ||
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
      final nameMatches = _matchPatientInQuery(
        query,
        existingPatients,
        currentActivePatient: currentActivePatient,
      );
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

      case ConversationIntent.switchPatient:
        _extractSwitchPatientSlots(
          query,
          params,
          existingPatients,
          currentActivePatient: currentActivePatient,
        );
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

  List<PatientModel> _matchPatientInQuery(
    String query,
    List<PatientModel> patients, {
    PatientModel? currentActivePatient,
  }) =>
      matchPatientInQuery(
        query,
        patients,
        currentActivePatient: currentActivePatient,
      );

  /// Matches patients mentioned in the query with strict exact-match precedence and stopword filtering.
  List<PatientModel> matchPatientInQuery(
    String query,
    List<PatientModel> patients, {
    PatientModel? currentActivePatient,
  }) {
    final lower = query.toLowerCase().trim();
    if (lower.isEmpty || patients.isEmpty) return [];

    const genericStopwords = {
      'patient',
      'patients',
      'new',
      'user',
      'record',
      'records',
      'history',
      'vital',
      'vitals',
      'summary',
      'summarise',
      'summarize',
      'test',
      'dr',
      'doctor',
      'nurse',
      'mr',
      'mrs',
      'ms',
      'miss',
      'male',
      'female',
      'adult',
      'child',
      'profile',
      'info',
      'information',
      'active',
      'current',
      'view',
      'show',
      'open',
      'check',
      'switch',
      'select',
      'choose',
      'data',
      'chart',
      'details',
      'latest',
    };

    final exactMatches = <PatientModel>[];
    final partialMatches = <PatientModel>[];

    for (final p in patients) {
      final fullName = p.name.toLowerCase().trim();
      if (fullName.isEmpty) continue;

      // 1. Exact full-name match in the query (with boundary or possessive or punctuation)
      final escapedFullName = RegExp.escape(fullName);
      final exactRegex = RegExp(
        '(?:^|\\b|\\s)$escapedFullName(?:\'s|s|\\b|\\s|\$)',
        caseSensitive: false,
      );

      if (exactRegex.hasMatch(lower) || lower == fullName || lower.contains("$fullName's")) {
        exactMatches.add(p);
        continue;
      }

      // 2. Partial name match (first name / last name)
      // Disallow generic clinical stopwords from acting as partial name identifiers!
      final parts = fullName.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
      final firstName = parts.isNotEmpty ? parts.first : '';
      final lastName = parts.length > 1 ? parts.last : '';

      bool matchedPartial = false;

      if (firstName.length > 2 && !genericStopwords.contains(firstName)) {
        final escapedFirst = RegExp.escape(firstName);
        final firstRegex = RegExp('(?:^|\\b|\\s)$escapedFirst(?:\'s|s|\\b|\\s|\$)', caseSensitive: false);
        if (firstRegex.hasMatch(lower)) {
          matchedPartial = true;
        }
      }

      if (!matchedPartial && lastName.length > 2 && !genericStopwords.contains(lastName)) {
        final escapedLast = RegExp.escape(lastName);
        final lastRegex = RegExp('(?:^|\\b|\\s)$escapedLast(?:\'s|s|\\b|\\s|\$)', caseSensitive: false);
        if (lastRegex.hasMatch(lower)) {
          matchedPartial = true;
        }
      }

      if (matchedPartial) {
        partialMatches.add(p);
      }
    }

    // STRICT PRECEDENCE RULE:
    // If there is any exact full-name match, partial single-word matches are discarded!
    if (exactMatches.isNotEmpty) {
      // If the current active patient is among the exact matches, prefer it
      if (currentActivePatient != null &&
          exactMatches.any((p) => p.id == currentActivePatient.id || (p.remoteId.isNotEmpty && p.remoteId == currentActivePatient.remoteId))) {
        return [currentActivePatient];
      }
      return exactMatches;
    }

    // If no exact match, check partial matches
    if (partialMatches.isNotEmpty) {
      if (currentActivePatient != null &&
          partialMatches.any((p) => p.id == currentActivePatient.id || (p.remoteId.isNotEmpty && p.remoteId == currentActivePatient.remoteId))) {
        return [currentActivePatient];
      }
      return partialMatches;
    }

    return [];
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

  void _extractSwitchPatientSlots(
    String query,
    Map<String, dynamic> params,
    List<PatientModel>? existingPatients, {
    PatientModel? currentActivePatient,
  }) {
    final lower = query.toLowerCase().trim();
    String target = lower
        .replaceFirst(RegExp(r"^switch\s+to\s+", caseSensitive: false), '')
        .replaceFirst(RegExp(r"^let'?s\s+work\s+on\s+", caseSensitive: false), '')
        .replaceFirst(RegExp(r"^lets\s+work\s+on\s+", caseSensitive: false), '')
        .replaceFirst(RegExp(r"^work\s+on\s+", caseSensitive: false), '')
        .replaceFirst(RegExp(r"^select\s+patient\s+", caseSensitive: false), '')
        .replaceFirst(RegExp(r"^go\s+back\s+to\s+", caseSensitive: false), '')
        .replaceFirst(RegExp(r"^switch\s+patient\s+to\s+", caseSensitive: false), '')
        .replaceFirst(RegExp(r"^change\s+patient\s+to\s+", caseSensitive: false), '')
        .replaceAll(RegExp(r"'s\s+record.*$", caseSensitive: false), '')
        .replaceAll(RegExp(r"'s\s+file.*$", caseSensitive: false), '')
        .replaceAll(RegExp(r"\s+record.*$", caseSensitive: false), '')
        .replaceAll(RegExp(r"[.?!]", caseSensitive: false), '')
        .trim();

    if (target.isNotEmpty && target != 'patient' && target != 'patients') {
      params['targetPatientName'] = target;
      if (existingPatients != null && existingPatients.isNotEmpty) {
        final matches = _matchPatientInQuery(
          target,
          existingPatients,
          currentActivePatient: currentActivePatient,
        );
        if (matches.length == 1) {
          params['patientId'] = matches.first.id;
          params['patientName'] = matches.first.name;
        } else if (matches.length > 1) {
          params['isPatientAmbiguous'] = true;
        }
      }
    }
  }

  void _extractPatientCreationSlots(String query, Map<String, dynamic> params) {
    final lower = query.toLowerCase();

    // 1. Name extraction
    // Look for explicit markers like "called <Name>", "named <Name>", "patient <Name>", or "add/create <Name>"
    final nameLookahead = r'(?=\.|\,|\s+(?:she|he|who|aged|age|is|with|phone|email|dob|born|\d)|$)';
    final calledMatch = RegExp(r'(?:called|named)\s+([A-Za-z]+(?:\s+[A-Za-z]+)+?)' + nameLookahead, caseSensitive: false).firstMatch(query);
    final patientMatch = RegExp(r'(?:patient)\s+(?:called\s+|named\s+)?([A-Za-z]+(?:\s+[A-Za-z]+)+?)' + nameLookahead, caseSensitive: false).firstMatch(query);
    final createMatch = RegExp(r'(?:create|register|add)\s+(?:a\s+)?(?:new\s+)?(?:patient\s+)?(?:called\s+|named\s+)?([A-Za-z]+(?:\s+[A-Za-z]+)+?)' + nameLookahead, caseSensitive: false).firstMatch(query);
    final directNameMatch = RegExp(r'(?:named|called)\s+([A-Za-z]+(?:\s+[A-Za-z]+)+)', caseSensitive: false).firstMatch(query);

    final rawName = calledMatch?.group(1) ?? patientMatch?.group(1) ?? createMatch?.group(1) ?? directNameMatch?.group(1);
    if (rawName != null && rawName.trim().length >= 2) {
      // Capitalize name to title case
      params['name'] = rawName.trim().split(RegExp(r'\s+')).map((w) {
        if (w.isEmpty) return '';
        return w[0].toUpperCase() + w.substring(1).toLowerCase();
      }).join(' ');
    }

    // 2. Age extraction: "28 years old", "28 yo", "aged 28", "age 28", "is 28"
    final ageRegex = RegExp(
      r'(?:is|aged|age|she is|he is)?\s*(\d{1,3})\s*(?:years?\s*old|yo|age\b)',
      caseSensitive: false,
    );
    final ageMatch = ageRegex.firstMatch(query);
    if (ageMatch != null) {
      final parsedAge = int.tryParse(ageMatch.group(1)!);
      if (parsedAge != null && parsedAge > 0 && parsedAge < 130) {
        params['age'] = parsedAge;
        params['dateOfBirth'] = DateTime(DateTime.now().year - parsedAge, 1, 1);
      }
    }

    // 3. Date of birth (explicit date format if present)
    final dob = _parseDate(query);
    if (dob != null) {
      params['dateOfBirth'] = dob;
    }

    // 4. Biological sex
    if (RegExp(r'\b(?:she|her|female|woman|girl)\b', caseSensitive: false).hasMatch(query)) {
      params['gender'] = 'Female';
    } else if (RegExp(r'\b(?:he|him|his|male|man|boy)\b', caseSensitive: false).hasMatch(query)) {
      params['gender'] = 'Male';
    }

    // 5. Presenting complaint & symptom duration
    final complaintRegex = RegExp(
      r'(?:complaining of|complaint of|came in with|presented with|suffering from)\s+([^.]+)',
      caseSensitive: false,
    );
    final complaintMatch = complaintRegex.firstMatch(query);
    if (complaintMatch != null) {
      params['complaint'] = complaintMatch.group(1)!.trim();
    }

    final durationRegex = RegExp(
      r'(?:lasted|for|duration of)\s+(\d+|one|two|three|four|five|six|seven|eight|nine|ten)\s+(days?|weeks?|months?|hours?)',
      caseSensitive: false,
    );
    final durationMatch = durationRegex.firstMatch(query);
    if (durationMatch != null) {
      params['duration'] = durationMatch.group(0)!.trim();
    }

    // 6. Email
    final emailRegex = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
    final emailMatch = emailRegex.firstMatch(query);
    if (emailMatch != null) {
      params['email'] = emailMatch.group(0);
    }

    // 7. Phone
    final phoneRegex = RegExp(r'(?:phone(?:\s*number)?(?:\s*is)?\s*)?(\+?[0-9][0-9\s-]{7,15}[0-9])', caseSensitive: false);
    final phoneMatch = phoneRegex.firstMatch(query);
    if (phoneMatch != null) {
      params['phone'] = phoneMatch.group(1)!.replaceAll(RegExp(r'[\s-]'), '');
    }

    // 8. Embedded Vitals (e.g. BP 118/76, temperature 37.2)
    _extractVitalsSlots(query, params);
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

    // If the user requested a summary or complete history, prefill all categories
    if (categories.isEmpty &&
        (lower.contains('summar') || lower.contains('complete history'))) {
      categories.addAll(['vitals', 'notes', 'visits', 'medications']);
    }

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
