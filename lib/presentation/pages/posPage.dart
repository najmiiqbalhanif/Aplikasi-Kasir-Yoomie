import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:helloworld/presentation/pages/cartProvider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import '../../models/Product.dart';
import '../../models/CartItem.dart';
import '../../services/ProductService.dart';
import '../../services/cartService.dart';

class PoSPage extends StatefulWidget {
  final int cashierId; // active cashier id

  const PoSPage({
    super.key,
    required this.cashierId,
  });

  @override
  State<PoSPage> createState() => _PoSPageState();
}

class _PoSPageState extends State<PoSPage>
    with SingleTickerProviderStateMixin {
  static const Color backgroundColor = Color(0xFFF3F6FD);
  static const Color primaryGradientStart = Color(0xFF3B82F6);
  static const Color primaryGradientEnd = Color(0xFF4F46E5);
  static const Color textGrey = Color(0xFF6B7280);

  late Future<List<Product>> _futureProducts;
  late TabController _tabController;

  final CartService _cartService = CartService();

  /// key = category value in the database
  /// label = text shown in the UI
  final List<Map<String, String>> _categories = [
    {'key': 'makanan', 'label': 'Makanan'},
    {'key': 'minuman', 'label': 'Minuman'},
    {'key': 'sabun', 'label': 'Sabun'},
    {'key': 'perabot', 'label': 'Perabot'},
    {'key': 'pakaian', 'label': 'Pakaian'},
    {'key': 'minyak', 'label': 'Minyak'},
    {'key': 'alat_tulis', 'label': 'Alat Tulis'},
  ];

  // ===== SEARCH STATE =====
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  List<Product> _allProducts = [];

  @override
  void initState() {
    super.initState();
    _futureProducts = ProductService().getProducts();
    _tabController =
        TabController(length: _categories.length, vsync: this);

    // Load cart contents from backend -> store into CartProvider
    _loadInitialCartFromServer();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('cashierId');
    await prefs.remove('cashierName');

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  /// Fetch initial cart data from backend and fill CartProvider
  Future<void> _loadInitialCartFromServer() async {
    try {
      final cartProvider =
      Provider.of<CartProvider>(context, listen: false);

      // If the provider is already filled (e.g., loaded from another page), do not overwrite.
      if (cartProvider.items.isNotEmpty) return;

      final List<CartItem> initialCartItems =
      await _cartService.getCartItems(widget.cashierId);

      if (!mounted) return;

      // Double-check after the network call (in case changes happened)
      if (cartProvider.items.isNotEmpty) return;

      cartProvider.clearCart();

      for (final item in initialCartItems) {
        cartProvider.addExistingItem(item.product, item.quantity);
      }

      // Rebuild PoSPage so Qty on the cards gets updated
      setState(() {});
    } catch (e) {
      if (e.toString().contains('UNAUTHORIZED')) {
        await _forceLogout();
        return;
      }
      debugPrint('Error load initial cart in PoSPage: $e');
      if (!mounted) return;
    }
  }

  bool _matchesQuery(Product p, String query) {
    final q = query.toLowerCase();
    return p.name.toLowerCase().contains(q) ||
        p.brand.toLowerCase().contains(q);
  }

  void _onSearchChanged(String value) {
    final query = value.trim().toLowerCase();

    setState(() {
      _searchQuery = query;
    });

    if (query.isEmpty || _allProducts.isEmpty) return;

    // Find the first matching product across ALL categories
    Product? firstMatch;
    for (final p in _allProducts) {
      if (_matchesQuery(p, query)) {
        firstMatch = p;
        break;
      }
    }

    if (firstMatch != null) {
      final idx = _categories
          .indexWhere((c) => c['key'] == firstMatch!.category);
      if (idx != -1) {
        _tabController.animateTo(idx);
      }
    }
  }

  /// Get latest qty for a product from CartProvider
  int _getCurrentQtyFromProvider(Product product) {
    if (product.id == null) return 0;
    final cartProvider =
    Provider.of<CartProvider>(context, listen: false);
    final productId = product.id!;

    final matched = cartProvider.items
        .where((item) => item.product.id == productId);
    if (matched.isEmpty) return 0;
    return matched.first.quantity;
  }

  /// Tap on product card:
  /// - If not in cart => qty = 1
  /// - If already in cart => qty + 1
  void _onProductTap(Product product) {
    if (product.id == null) return;

    final currentQty = _getCurrentQtyFromProvider(product);
    final maxQty = product.stock;

    if (maxQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Out of stock.')),
      );
      return;
    }

    if (currentQty >= maxQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only $maxQty left for this product.')),
      );
      return;
    }

    _updateCartQuantity(product, currentQty + 1);
  }

  /// Update qty in CartProvider + sync to backend via CartService.
  Future<void> _updateCartQuantity(Product product, int newQuantity) async {
    final maxQty = product.stock;
    if (maxQty <= 0 && newQuantity > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Out of stock.')),
      );
      return;
    }
    if (newQuantity > maxQty) {
      newQuantity = maxQty;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quantity adjusted to max stock: $maxQty.')),
      );
    }

    if (product.id == null) {
      debugPrint('Product id null, skip updateCartQuantity');
      return;
    }

    final int productId = product.id!;
    final int cashierId = widget.cashierId;

    final cartProvider =
    Provider.of<CartProvider>(context, listen: false);

    final int previousQty = _getCurrentQtyFromProvider(product);

    // ====== Optimistic update: update provider first ======
    if (newQuantity <= 0) {
      // remove item
      cartProvider.removeItem(product);
    } else if (previousQty == 0) {
      // new item
      cartProvider.addExistingItem(product, newQuantity);
    } else {
      // update existing qty
      cartProvider.updateQuantity(product, newQuantity);
    }

    // Ensure PoSPage rebuilds as well (even though provider notifies)
    if (mounted) {
      setState(() {});
    }

    try {
      // ====== Sync to backend ======
      if (newQuantity <= 0) {
        if (previousQty > 0) {
          await _cartService.removeProductFromCart(cashierId, productId);
        }
        return;
      }

      if (previousQty == 0 && newQuantity == 1) {
        // From 0 to 1 => use add endpoint
        await _cartService.addProductToCart(cashierId, productId);
        return;
      }

      if (newQuantity == previousQty - 1 && newQuantity >= 1) {
        // Decrease by 1 => use decrease endpoint
        await _cartService.decreaseProductQuantity(cashierId, productId);
        return;
      }

      // Otherwise (e.g., jump 1 -> 5), use updateQuantity endpoint
      await _cartService.updateProductQuantity(
        cashierId,
        productId,
        newQuantity,
      );
    } catch (e) {
      if (e.toString().contains('UNAUTHORIZED')) {
        await _forceLogout();
        return;
      }

      debugPrint('Error update cart: $e');

      if (!mounted) return;

      // ==== Rollback provider to previous value ====
      if (previousQty <= 0) {
        cartProvider.removeItem(product);
      } else {
        cartProvider.updateQuantity(product, previousQty);
      }

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update cart. Please try again.')),
      );
    }
  }

  /// Bottom sheet qty (Cupertino style) - SOLUSI 1: SafeArea
  void _showQuantityBottomSheet(Product product) {
    if (product.id == null) {
      debugPrint('Product id null, cannot show bottom sheet qty');
      return;
    }

    final int maxQty = product.stock; // <-- from DB

    if (maxQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Out of stock.')),
      );
      return;
    }

    final existingQty = _getCurrentQtyFromProvider(product);
    int currentQty = existingQty == 0 ? 1 : existingQty;
    if (currentQty > maxQty) currentQty = maxQty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true, // <-- KUNCI: sejajarkan dengan area aman (bottom bar terasa “naik”)
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) {
        int tempQty = currentQty;
        if (tempQty < 1) tempQty = 1;
        if (tempQty > maxQty) tempQty = maxQty;

        final scrollController = FixedExtentScrollController(initialItem: tempQty - 1);

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final height = MediaQuery.of(ctx).size.height;
            const double itemHeight = 46; // same as target design

            return SafeArea(
              top: false, // bottom aman, top tetap “mepet” agar desain tidak berubah
              child: Container(
                width: double.infinity,
                height: height * 0.60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF3B82F6), // blue (left)
                      Color(0xFF4F46E5), // purple (right)
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 22,
                      spreadRadius: 2,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // handle
                    Container(
                      width: 52,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Row: Remove from cart + X button on the right
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(50),
                              onTap: () {
                                _updateCartQuantity(product, 0);
                                Navigator.of(ctx).pop();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.25),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Remove from cart',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () => Navigator.of(ctx).pop(),
                            child: Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                ),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // divider
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: Colors.white.withOpacity(0.18),
                    ),

                    const SizedBox(height: 10),

                    // qty picker
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.center,
                              child: Container(
                                height: itemHeight,
                                margin: const EdgeInsets.symmetric(horizontal: 24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ListWheelScrollView.useDelegate(
                            controller: scrollController,
                            itemExtent: itemHeight,
                            perspective: 0.003,
                            diameterRatio: 1.6,
                            magnification: 1.10,
                            useMagnifier: true,
                            squeeze: 1.05,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              final selectedQty = index + 1;
                              setModalState(() => tempQty = selectedQty);
                              _updateCartQuantity(product, selectedQty);
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: maxQty,
                              builder: (BuildContext context, int index) {
                                final value = index + 1;
                                final isSelected = value == tempQty;

                                return Center(
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 120),
                                    style: TextStyle(
                                      fontSize: isSelected ? 26 : 18,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.65),
                                    ),
                                    child: Text('$value'),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // done button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0B3B8F),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // ================== HEADER ==================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 25, 20, 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryGradientStart, primaryGradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _isSearching ? _buildSearchRow() : _buildTitleRow(),
                const SizedBox(height: 14),

                // ================== CATEGORY TABS ==================
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    indicatorPadding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 6,
                    ),
                    labelColor: primaryGradientEnd,
                    unselectedLabelColor: Colors.white,
                    labelStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 12.5,
                    ),
                    tabs: _categories
                        .map(
                          (cat) => Tab(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Text(
                            cat['label']!,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          // ================== PRODUCT CONTENT ==================
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _futureProducts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  final err = snapshot.error.toString();
                  if (err.contains('UNAUTHORIZED')) {
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      await _forceLogout();
                    });
                    return const SizedBox.shrink();
                  }
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final products = snapshot.data ?? [];
                _allProducts = products;

                return TabBarView(
                  controller: _tabController,
                  children: _categories.map((category) {
                    final key = category['key']!;

                    final inCategory =
                    products.where((p) => p.category == key).toList();

                    final displayProducts = _searchQuery.isEmpty
                        ? inCategory
                        : inCategory
                        .where((p) => _matchesQuery(p, _searchQuery))
                        .toList();

                    return _buildProductGrid(displayProducts);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================== HEADER ROWS ==================

  Widget _buildTitleRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Point of Sale',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Select products and add them to your cart.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.search,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Center(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: primaryGradientEnd,
                  ),
                  hintText: 'Search products...',
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: textGrey,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(
            Icons.close_rounded,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchQuery = '';
              _searchController.clear();
            });
          },
        ),
      ],
    );
  }

  // ================== RESPONSIVE PRODUCT GRID ==================
  Widget _buildProductGrid(List<Product> products) {
    if (products.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty
              ? 'No products in this category yet.'
              : 'No products match your search.',
          style: const TextStyle(color: textGrey),
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;

    int crossAxisCount;
    double childAspectRatio;

    if (width >= 1000) {
      crossAxisCount = 5;
      childAspectRatio = 0.75;
    } else if (width >= 700) {
      crossAxisCount = 4;
      childAspectRatio = 0.75;
    } else if (width >= 500) {
      crossAxisCount = 3;
      childAspectRatio = 0.7;
    } else {
      crossAxisCount = 2;
      childAspectRatio = 0.7;
    }

    // Get cart state from provider (listen: true for realtime)
    final cartProvider = Provider.of<CartProvider>(context);
    final Map<int, int> quantityMap = {};
    for (final item in cartProvider.items) {
      if (item.product.id != null) {
        quantityMap[item.product.id!] = item.quantity;
      }
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final qty = (product.id == null) ? 0 : (quantityMap[product.id!] ?? 0);

        return ProductItem(
          product: product,
          quantity: qty,
          onTap: () => _onProductTap(product),
          onQtyTap: () => _showQuantityBottomSheet(product),
        );
      },
    );
  }
}

// ================== PRODUCT CARD ==================
class ProductItem extends StatelessWidget {
  final Product product;
  final int quantity;
  final VoidCallback onTap;
  final VoidCallback onQtyTap;

  const ProductItem({
    super.key,
    required this.product,
    required this.onTap,
    required this.onQtyTap,
    this.quantity = 0,
  });

  String _formatRupiah(double value) {
    final text = value.toStringAsFixed(0);
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = text.replaceAllMapped(reg, (match) => '${match[1]}.');
    return 'Rp $formatted';
  }

  String _resolveImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      print('IMAGE URL (FULL): $url');
      return url;
    }

    if (url.contains('src/main/resources/static/storage')) {
      url = url.split('src/main/resources/static/storage').last;
    }

    url = url.replaceAll('\\', '/');
    url = url.replaceAll(' ', '%20');

    if (!url.startsWith('/')) {
      url = '/$url';
    }

    final fullUrl = 'http://10.0.2.2:8080$url';
    print('IMAGE URL (POS): $fullUrl');
    return fullUrl;
  }

  @override
  Widget build(BuildContext context) {
    const Color priceColor = Color(0xFF111827);
    const Color qtyTextColor = Color(0xFF6B7280);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  _resolveImageUrl(product.photoUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Icon(Icons.broken_image)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _formatRupiah(product.price),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: priceColor,
                        ),
                      ),
                      const Spacer(),
                      if (quantity > 0)
                        GestureDetector(
                          onTap: onQtyTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Qty $quantity',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: qtyTextColor,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: qtyTextColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
