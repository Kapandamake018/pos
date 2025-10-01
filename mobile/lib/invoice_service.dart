import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class InvoiceService {
  static const String baseUrl = "http://10.0.2.2:8000/api/invoices";

  /// Submit invoice and save response locally
  static Future<Map<String, dynamic>> submitInvoice(Map<String, dynamic> invoice, {bool fail = false}) async {
    final url = Uri.parse("$baseUrl/${fail ? "fail" : "submit"}");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(invoice),
    );

    final result = jsonDecode(response.body);

    // Save response to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("last_response", jsonEncode(result));

    return result;
  }

  /// Get last saved response
  static Future<Map<String, dynamic>?> getLastResponse()
