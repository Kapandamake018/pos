import 'dart:convert';
import 'package:http/http.dart' as http;

class InvoiceService {
  /// 🔹 Base URL of your FastAPI backend
  /// Change this depending on where you run the app:
  ///
  /// - Android Emulator: use "http://10.0.2.2:8000/api/invoices"
  ///   (because "localhost" points to emulator, not your PC)
  ///
  /// - iOS Simulator: use "http://127.0.0.1:8000/api/invoices"
  ///
  /// - Flutter Web: use "http://127.0.0.1:8000/api/invoices"
  ///
  /// - Real Device (on same WiFi): use your computer’s LAN IP
  ///   Example: "http://192.168.1.100:8000/api/invoices"
  ///
  static const String baseUrl = "http://10.0.2.2:8000/api/invoices";

  /// Submit invoice for success case
  static Future<Map<String, dynamic>> submitInvoice(Map<String, dynamic> invoice) async {
    final url = Uri.parse("$baseUrl/submit");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(invoice),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed: ${response.body}");
    }
  }

  /// Submit invoice to trigger failure case
  static Future<Map<String, dynamic>> submitInvoiceFail(Map<String, dynamic> invoice) async {
    final url = Uri.parse("$baseUrl/fail");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(invoice),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      // Fail endpoint returns 400
      return jsonDecode(response.body);
    }
  }
}

