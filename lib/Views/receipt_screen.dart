import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Services/pos_service.dart';

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: Consumer<PosService>(
        builder: (context, pos, _) {
          final receipt = pos.lastReceipt;
          if (receipt == null) {
            return const Center(child: Text('No recent receipt available.'));
          }

          final items = receipt.items;
          final taxResponse = receipt.taxResponse;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Mpepo Kitchen',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(receipt.dateTimeString, textAlign: TextAlign.center),
              const Divider(height: 24),
              ...items.map(
                (i) => ListTile(
                  dense: true,
                  title: Text(i.product.name),
                  subtitle: Text(
                    'Qty ${i.quantity} x ZMW ${i.product.price.toStringAsFixed(2)}',
                  ),
                  trailing: Text('ZMW ${i.total.toStringAsFixed(2)}'),
                ),
              ),
              const Divider(height: 24),
              _row(context, 'Subtotal', receipt.subtotal),
              _row(context, 'Discount', -receipt.discountValue),
              _row(context, 'Tax', receipt.taxValue),
              const SizedBox(height: 8),
              _row(context, 'Total', receipt.total, isBold: true),
              const Divider(height: 24),
              Text(
                'Tax Authority',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (taxResponse == null)
                Row(
                  children: [
                    const Expanded(
                      child: Text('Submitting to tax authority...'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final pos = context.read<PosService>();
                        final receipt = pos.lastReceipt;
                        if (receipt?.orderData != null) {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await pos.resubmitTax(receipt!.orderData!);
                            messenger
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text('Invoice resubmitted.'),
                                ),
                              );
                          } catch (_) {
                            messenger
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to resubmit invoice.'),
                                ),
                              );
                          }
                        }
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                )
              else
                Builder(
                  builder: (context) {
                    final invNo =
                        taxResponse['invoice_number'] ??
                        taxResponse['cis_invc_no'] ??
                        taxResponse['cisInvcNo'];
                    final authRef = taxResponse['authority_reference'];
                    final receivedRaw = taxResponse['received_at'];
                    DateTime? received;
                    if (receivedRaw is String) {
                      received = DateTime.tryParse(receivedRaw);
                    }
                    final amount = taxResponse['amount'];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (invNo != null) Text('Invoice No: $invNo'),
                        if (authRef != null) Text('Authority Ref: $authRef'),
                        if (received != null)
                          Text('Received: ${received.toLocal()}'),
                        if (amount is num)
                          Text('Amount: ZMW ${amount.toStringAsFixed(2)}'),
                        if (taxResponse['status'] != null)
                          Text('Status: ${taxResponse['status']}'),
                        if (taxResponse['message'] != null)
                          Text('Message: ${taxResponse['message']}'),
                      ],
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    double value, {
    bool isBold = false,
  }) {
    final style = isBold
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text('ZMW ${value.toStringAsFixed(2)}', style: style),
      ],
    );
  }
}
