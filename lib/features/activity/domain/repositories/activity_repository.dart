import '../../data/models/activity_item.dart';

abstract class ActivityRepository {
  Future<List<ActivityItem>> getActivities({ActivityCategory category = ActivityCategory.all});
  Future<void> logActivity(ActivityItem item);
  Future<void> clearActivities();
}
