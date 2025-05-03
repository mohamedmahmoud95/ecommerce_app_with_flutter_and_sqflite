import 'package:flutter/material.dart';
import 'product_list_screen.dart';
import 'user_list_screen.dart';
import 'order_list_screen.dart';
import 'cart_screen.dart';
import 'user_orders_screen.dart';
import '../models/user.dart';
import 'login_screen.dart';
import 'discount_list_screen.dart';

class HomeScreen extends StatelessWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Commerce Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        children: [
          if (user.userType == 'Admin')
            _buildMenuCard(
              context,
              'Users',
              Icons.people,
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserListScreen()),
              ),
            ),
          _buildMenuCard(
            context,
            'Products',
            Icons.shopping_bag,
            Colors.green,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ProductListScreen(
                      isAdmin: user.userType == 'Admin',
                      userId: user.id!,
                    ),
              ),
            ),
          ),
          if (user.userType == 'Admin')
            _buildMenuCard(
              context,
              'Orders',
              Icons.shopping_cart,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderListScreen(),
                ),
              ),
            ),
          if (user.userType == 'Admin')
            _buildMenuCard(
              context,
              'Discounts',
              Icons.discount,
              Colors.purple,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DiscountListScreen(),
                ),
              ),
            ),
          _buildMenuCard(
            context,
            'My Orders',
            Icons.history,
            Colors.amber,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserOrdersScreen(userId: user.id!),
              ),
            ),
          ),
          _buildMenuCard(
            context,
            'Cart',
            Icons.shopping_basket,
            Colors.purple,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CartScreen(userId: user.id!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
