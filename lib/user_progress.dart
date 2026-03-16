import 'package:shared_preferences/shared_preferences.dart';

class UserProgress {
  int steps;
  int totalRuns;
  String username;
  int level;
  int exp;
  List<Map<String, dynamic>> runs;

  UserProgress({
    required this.steps,
    required this.totalRuns,
    required this.username,
    required this.level,
    required this.exp,
    required this.runs,
  });

  int expToNextLevel() {
    return 1000 + (level * 500);
  }

  double expProgress() {
    return exp / expToNextLevel();
  }

  static Future<UserProgress> load() async {
    final prefs = await SharedPreferences.getInstance();

    int steps = prefs.getInt("items") ?? 0;
    int totalRuns = prefs.getInt("items") ?? 0;
    String username = prefs.getString("username") ?? "Runner";
    int level = prefs.getInt("level") ?? 1;
    int exp = prefs.getInt("exp") ?? 0;

    return UserProgress(
      steps: steps,
      totalRuns: totalRuns,
      username: username,
      level: level,
      exp: exp,
      runs: [],
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt("steps", steps);
    await prefs.setInt("totalRuns", totalRuns);
    await prefs.setString("username", username);
    await prefs.setInt("level", level);
    await prefs.setInt("exp", exp);
  }

  Future<void> addExp(int runSteps, double distanceKm) async {
    int gainedExp = runSteps + (distanceKm * 1000).toInt();
    exp += gainedExp;

    while (exp >= expToNextLevel()) {
      exp -= expToNextLevel();
      level++;
    }

    await save();
  }
}
