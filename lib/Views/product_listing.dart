import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Services/pos_service.dart';
import '../Models/cart_item_model.dart';
import '../Models/product_model.dart';
import 'reporting_screen.dart'; // Add this import

class ProductListingScreen extends StatefulWidget {
  const ProductListingScreen({Key? key}) : super(key: key);

  @override
  _ProductListingScreenState createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  final PosService _posService = PosService();
  List<Product> _products = [];

  @override
  Widget build(BuildContext context) {
    // Fetch products on screen load
    Provider.of<PosService>(context, listen: false).fetchProducts();
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mpepo Kitchen POS'),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportingScreen()),
              );
            },
          ),
        ],
      ),
      body: isMobile
          ? ProductGridView()
          : Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: ProductGridView()),
          Expanded(flex: 2, child: CartView()),
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

    if (posService.catalog.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

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
  final ProductModel product;
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
            child: product.imageUrl != null
                ? Image.network(
              product.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _placeholderImage(),
            )
                : _placeholderImage(),
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
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'Stock: ${product.stock}',
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

  Widget _placeholderImage() {
    return Container(
      color: Colors.grey[300],
      child: const Center(child: Text('No Image')),
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
              child: Center(child: Text('Your cart is empty.')),
            )
          else
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
            onPressed: posService.cart.isEmpty
                ? null
                : () {
              // Show checkout confirmation
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Checkout'),
                  content: Text(
                      'Total: K${posService.total.toStringAsFixed(2)}\n\n'
                          'Items: ${posService.cart.length}\n'
                          'Subtotal: K${posService.subtotal.toStringAsFixed(2)}\n'
                          'Discount: -K${posService.discountValue.toStringAsFixed(2)}\n'
                          'Tax: +K${posService.taxValue.toStringAsFixed(2)}'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Clear cart and close dialog
                        posService.clearCart();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Checkout successful!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              );
            },
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
        leading: cartItem.product.imageUrl != null
            ? Image.network(
          cartItem.product.imageUrl!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _placeholderImage(),
        )
            : _placeholderImage(),
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

  Widget _placeholderImage() {
    return Container(
      width: 50,
      height: 50,
      color: Colors.grey[300],
      child: const Center(child: Text('No Image')),
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
        _buildSummaryRow('Subtotal:', 'K${posService.subtotal.toStringAsFixed(2)}'),
        _buildSummaryRow('Discount (10%):', '-K${posService.discountValue.toStringAsFixed(2)}'),
        _buildSummaryRow('Tax (8%):', '+K${posService.taxValue.toStringAsFixed(2)}'),
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