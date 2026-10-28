import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Hydration Tracking & Persistence Tests', () {
    String getDateKey([DateTime? date]) {
      final now = date ?? DateTime.now();
      return '${now.year}_${now.month}_${now.day}';
    }

    test('Fresh day or unlogged profile defaults intake to 0 ml (0%) and 2000 ml target', () async {
      final prefs = await SharedPreferences.getInstance();
      const pid = 1;
      final dateKey = getDateKey();

      final savedWater = prefs.getInt('hydration_intake_${pid}_$dateKey');
      final savedWaterGoal = prefs.getInt('hydration_goal_$pid');

      final intake = savedWater ?? 0;
      final goal = savedWaterGoal ?? 2000;
      final pct = ((intake / goal) * 100).clamp(0, 100).toInt();

      expect(intake, 0);
      expect(goal, 2000);
      expect(pct, 0);
    });

    test('Logging water increments and persists date-keyed intake for active patient', () async {
      final prefs = await SharedPreferences.getInstance();
      const pid = 1;
      final dateKey = getDateKey();

      // Log first glass (+250 ml)
      int currentIntake = prefs.getInt('hydration_intake_${pid}_$dateKey') ?? 0;
      currentIntake += 250;
      await prefs.setInt('hydration_intake_${pid}_$dateKey', currentIntake);

      expect(prefs.getInt('hydration_intake_${pid}_$dateKey'), 250);

      // Log bottle (+500 ml)
      currentIntake += 500;
      await prefs.setInt('hydration_intake_${pid}_$dateKey', currentIntake);

      expect(prefs.getInt('hydration_intake_${pid}_$dateKey'), 750);
      final pct = ((currentIntake / 2000) * 100).toInt();
      expect(pct, 37); // (750 / 2000) * 100 = 37.5 -> 37
    });

    test('Custom daily goal updates and persists per patient', () async {
      final prefs = await SharedPreferences.getInstance();
      const pid = 1;

      await prefs.setInt('hydration_goal_$pid', 2500);
      expect(prefs.getInt('hydration_goal_$pid'), 2500);

      // 1250 ml / 2500 ml = 50%
      const intake = 1250;
      final goal = prefs.getInt('hydration_goal_$pid') ?? 2000;
      final pct = ((intake / goal) * 100).toInt();
      expect(pct, 50);
    });

    test('Strict patient isolation: Patient A logs do not leak into Patient B', () async {
      final prefs = await SharedPreferences.getInstance();
      const patientA = 101;
      const patientB = 202;
      final dateKey = getDateKey();

      await prefs.setInt('hydration_intake_${patientA}_$dateKey', 1500);
      await prefs.setInt('hydration_goal_$patientA', 2500);

      await prefs.setInt('hydration_intake_${patientB}_$dateKey', 500);
      await prefs.setInt('hydration_goal_$patientB', 1800);

      expect(prefs.getInt('hydration_intake_${patientA}_$dateKey'), 1500);
      expect(prefs.getInt('hydration_goal_$patientA'), 2500);

      expect(prefs.getInt('hydration_intake_${patientB}_$dateKey'), 500);
      expect(prefs.getInt('hydration_goal_$patientB'), 1800);
    });

    test('Weekly history correctly queries past 7 days independently', () async {
      final prefs = await SharedPreferences.getInstance();
      const pid = 1;
      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);

      // Simulate intake on yesterday and 2 days ago
      final yesterday = todayMidnight.subtract(const Duration(days: 1));
      final twoDaysAgo = todayMidnight.subtract(const Duration(days: 2));

      await prefs.setInt('hydration_intake_${pid}_${getDateKey(yesterday)}', 2000);
      await prefs.setInt('hydration_intake_${pid}_${getDateKey(twoDaysAgo)}', 1500);

      final Map<DateTime, int> weeklyMap = {};
      for (int i = 6; i >= 0; i--) {
        final day = todayMidnight.subtract(Duration(days: i));
        final dayKey = getDateKey(day);
        final intake = prefs.getInt('hydration_intake_${pid}_$dayKey') ?? 0;
        weeklyMap[day] = intake;
      }

      expect(weeklyMap.length, 7);
      expect(weeklyMap[yesterday], 2000);
      expect(weeklyMap[twoDaysAgo], 1500);
      expect(weeklyMap[todayMidnight], 0); // today unlogged starts at 0
    });
  });
}
