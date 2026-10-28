import 'package:vitalai/core/database/db_service.dart';
import '../../domain/repositories/activity_repository.dart';
import '../models/activity_item.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final DbService _dbService;

  ActivityRepositoryImpl(this._dbService);

  @override
  Future<List<ActivityItem>> getActivities({ActivityCategory category = ActivityCategory.all}) async {
    var list = await _dbService.getActivities();
    if (list.isEmpty) {
      list = _getDefaultActivities();
      await _dbService.saveActivities(list);
    }

    if (category == ActivityCategory.all) {
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    }

    final filtered = list.where((a) => a.category == category).toList();
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered;
  }

  @override
  Future<void> logActivity(ActivityItem item) async {
    final list = await _dbService.getActivities();
    list.insert(0, item);
    // Keep max 50 items
    if (list.length > 50) {
      list.removeRange(50, list.length);
    }
    await _dbService.saveActivities(list);
  }

  @override
  Future<void> clearActivities() async {
    await _dbService.saveActivities([]);
  }

  List<ActivityItem> _getDefaultActivities() {
    final now = DateTime.now();
    return [
      ActivityItem(
        title: 'Blood pressure recorded',
        subtitle: '118/76 mmHg • Chika Okafor',
        timestamp: DateTime(now.year, now.month, now.day, 9, 41),
        category: ActivityCategory.vitals,
        patientName: 'Chika Okafor',
      ),
      ActivityItem(
        title: 'Note added',
        subtitle: 'Follow-up visit • Chika Okafor',
        timestamp: DateTime(now.year, now.month, now.day, 8, 32),
        category: ActivityCategory.notes,
        patientName: 'Chika Okafor',
      ),
      ActivityItem(
        title: 'Patient viewed',
        subtitle: 'Emeka Nwosu',
        timestamp: now.subtract(const Duration(days: 1)).copyWith(hour: 16, minute: 12),
        category: ActivityCategory.patients,
        statusBadge: 'Synced',
        patientName: 'Emeka Nwosu',
      ),
      ActivityItem(
        title: 'Vitals chart viewed',
        subtitle: 'Aisha Mohammed',
        timestamp: now.subtract(const Duration(days: 2)).copyWith(hour: 11, minute: 20),
        category: ActivityCategory.vitals,
        patientName: 'Aisha Mohammed',
      ),
      ActivityItem(
        title: 'Patient list opened',
        subtitle: 'You viewed 5 patients',
        timestamp: now.subtract(const Duration(days: 3)).copyWith(hour: 9, minute: 15),
        category: ActivityCategory.patients,
      ),
    ];
  }
}
