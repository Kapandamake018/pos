import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Services/pos_service.dart';
import '../Models/product_model.dart';
import '../Models/cart_item_model.dart';

class ProductListingScreen extends StatefulWidget {
  const ProductListingScreen({super.key});

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<PosService>().fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PosService>(
      builder: (context, pos, _) {
        if (pos.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (pos.lastError != null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Products')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(pos.lastError!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: pos.fetchProducts,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Menu'),
            actions: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => _showCart(context, pos),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: pos.catalog.length,
              itemBuilder: (_, i) {
                final Product p = pos.catalog[i];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        Text(
                          'ZMW ${p.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => pos.addToCart(p),
                            icon: const Icon(Icons.add_shopping_cart, size: 18),
                            label: const Text('Add'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          bottomNavigationBar: _CartSummaryBar(pos: pos),
        );
      },
    );
  }

  void _showCart(BuildContext context, PosService pos) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _CartSheet(pos: pos),
    );
  }
}

class _CartSummaryBar extends StatelessWidget {
  final PosService pos;
  const _CartSummaryBar({required this.pos});

  @override
  Widget build(BuildContext context) {
    final itemCount = pos.cart.length;
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Text('Items: $itemCount'),
          const Spacer(),
          Text('Total: ZMW ${pos.total.toStringAsFixed(2)}'),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: itemCount == 0 ? null : () {},
            child: const Text('Checkout'),
          ),
        ],
      ),
    );
  }
}

class _CartSheet extends StatelessWidget {
  final PosService pos;
  const _CartSheet({required this.pos});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            ListTile(
              title: const Text('Your Cart'),
              trailing: IconButton(
                icon: const Icon(Icons.clear_all),
                onPressed: pos.clearCart,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: pos.cart.isEmpty
                  ? const Center(child: Text('Cart is empty'))
                  : ListView.builder(
                      itemCount: pos.cart.length,
                      itemBuilder: (_, i) {
                        final CartItem item = pos.cart[i];
                        return ListTile(
                          title: Text(item.product.name),
                          subtitle: Text(
                            'Qty: ${item.quantity} • ZMW ${item.total.toStringAsFixed(2)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => pos.decrementQuantity(item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => pos.incrementQuantity(item),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Row('Subtotal', pos.subtotal),
                  _Row('Discount', -pos.discountValue),
                  _Row('Tax', pos.taxValue),
                  const SizedBox(height: 8),
                  _Row('Total', pos.total, isBold: true),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Checkout'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;
  const _Row(this.label, this.value, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
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
