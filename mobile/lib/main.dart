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
      title: 'Invoice Response Viewer',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ResponseScreen(),
    );
  }
}

class ResponseScreen extends StatefulWidget {
  const ResponseScreen({super.key});

  @override
  State<ResponseScreen> createState() => _ResponseScreenState();
}

class _ResponseScreenState extends State<ResponseScreen> {
  Map<String, dynamic>? _response;

  @override
  void initState() {
    super.initState();
    _loadResponse();
  }

  Future<void> _loadResponse() async {
    final res = await InvoiceService.getLastResponse();
    setState(() {
      _response = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Last Invoice Response")),
      body: Center(
        child: _response == null
            ? const Text("No response saved yet")
            : Text(
                _response.toString(),
                style: const TextStyle(fontSize: 16),
              ),
      ),
    );
  }
}
