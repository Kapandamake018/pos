import 'package:shared_preferences/shared_preferences.dart';
import 'config/api_config.dart';

class AppConfig {
  static const _baseUrlKey = 'base_url_override';
  static const _taxUrlKey = 'tax_url_override';

  String baseUrl;
  String taxUrl;

  AppConfig({required this.baseUrl, required this.taxUrl});

  static Future<AppConfig> load({
    String? defaultBase,
    String? defaultTax,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final rawB = prefs.getString(_baseUrlKey);
    final rawT = prefs.getString(_taxUrlKey);
    final b = (rawB == null || rawB.trim().isEmpty)
        ? (defaultBase ?? ApiConfig.baseUrl)
        : rawB;
    final t = (rawT == null || rawT.trim().isEmpty)
        ? (defaultTax ?? ApiConfig.taxApiBaseUrl)
        : rawT;
    return AppConfig(baseUrl: b, taxUrl: t);
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, baseUrl);
    await prefs.setString(_taxUrlKey, taxUrl);
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    // Clear saved overrides so the app falls back to compile-time defaults
    await prefs.setString(_baseUrlKey, '');
    await prefs.setString(_taxUrlKey, '');
  }
}
