import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/portfolio.dart';
import 'inflation_service.dart';

class StorageService {
  static const String _keyPortfolios = 'portfolios_data';
  static const String _keyLogoCache = 'logo_cache';
  static const String _keySettings = 'app_settings';
  static const String _keyInflationCache = 'inflation_cache';

  Future<Map<String, dynamic>> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final content = prefs.getString(_keySettings);
      if (content != null && content.trim().isNotEmpty) {
        final decoded = jsonDecode(content);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
    } catch (_) {}
    return {
      'returnCalculationMode': 'brut',
      'showNetValuesWithholdingTax': false,
    };
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final content = jsonEncode(settings);
      await prefs.setString(_keySettings, content);
    } catch (_) {}
  }

  Future<Map<String, String>> loadLogoCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final content = prefs.getString(_keyLogoCache);
      if (content != null && content.trim().isNotEmpty) {
        final Map<String, dynamic> raw =
            jsonDecode(content) as Map<String, dynamic>;
        return raw.map((k, v) => MapEntry(k, v.toString()));
      }
    } catch (_) {}
    return {};
  }

  Future<void> saveLogoCache(Map<String, String> cache) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final content = jsonEncode(cache);
      await prefs.setString(_keyLogoCache, content);
    } catch (_) {}
  }

  Future<Map<String, InflationInfo>> loadInflationCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final content = prefs.getString(_keyInflationCache);
      if (content != null && content.trim().isNotEmpty) {
        final Map<String, dynamic> raw =
            jsonDecode(content) as Map<String, dynamic>;
        return raw.map((k, v) => MapEntry(
            k, InflationInfo.fromJson(v as Map<String, dynamic>)));
      }
    } catch (_) {}
    return {};
  }

  Future<void> saveInflationCache(Map<String, InflationInfo> cache) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = cache.map((k, v) => MapEntry(k, v.toJson()));
      final content = jsonEncode(map);
      await prefs.setString(_keyInflationCache, content);
    } catch (_) {}
  }

  Future<List<Portfolio>> loadPortfolios() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final content = prefs.getString(_keyPortfolios);
      if (content != null && content.trim().isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;
        return jsonList
            .map((item) => Portfolio.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    } catch (e) {
      // Fallback on error
    }
    return [];
  }

  Future<void> savePortfolios(List<Portfolio> portfolios) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = portfolios.map((p) => p.toJson()).toList();
      final content = jsonEncode(jsonList);
      await prefs.setString(_keyPortfolios, content);
    } catch (e) {
      // Ignore write errors or log
    }
  }
}
