import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class InvoiceService {
  // Emulator (Android Studio/AVD)
  static const String emulatorUrl = "http://10.0.2.2:8000/api";

  // Replace this with your actual LAN IP for real device testing
  static const String phoneUrl = "http://192.168.1.45:8000/api";

  // Picks correct base URL depending on environment
  static String get baseUrl {
    if (Platform.isAndroid) {
      // If running on emulator
      return emulatorUrl;
    } else {
      // iOS simulator can use localhost directly
      return "http://localhost:8000/api";
    }
  }

  /// Submit invoice
  static Future<Map<String, dynamic>> submitInvoice(Map<String, dynamic> invoice) async {
    final url = Uri.parse("${baseUrl}/invoices/submit");
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

  /// Submit invoice fail (simulate error)
  static Future<Map<String, dynamic>> submitInvoiceFail(Map<String, dynamic> invoice) async {
    final url = Uri.parse("${baseUrl}/invoices/fail");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(invoice),
    );

    return jsonDecode(response.body);
  }

  /// Fetch all invoices (log)
  static Future<List<dynamic>> fetchInvoices() async {
    final url = Uri.parse("${baseUrl}/invoices");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch invoices: ${response.body}");
    }
  }

  /// Fetch single invoice by ID
  static Future<Map<String, dynamic>> fetchInvoiceById(String invoiceId) async {
    final url = Uri.parse("${baseUrl}/invoices/$invoiceId");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Invoice not found: ${response.body}");
    }
  }
}
