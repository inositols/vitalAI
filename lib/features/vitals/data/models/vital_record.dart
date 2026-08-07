import 'package:uuid/uuid.dart';

/// VitalRecord represents local and calculated health vitals readings.
class VitalRecord {
  /// Local autoincrement ID.
  int id = 0;

  /// Remote ID for cloud sync.
  late String remoteId;

  /// Foreign key link to the active Patient profile's local ID.
  late int patientId;

  /// Timestamp when the reading was taken.
  late DateTime dateTime;

  // Vitals measurements (stored as nullables since users can log them individually)
  
  /// Blood Pressure - Systolic value (mmHg).
  double? systolic;

  /// Blood Pressure - Diastolic value (mmHg).
  double? diastolic;

  /// Blood Glucose level (mg/dL or mmol/L depending on settings).
  double? glucoseValue;

  /// Glucose reading context: fasting, random, before_meal, after_meal.
  String? glucoseMealContext;

  /// Pulse/Heart rate (BPM).
  double? pulseRate;

  /// Oxygen Saturation SpO₂ (percentage).
  double? oxygenSaturation;

  /// Body Temperature (°C or °F depending on settings).
  double? bodyTemperature;

  /// Body Weight (kg or lbs depending on settings).
  double? weight;

  /// Calculated Body Mass Index (BMI = kg / m^2).
  double? bmi;

  /// Optional personal comment or context.
  String? note;

  /// Optional hardware device identifier (e.g. Omron, Dexcom).
  String? deviceUsed;

  /// Searchable categorization tags (e.g. "morning", "after exercise").
  List<String> tags = [];

  /// Sync verification state.
  late bool isSynced;

  /// Local update timestamp.
  late DateTime updatedAt;

  VitalRecord() {
    remoteId = const Uuid().v4();
    patientId = 0;
    dateTime = DateTime.now();
    isSynced = false;
    updatedAt = DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'remoteId': remoteId,
      'patientId': patientId,
      'dateTime': dateTime.toIso8601String(),
      'systolic': systolic,
      'diastolic': diastolic,
      'glucoseValue': glucoseValue,
      'glucoseMealContext': glucoseMealContext,
      'pulseRate': pulseRate,
      'oxygenSaturation': oxygenSaturation,
      'bodyTemperature': bodyTemperature,
      'weight': weight,
      'bmi': bmi,
      'note': note,
      'deviceUsed': deviceUsed,
      'tags': tags,
      'isSynced': isSynced,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory VitalRecord.fromJson(Map<String, dynamic> json) {
    return VitalRecord()
      ..id = json['id'] as int? ?? 0
      ..remoteId = json['remoteId'] as String? ?? const Uuid().v4()
      ..patientId = json['patientId'] as int? ?? 0
      ..dateTime = json['dateTime'] != null
          ? DateTime.parse(json['dateTime'] as String)
          : DateTime.now()
      ..systolic = (json['systolic'] as num?)?.toDouble()
      ..diastolic = (json['diastolic'] as num?)?.toDouble()
      ..glucoseValue = (json['glucoseValue'] as num?)?.toDouble()
      ..glucoseMealContext = json['glucoseMealContext'] as String?
      ..pulseRate = (json['pulseRate'] as num?)?.toDouble()
      ..oxygenSaturation = (json['oxygenSaturation'] as num?)?.toDouble()
      ..bodyTemperature = (json['bodyTemperature'] as num?)?.toDouble()
      ..weight = (json['weight'] as num?)?.toDouble()
      ..bmi = (json['bmi'] as num?)?.toDouble()
      ..note = json['note'] as String?
      ..deviceUsed = json['deviceUsed'] as String?
      ..tags = List<String>.from(json['tags'] ?? [])
      ..isSynced = json['isSynced'] as bool? ?? false
      ..updatedAt = json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now();
  }
}
