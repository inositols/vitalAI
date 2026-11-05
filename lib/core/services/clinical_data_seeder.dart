import 'package:vitalai/features/patients/data/models/patient_model.dart';
import 'package:vitalai/features/patients/data/models/clinical_note.dart';
import 'package:vitalai/features/vitals/data/models/vital_record.dart';
import 'package:vitalai/features/activity/data/models/activity_item.dart';
import 'package:vitalai/core/database/db_service.dart';

/// Seeds realistic clinical demo data for healthcare providers.
/// Matches the VoiceVitals UI specifications.
class ClinicalDataSeeder {
  /// Purges all pre-seeded demo clinical data from the database.
  /// Leaves only user-added patients, or leaves the database completely clean.
  static Future<void> purgeDemoPatients(DbService dbService) async {
    final patients = await dbService.getPatients();
    const demoRemoteIds = {
      'CV-10024',
      'CV-10025',
      'CV-10026',
      'CV-10027',
      'CV-10028',
    };
    const demoNames = {
      'chika okafor',
      'emeka nwosu',
      'ngozi eze',
      'tunde bello',
      'chinelo obi',
      'user',
    };

    final demoIds = <int>{};
    for (final p in patients) {
      final nameLower = p.name.trim().toLowerCase();
      if (demoRemoteIds.contains(p.remoteId) ||
          demoNames.contains(nameLower) ||
          p.remoteId.startsWith('CV-1002')) {
        demoIds.add(p.id);
      }
    }

    final remainingPatients = patients.where((p) => !demoIds.contains(p.id)).toList();
    await dbService.savePatients(remainingPatients);

    // Remove vitals for purged demo patients
    final vitals = await dbService.getVitals();
    final remainingVitals = vitals.where((v) => !demoIds.contains(v.patientId)).toList();
    await dbService.saveVitals(remainingVitals);

    // Remove clinical notes and conversations for purged demo patients
    for (final id in demoIds) {
      await dbService.saveClinicalNotes(id, []);
      await dbService.clearConversations(id);
    }
  }

  static Future<void> seedDefaultClinicalData(DbService dbService) async {
    final existingPatients = await dbService.getPatients();
    if (existingPatients.isNotEmpty) return;

    // 1. Seed Patients
    final patients = getDemoPatients();
    await dbService.savePatients(patients);

    // 2. Seed Vitals for Chika Okafor and other patients
    final vitals = getDemoVitals();
    await dbService.saveVitals(vitals);

    // 3. Seed Clinical Notes
    for (final p in patients) {
      final notes = getDemoNotes(p.id, p.name);
      await dbService.saveClinicalNotes(p.id, notes);
    }

    // 4. Seed Activity Log
    final activities = getDemoActivities();
    await dbService.saveActivities(activities);
  }

  static List<PatientModel> getDemoPatients() {
    return [
      PatientModel()
        ..id = 1
        ..remoteId = 'CV-10024'
        ..name = 'Chika Okafor'
        ..gender = 'Female'
        ..dateOfBirth = DateTime(1991, 5, 14)
        ..height = 168.0
        ..weight = 64.0
        ..emergencyContact = 'Emeka Okafor (+234 803 123 4567)'
        ..medicalConditions = ['Hypertension']
        ..allergies = ['Penicillin']
        ..medications = ['Amlodipine 5mg QD', 'Lisinopril 10mg QD']
        ..doctorName = 'Dr. Adeyemi'
        ..notes = 'Stage 1 essential hypertension. Regular BP tracking recommended.'
        ..isSynced = true
        ..updatedAt = DateTime(2025, 4, 22, 10, 30),

      PatientModel()
        ..id = 2
        ..remoteId = 'CV-10025'
        ..name = 'Emeka Nwosu'
        ..gender = 'Male'
        ..dateOfBirth = DateTime(1973, 8, 20)
        ..height = 175.0
        ..weight = 82.0
        ..emergencyContact = 'Ada Nwosu (+234 802 987 6543)'
        ..medicalConditions = ['Diabetes', 'Metabolic Syndrome']
        ..allergies = ['Sulfa drugs']
        ..medications = ['Metformin 500mg BID']
        ..doctorName = 'Dr. Adeyemi'
        ..notes = 'Type 2 Diabetes. Follow up on glycemic control.'
        ..isSynced = true
        ..updatedAt = DateTime(2025, 4, 18, 11, 00),

      PatientModel()
        ..id = 3
        ..remoteId = 'CV-10026'
        ..name = 'Ngozi Eze'
        ..gender = 'Female'
        ..dateOfBirth = DateTime(1997, 2, 10)
        ..height = 162.0
        ..weight = 68.0
        ..emergencyContact = 'Kelechi Eze (+234 805 333 4444)'
        ..medicalConditions = ['Pregnancy (24 wks)']
        ..allergies = ['None known']
        ..medications = ['Prenatal Multivitamin', 'Iron & Folic Acid']
        ..doctorName = 'Dr. Adeyemi'
        ..notes = 'Routine second-trimester prenatal care. Monitor blood pressure for preeclampsia screening.'
        ..isSynced = true
        ..updatedAt = DateTime(2025, 4, 15, 14, 30),

      PatientModel()
        ..id = 4
        ..remoteId = 'CV-10027'
        ..name = 'Tunde Bello'
        ..gender = 'Male'
        ..dateOfBirth = DateTime(1979, 11, 5)
        ..height = 180.0
        ..weight = 76.0
        ..emergencyContact = 'Folake Bello (+234 809 111 2222)'
        ..medicalConditions = ['Asthma']
        ..allergies = ['Aspirin', 'NSAIDs']
        ..medications = ['Albuterol Inhaler PRN', 'Fluticasone Propionate']
        ..doctorName = 'Dr. Adeyemi'
        ..notes = 'Moderate persistent asthma under control with maintenance inhaler.'
        ..isSynced = true
        ..updatedAt = DateTime(2025, 4, 10, 9, 45),

      PatientModel()
        ..id = 5
        ..remoteId = 'CV-10028'
        ..name = 'Aisha Mohammed'
        ..gender = 'Female'
        ..dateOfBirth = DateTime(1986, 6, 18)
        ..height = 165.0
        ..weight = 61.0
        ..emergencyContact = 'Zainab Mohammed (+234 807 555 6666)'
        ..medicalConditions = ['Hypothyroidism']
        ..allergies = ['Iodine contrast']
        ..medications = ['Levothyroxine 75mcg QD']
        ..doctorName = 'Dr. Adeyemi'
        ..notes = 'Primary hypothyroidism. Annual thyroid panel review.'
        ..isSynced = true
        ..updatedAt = DateTime(2025, 4, 5, 16, 20),
    ];
  }

  static List<VitalRecord> getDemoVitals() {
    return [
      // Chika Okafor (id: 1) 7-day readings Apr 19-26
      VitalRecord()
        ..id = 1
        ..patientId = 1
        ..systolic = 118
        ..diastolic = 76
        ..pulseRate = 72
        ..bodyTemperature = 36.6
        ..oxygenSaturation = 98
        ..dateTime = DateTime(2025, 4, 26, 9, 41)
        ..note = 'Resting morning vitals'
        ..isSynced = true,

      VitalRecord()
        ..id = 2
        ..patientId = 1
        ..systolic = 120
        ..diastolic = 78
        ..pulseRate = 70
        ..bodyTemperature = 36.5
        ..oxygenSaturation = 98
        ..dateTime = DateTime(2025, 4, 25, 9, 15)
        ..isSynced = true,

      VitalRecord()
        ..id = 3
        ..patientId = 1
        ..systolic = 124
        ..diastolic = 80
        ..pulseRate = 74
        ..bodyTemperature = 36.7
        ..oxygenSaturation = 97
        ..dateTime = DateTime(2025, 4, 24, 9, 30)
        ..isSynced = true,

      VitalRecord()
        ..id = 4
        ..patientId = 1
        ..systolic = 122
        ..diastolic = 79
        ..pulseRate = 71
        ..bodyTemperature = 36.6
        ..oxygenSaturation = 98
        ..dateTime = DateTime(2025, 4, 23, 9, 10)
        ..isSynced = true,

      VitalRecord()
        ..id = 5
        ..patientId = 1
        ..systolic = 118
        ..diastolic = 76
        ..pulseRate = 72
        ..bodyTemperature = 36.6
        ..oxygenSaturation = 98
        ..dateTime = DateTime(2025, 4, 22, 10, 30)
        ..note = 'General Consultation'
        ..isSynced = true,

      VitalRecord()
        ..id = 6
        ..patientId = 1
        ..systolic = 126
        ..diastolic = 82
        ..pulseRate = 75
        ..bodyTemperature = 36.6
        ..oxygenSaturation = 97
        ..dateTime = DateTime(2025, 4, 21, 9, 20)
        ..isSynced = true,

      VitalRecord()
        ..id = 7
        ..patientId = 1
        ..systolic = 125
        ..diastolic = 81
        ..pulseRate = 73
        ..bodyTemperature = 36.7
        ..oxygenSaturation = 98
        ..dateTime = DateTime(2025, 4, 20, 9, 0)
        ..isSynced = true,

      VitalRecord()
        ..id = 8
        ..patientId = 1
        ..systolic = 128
        ..diastolic = 84
        ..pulseRate = 76
        ..bodyTemperature = 36.8
        ..oxygenSaturation = 97
        ..dateTime = DateTime(2025, 4, 19, 9, 30)
        ..isSynced = true,

      // Emeka Nwosu (id: 2)
      VitalRecord()
        ..id = 9
        ..patientId = 2
        ..systolic = 124
        ..diastolic = 82
        ..pulseRate = 76
        ..glucoseValue = 112
        ..bodyTemperature = 36.6
        ..oxygenSaturation = 98
        ..dateTime = DateTime(2025, 4, 18, 11, 0)
        ..note = 'Routine diabetic review'
        ..isSynced = true,

      // Ngozi Eze (id: 3)
      VitalRecord()
        ..id = 10
        ..patientId = 3
        ..systolic = 110
        ..diastolic = 70
        ..pulseRate = 78
        ..bodyTemperature = 36.8
        ..oxygenSaturation = 99
        ..dateTime = DateTime(2025, 4, 15, 14, 30)
        ..note = '24-week prenatal vitals'
        ..isSynced = true,

      // Tunde Bello (id: 4)
      VitalRecord()
        ..id = 11
        ..patientId = 4
        ..systolic = 120
        ..diastolic = 78
        ..pulseRate = 74
        ..bodyTemperature = 36.5
        ..oxygenSaturation = 97
        ..dateTime = DateTime(2025, 4, 10, 9, 45)
        ..note = 'Asthma wellness check'
        ..isSynced = true,

      // Aisha Mohammed (id: 5)
      VitalRecord()
        ..id = 12
        ..patientId = 5
        ..systolic = 116
        ..diastolic = 74
        ..pulseRate = 68
        ..bodyTemperature = 36.5
        ..oxygenSaturation = 98
        ..dateTime = DateTime(2025, 4, 5, 16, 20)
        ..note = 'Thyroid review vitals'
        ..isSynced = true,
    ];
  }

  static List<ClinicalNote> getDemoNotes(int patientId, String patientName) {
    return [
      ClinicalNote(
        patientId: patientId,
        visitType: 'General Consultation',
        content: 'Patient $patientName presented for routine review. Vitals stable. Medication regimen reviewed and refilled. Advised continuation of heart-healthy dietary habits and moderate aerobic physical activity.',
        authorName: 'Dr. Adeyemi',
        date: DateTime(2025, 4, 22, 10, 30),
      ),
      ClinicalNote(
        patientId: patientId,
        visitType: 'Follow-up Visit',
        content: 'Follow-up consultation. Patient reports good adherence to prescribed therapy. No adverse side effects or symptoms reported.',
        authorName: 'Dr. Adeyemi',
        date: DateTime(2025, 2, 10, 14, 15),
      ),
    ];
  }

  static List<ActivityItem> getDemoActivities() {
    return [
      ActivityItem(
        title: 'Blood pressure recorded',
        subtitle: '118/76 mmHg • Chika Okafor',
        timestamp: DateTime(2025, 4, 26, 9, 41),
        category: ActivityCategory.vitals,
        patientName: 'Chika Okafor',
        patientId: 1,
      ),
      ActivityItem(
        title: 'Note added',
        subtitle: 'Follow-up visit • Chika Okafor',
        timestamp: DateTime(2025, 4, 26, 8, 32),
        category: ActivityCategory.notes,
        patientName: 'Chika Okafor',
        patientId: 1,
      ),
      ActivityItem(
        title: 'Patient viewed',
        subtitle: 'Emeka Nwosu',
        timestamp: DateTime(2025, 4, 25, 16, 12),
        category: ActivityCategory.patients,
        statusBadge: 'Synced',
        patientName: 'Emeka Nwosu',
        patientId: 2,
      ),
      ActivityItem(
        title: 'Vitals chart viewed',
        subtitle: 'Aisha Mohammed',
        timestamp: DateTime(2025, 4, 24, 11, 20),
        category: ActivityCategory.vitals,
        patientName: 'Aisha Mohammed',
        patientId: 5,
      ),
      ActivityItem(
        title: 'Patient list opened',
        subtitle: 'You viewed 5 patients',
        timestamp: DateTime(2025, 4, 23, 9, 15),
        category: ActivityCategory.patients,
      ),
    ];
  }
}
