import 'dart:convert';
import 'package:http/http.dart' as http;

class InvoiceService {
  final String baseUrl = 'http://localhost:8000/api/invoices';

  Future<Map<String, dynamic>> submitInvoice(Map<String, dynamic> invoiceData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/submit'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(invoiceData),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {'status': 'ERROR', 'message': response.body};
    }
  }

  Future<Map<String, dynamic>> getLog(String cisInvcNo) async {
    final response = await http.get(Uri.parse('$baseUrl/logs/$cisInvcNo'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load log');
    }
  }
}
