import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  static const String _nameKey = 'user_name';
  static const String _totalStarsKey = 'total_stars';

  // ── Name ──────────────────────────────────────────────────────────────────

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  static Future<void> saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
  }

  // ── Quest Progress ─────────────────────────────────────────────────────────

  static Future<String> getQuestStatus(String questId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('quest_${questId}_status') ?? 'notstarted';
  }

  static Future<void> saveQuestStatus(String questId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quest_${questId}_status', status);
  }

  static Future<int> getQuestProgress(String questId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('quest_${questId}_progress') ?? 0;
  }

  static Future<void> saveQuestProgress(String questId, int progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quest_${questId}_progress', progress);
  }

  static Future<int> getQuestStars(String questId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('quest_${questId}_stars') ?? 0;
  }

  static Future<void> saveQuestStars(String questId, int stars) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quest_${questId}_stars', stars);
  }

  // ── Collected Items — save/load full list with label + image path ──────────

  static Future<void> saveCollectedItems(
      String questId, List<Map<String, String>> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items);
    await prefs.setString('quest_${questId}_items', encoded);
  }

  static Future<List<Map<String, String>>> getCollectedItems(
      String questId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('quest_${questId}_items');
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded.map((e) => Map<String, String>.from(e)).toList();
  }

  static Future<void> clearCollectedItems(String questId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('quest_${questId}_items');
  }

  // ── Total Stars ────────────────────────────────────────────────────────────

  static Future<int> getTotalStars() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalStarsKey) ?? 0;
  }

  static Future<void> addStars(int stars) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_totalStarsKey) ?? 0;
    await prefs.setInt(_totalStarsKey, current + stars);
  }

  // ── Reset single quest ─────────────────────────────────────────────────────

  static Future<void> resetQuest(String questId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quest_${questId}_status', 'notstarted');
    await prefs.setInt('quest_${questId}_progress', 0);
    await prefs.setInt('quest_${questId}_stars', 0);
    await prefs.remove('quest_${questId}_items');
  }

  // ── Reset everything ───────────────────────────────────────────────────────

  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}