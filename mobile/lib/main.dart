import 'package:flutter/material.dart';
import 'services/invoice_service.dart';

void main() {
  runApp(const InvoiceApp());
}

class InvoiceApp extends StatelessWidget {
  const InvoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student B Invoice App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const InvoiceForm(),
    );
  }
}

class InvoiceForm extends StatefulWidget {
  const InvoiceForm({super.key});

  @override
  State<InvoiceForm> createState() => _InvoiceFormState();
}

class _InvoiceFormState extends State<InvoiceForm> {
  final TextEditingController _invoiceNoController =
      TextEditingController(text: "INV_20251003_001");
  final TextEditingController _customerController =
      TextEditingController(text: "John Banda");

  Map<String, dynamic> _buildInvoice() {
    return {
      "tpin": "123456789",
      "bhfId": "001",
      "deviceSerialNo": "POS-01",
      "invcNo": _invoiceNoController.text,
      "salesDt": "2025-10-03T14:30:00Z",
      "invoiceType": "N",
      "transactionType": "SALE",
      "paymentType": "CASH",
      "customerTpin": "987654321",
      "customerNm": _customerController.text,
      "totalItemCnt": 1,
      "items": [
        {
          "itemCd": "PROD_001",
          "itemNm": "Mpepo Burger",
          "qty": 2,
          "prc": 50.0,
          "taxblAmt": 100.0,
          "taxAmt": 10.0,
          "totAmt": 110.0
        }
      ],
      "totTaxblAmt": 100.0,
      "totTaxAmt": 10.0,
      "totAmt": 110.0
    };
  }

  Future<void> _handleSubmit(bool success) async {
    try {
      final invoice = _buildInvoice();
      final response = success
          ? await InvoiceService.submitInvoice(invoice)
          : await InvoiceService.submitInvoiceFail(invoice);

      if (success) {
        _showSnackBar("✅ ${response['message']}", Colors.green);
      } else {
        _showSnackBar("❌ ${response['detail']['message']}", Colors.red);
      }
    } catch (e) {
      _showSnackBar("⚠️ Error: $e", Colors.orange);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Invoice Submission")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _invoiceNoController,
              decoration: const InputDecoration(labelText: "Invoice No"),
            ),
            TextField(
              controller: _customerController,
              decoration: const InputDecoration(labelText: "Customer Name"),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _handleSubmit(true),
                  child: const Text("Submit Success"),
                ),
                ElevatedButton(
                  onPressed: () => _handleSubmit(false),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Submit Fail"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
