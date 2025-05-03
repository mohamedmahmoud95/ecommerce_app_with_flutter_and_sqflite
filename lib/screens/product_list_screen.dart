import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/database_helper.dart';
import 'product_form_screen.dart';
import 'cart_screen.dart';

class ProductListScreen extends StatefulWidget {
  final bool isAdmin;
  final int userId;

  const ProductListScreen({
    super.key,
    this.isAdmin = false,
    required this.userId,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'name';
  bool _sortAscending = true;
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _dbHelper.query('Products');
      setState(() {
        _products =
            products.map((product) => Product.fromMap(product)).toList();
        _categories = ['All', ..._products.map((p) => p.category).toSet()];
        _applyFilters();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    List<Product> filtered = _products;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (product) => product.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();
    }

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered =
          filtered
              .where((product) => product.category == _selectedCategory)
              .toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'name':
          return _sortAscending
              ? a.name.compareTo(b.name)
              : b.name.compareTo(a.name);
        case 'price':
          return _sortAscending
              ? a.price.compareTo(b.price)
              : b.price.compareTo(a.price);
        case 'category':
          return _sortAscending
              ? a.category.compareTo(b.category)
              : b.category.compareTo(a.category);
        default:
          return 0;
      }
    });

    setState(() => _filteredProducts = filtered);
  }

  Future<void> _addToCart(Product product) async {
    final cart = await _dbHelper.query(
      'Carts',
      where: 'User_ID = ?',
      whereArgs: [widget.userId],
    );

    int cartId;
    if (cart.isEmpty) {
      cartId = await _dbHelper.insert('Carts', {'User_ID': widget.userId});
    } else {
      cartId = cart.first['CartID'];
    }

    final cartProducts = await _dbHelper.query(
      'CartProducts',
      where: 'CartID = ? AND ProductID = ?',
      whereArgs: [cartId, product.id],
    );

    if (cartProducts.isEmpty) {
      await _dbHelper.insert('CartProducts', {
        'CartID': cartId,
        'ProductID': product.id,
        'Quantity': 1,
      });
    } else {
      await _dbHelper.update(
        'CartProducts',
        {'Quantity': cartProducts.first['Quantity'] + 1},
        'CartID = ? AND ProductID = ?',
        [cartId, product.id],
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${product.name} added to cart')));
    }
  }

  Future<void> _deleteProduct(int productId) async {
    try {
      await _dbHelper.delete('Products', 'ProductID = ?', [productId]);
      setState(() {
        _products.removeWhere((p) => p.id == productId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting product: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductFormScreen(),
                  ),
                );
                _loadProducts();
              },
            ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartScreen(userId: widget.userId),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search Products',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            _categories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedCategory = value!);
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        decoration: const InputDecoration(
                          labelText: 'Sort By',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'name', child: Text('Name')),
                          DropdownMenuItem(
                            value: 'price',
                            child: Text('Price'),
                          ),
                          DropdownMenuItem(
                            value: 'category',
                            child: Text('Category'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _sortBy = value!);
                          _applyFilters();
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                      ),
                      onPressed: () {
                        setState(() => _sortAscending = !_sortAscending);
                        _applyFilters();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredProducts.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No products found',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search or filters',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                    : GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        return Card(
                          elevation: 4,
                          child: InkWell(
                            onTap:
                                widget.isAdmin
                                    ? () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => ProductFormScreen(
                                                product: product,
                                              ),
                                        ),
                                      );
                                      _loadProducts();
                                    }
                                    : null,
                            onLongPress: () => _deleteProduct(product.id!),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(8),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.image,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '\$${product.price.toStringAsFixed(2)}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall?.copyWith(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        product.category,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Colors.grey[600]),
                                      ),
                                      if (!widget.isAdmin) ...[
                                        const SizedBox(height: 8),
                                        ElevatedButton(
                                          onPressed: () => _addToCart(product),
                                          child: const Text('Add to Cart'),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
