import 'package:flutter/material.dart';
import '../services/invoice_service.dart';

class InvoiceSubmissionScreen extends StatefulWidget {
  const InvoiceSubmissionScreen({super.key});

  @override
  State<InvoiceSubmissionScreen> createState() => _InvoiceSubmissionScreenState();
}

class _InvoiceSubmissionScreenState extends State<InvoiceSubmissionScreen> {
  List<dynamic> _responses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadResponses();
  }

  Future<void> _loadResponses() async {
    try {
      final data = await InvoiceService.fetchAllResponses();
      setState(() {
        _responses = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _responses = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Invoice Responses")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _responses.length,
              itemBuilder: (context, index) {
                final resp = _responses[index];
                return ListTile(
                  title: Text("Invoice: ${resp['invoiceId']}"),
                  subtitle: Text("Status: ${resp['status'] ?? resp['detail']['status']}"),
                  trailing: Text(resp['message'] ?? resp['detail']?['message'] ?? ""),
                );
              },
            ),
    );
  }
}
