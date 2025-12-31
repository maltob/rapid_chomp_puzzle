import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_constants.dart';

class StorageService {
  static const String keyMemoryMatchHighScore = 'memory_match_high_score';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  Future<void> saveMemoryMatchHighScore(int score) async {
    final currentScore = getMemoryMatchHighScore();
    if (score < currentScore || currentScore == 0) {
      await _prefs.setInt(keyMemoryMatchHighScore, score);
    }
  }

  int getMemoryMatchHighScore() {
    return _prefs.getInt(keyMemoryMatchHighScore) ?? 0;
  }

  Future<void> saveMemoryMatchPresets(String presetsJson) async {
    await _prefs.setString(AppConstants.keyMemoryMatchPresets, presetsJson);
  }

  String getMemoryMatchPresets() {
    return _prefs.getString(AppConstants.keyMemoryMatchPresets) ?? '[]';
  }

  // Jigsaw Settings
  Future<void> saveJigsawSettings(String settingsJson) async {
    await _prefs.setString(AppConstants.keyLastJigsawSettings, settingsJson);
  }

  String? getJigsawSettings() {
    return _prefs.getString(AppConstants.keyLastJigsawSettings);
  }

  // Recent Jigsaw Images
  Future<void> addRecentJigsawImage(String path) async {
    final List<String> recent = getRecentJigsawImages();
    // Remove if already exists to move to top
    recent.remove(path);
    recent.insert(0, path);
    // Limit to 10
    if (recent.length > 10) {
      recent.removeLast();
    }
    await _prefs.setStringList(AppConstants.keyRecentJigsawImages, recent);
  }

  List<String> getRecentJigsawImages() {
    return _prefs.getStringList(AppConstants.keyRecentJigsawImages) ?? [];
  }

  // Memory Match Settings
  Future<void> saveMemoryMatchSettings(String settingsJson) async {
    await _prefs.setString(
      AppConstants.keyLastMemoryMatchSettings,
      settingsJson,
    );
  }

  String? getMemoryMatchSettings() {
    return _prefs.getString(AppConstants.keyLastMemoryMatchSettings);
  }
}
