/// PatientModel represents the patient profile data structure.
class PatientModel {
  PatientModel();

  /// Local database ID.
  int id = 0;

  /// Unique remote identifier for Firestore synchronization.
  late String remoteId;

  /// Full name of the patient.
  late String name;

  /// Gender string (e.g. Male, Female, Other).
  late String gender;

  /// Date of birth.
  late DateTime dateOfBirth;

  /// Height in metric or imperial value.
  late double height;

  /// Weight in metric or imperial value.
  late double weight;

  /// Emergency contact information (name, phone number).
  late String emergencyContact;

  /// List of current medical conditions.
  List<String> medicalConditions = [];

  /// List of known allergies.
  List<String> allergies = [];

  /// List of current medications.
  List<String> medications = [];

  /// Doctor's name or clinic details.
  String? doctorName;

  /// Doctor's phone number.
  String? doctorPhone;

  /// Additional notes (e.g. blood type, medical history notes).
  String? notes;

  /// Synchronization status flag.
  late bool isSynced;

  /// Local timestamp when the record was last modified.
  late DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'remoteId': remoteId,
      'name': name,
      'gender': gender,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'height': height,
      'weight': weight,
      'emergencyContact': emergencyContact,
      'medicalConditions': medicalConditions,
      'allergies': allergies,
      'medications': medications,
      'doctorName': doctorName,
      'doctorPhone': doctorPhone,
      'notes': notes,
      'isSynced': isSynced,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel()
      ..id = json['id'] as int
      ..remoteId = json['remoteId'] as String
      ..name = json['name'] as String
      ..gender = json['gender'] as String
      ..dateOfBirth = DateTime.parse(json['dateOfBirth'] as String)
      ..height = (json['height'] as num).toDouble()
      ..weight = (json['weight'] as num).toDouble()
      ..emergencyContact = json['emergencyContact'] as String
      ..medicalConditions = List<String>.from(json['medicalConditions'] ?? [])
      ..allergies = List<String>.from(json['allergies'] ?? [])
      ..medications = List<String>.from(json['medications'] ?? [])
      ..doctorName = json['doctorName'] as String?
      ..doctorPhone = json['doctorPhone'] as String?
      ..notes = json['notes'] as String?
      ..isSynced = json['isSynced'] as bool
      ..updatedAt = DateTime.parse(json['updatedAt'] as String);
  }
}

