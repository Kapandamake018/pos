// lib/Views/product_listing.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Services/pos_service.dart';
import '../Models/cart_item_model.dart';
import '../Models/product_model.dart';

class ProductListingScreen extends StatelessWidget {
  const ProductListingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mpepo Kitchen POS'),
        backgroundColor: Colors.deepOrange,
      ),
      body: isMobile
          ? ProductGridView() // Show only products on mobile, cart is a separate screen/dialog
          : Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: ProductGridView(),
          ),
          Expanded(
            flex: 2,
            child: CartView(),
          ),
        ],
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton.extended(
        onPressed: () => _showCartDialog(context),
        label: Text('View Cart (${context.watch<PosService>().cart.length})'),
        icon: Icon(Icons.shopping_cart),
        backgroundColor: Colors.deepOrange,
      )
          : null,
    );
  }

  void _showCartDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        builder: (_, controller) => ChangeNotifierProvider.value(
          value: Provider.of<PosService>(context, listen: false),
          child: SingleChildScrollView(
            controller: controller,
            child: CartView(),
          ),
        ),
      ),
    );
  }
}

class ProductGridView extends StatelessWidget {
  const ProductGridView({super.key});

  @override
  Widget build(BuildContext context) {
    final posService = Provider.of<PosService>(context);

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 2 / 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: posService.catalog.length,
      itemBuilder: (context, index) {
        final product = posService.catalog[index];
        return ProductCard(product: product);
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.network(
              product.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              product.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'K${product.price.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[700]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Provider.of<PosService>(context, listen: false).addToCart(product);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} added to cart.'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: const Text('Add to Cart'),
            ),
          ),
        ],
      ),
    );
  }
}

class CartView extends StatelessWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    final posService = context.watch<PosService>();

    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,

        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Shopping Cart',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Divider(),
          if (posService.cart.isEmpty)

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 64.0),
              child: Center(
                child: Text('Your cart is empty.'),
              ),
            )
          else

          // Flexible allows the ListView to shrink and not cause an overflow.
            Flexible(
              child: ListView.builder(

                shrinkWrap: true,
                itemCount: posService.cart.length,
                itemBuilder: (context, index) {
                  final cartItem = posService.cart[index];
                  return CartListItem(cartItem: cartItem);
                },
              ),
            ),
          const Divider(),
          CalculationSummary(),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: posService.cart.isEmpty ? null : () { /* Checkout Logic */ },
            child: const Text('Checkout', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}

class CartListItem extends StatelessWidget {
  final CartItem cartItem;
  const CartListItem({super.key, required this.cartItem});

  @override
  Widget build(BuildContext context) {
    final posService = Provider.of<PosService>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Image.network(cartItem.product.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
        title: Text(cartItem.product.name),
        subtitle: Text('K${cartItem.product.price.toStringAsFixed(2)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => posService.decrementQuantity(cartItem)),
            Text('${cartItem.quantity}', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => posService.incrementQuantity(cartItem)),
          ],
        ),
      ),
    );
  }
}

class CalculationSummary extends StatelessWidget {
  const CalculationSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final posService = context.watch<PosService>();

    return Column(
      children: [
        _buildSummaryRow('Subtotal:', 'k${posService.subtotal.toStringAsFixed(2)}'),
        _buildSummaryRow('Discount (10%):', '-k${posService.discountValue.toStringAsFixed(2)}'),
        _buildSummaryRow('Tax (8%):', '+k${posService.taxValue.toStringAsFixed(2)}'),
        const Divider(),
        _buildSummaryRow(
          'Total:',
          'K${posService.total.toStringAsFixed(2)}',
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
