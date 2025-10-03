import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Services/pos_service.dart';
import '../Models/product_model.dart';
import '../Models/cart_item_model.dart';
import 'reporting_screen.dart';
import 'receipt_screen.dart';
import 'pending_orders_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'package:badges/badges.dart' as badges;

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
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: () async {
                  await context.read<PosService>().logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.cloud_off),
                tooltip: 'Pending Orders',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PendingOrdersScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.bar_chart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReportingScreen(),
                    ),
                  );
                },
              ),
              // Updated Cart Badge
              badges.Badge(
                position: badges.BadgePosition.topEnd(top: 0, end: 3),
                badgeContent: Text(pos.cart.items.length.toString()),
                showBadge: pos.cart.items.isNotEmpty,
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () => _showCart(context, pos),
                ),
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
        );
      },
    );
  }

  void _showCart(BuildContext context, PosService pos) {
    showModalBottomSheet(
      context: context,
      // Use a Consumer here to rebuild the sheet on cart changes
      builder: (_) => Consumer<PosService>(
        builder: (context, pos, _) => _CartSheet(pos: pos),
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
              trailing: TextButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear Cart'),
                onPressed: pos.cart.items.isEmpty ? null : pos.clearCart,
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: pos.cart.items.isEmpty
                  ? const Center(child: Text('Cart is empty'))
                  : ListView.builder(
                      itemCount: pos.cart.items.length,
                      itemBuilder: (_, i) {
                        final CartItem item = pos.cart.items[i];
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
            // Discount control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Discount (%)'),
                      const Spacer(),
                      Text('${pos.discountPercentage.toStringAsFixed(0)}%'),
                    ],
                  ),
                  Slider(
                    value: pos.discountPercentage,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '${pos.discountPercentage.toStringAsFixed(0)}%',
                    onChanged: (v) => pos.setDiscountPercentage(v),
                  ),
                ],
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
                  onPressed: pos.cart.items.isEmpty
                      ? null
                      : () async {
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);

                          final success = await pos.checkout();

                          navigator.pop(); // Close the bottom sheet

                          if (success) {
                            messenger
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Order placed successfully!',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  action: SnackBarAction(
                                    label: 'View Receipt',
                                    onPressed: () {
                                      navigator.push(
                                        MaterialPageRoute(
                                          builder: (_) => const ReceiptScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                          } else {
                            messenger
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Checkout failed. Please try again.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                          }
                        },
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
