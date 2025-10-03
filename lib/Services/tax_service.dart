import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../app_config.dart';

class TaxService {
  Future<Map<String, dynamic>> submitInvoice(
    Map<String, dynamic> invoice,
  ) async {
    // Prefer runtime override from SharedPreferences (via AppConfig)
    String base;
    try {
      final cfg = await AppConfig.load();
      base = cfg.taxUrl;
    } catch (_) {
      base = ApiConfig.taxApiBaseUrl;
    }
    final url = Uri.parse('$base/invoices/submit');
    final headers = ApiConfig.getHeaders();
    final body = json.encode(invoice);

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final raw = response.body;
        if (raw.trim().isEmpty) {
          return {'status': 'accepted', 'statusCode': response.statusCode};
        }
        try {
          return json.decode(raw) as Map<String, dynamic>;
        } catch (_) {
          return {'raw': raw, 'statusCode': response.statusCode};
        }
      } else {
        throw Exception(
          'Failed to submit invoice: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to submit invoice: $e');
    }
  }
}
