import 'dart:convert';
import 'package:http/http.dart' as http;

class InvoiceService {
  static const String baseUrl = "http://10.0.2.2:8000/api/invoices";

  /// Submit an invoice (for app-generated invoices, no UI buttons)
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
      throw Exception("Submission failed: ${response.body}");
    }
  }

  /// Fetch all saved invoice responses
  static Future<List<dynamic>> fetchAllResponses() async {
    final url = Uri.parse("$baseUrl/responses");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch responses: ${response.body}");
    }
  }

  /// Fetch a single invoice response by ID
  static Future<Map<String, dynamic>> fetchSingleResponse(String invoiceId) async {
    final url = Uri.parse("$baseUrl/responses/$invoiceId");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Invoice response not found: ${response.body}");
    }
  }
}
s
