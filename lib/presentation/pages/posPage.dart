import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../models/Product.dart';
import '../../services/ProductService.dart';
import '../../services/cartService.dart';

class PoSPage extends StatefulWidget {
  final int cashierId; // <- id kasir aktif

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

  /// key = value category di database
  /// label = teks yang ditampilkan di UI
  final List<Map<String, String>> _categories = [
    {'key': 'makanan', 'label': 'Makanan'},
    {'key': 'minuman', 'label': 'Minuman'},
    {'key': 'sabun', 'label': 'Sabun'},
    {'key': 'perabot', 'label': 'Perabot'},
    {'key': 'pakaian', 'label': 'Pakaian'},
    {'key': 'minyak', 'label': 'Minyak'},
    {'key': 'alat_tulis', 'label': 'Alat Tulis'},
  ];

  // ===== STATE UNTUK SEARCH =====
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  List<Product> _allProducts = [];

  /// key = product.id, value = quantity di cart
  final Map<int, int> _cartQuantities = {};

  @override
  void initState() {
    super.initState();
    _futureProducts = ProductService().getProducts();
    _tabController =
        TabController(length: _categories.length, vsync: this);

    // Kalau nanti mau load qty awal dari backend, bisa pakai getCartItems di sini.
    // Untuk sekarang, kita mulai dari cart kosong di sisi app.
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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

    // Cari produk pertama yang cocok di SEMUA kategori
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

  /// Tap pada kartu produk:
  /// - Kalau belum ada di cart => qty = 1
  /// - Kalau sudah ada        => qty + 1
  void _onProductTap(Product product) {
    if (product.id == null) {
      debugPrint('Product id null, tidak bisa menambah ke cart');
      return;
    }

    final productId = product.id!;
    final currentQty = _cartQuantities[productId] ?? 0;
    final newQty = currentQty + 1;

    _updateCartQuantity(product, newQty);
  }

  /// Update qty di state + sinkron ke backend via CartService.
  Future<void> _updateCartQuantity(Product product, int newQuantity) async {
    if (product.id == null) {
      debugPrint('Product id null, skip updateCartQuantity');
      return;
    }

    final int productId = product.id!;
    final int cashierId = widget.cashierId;
    final int previousQty = _cartQuantities[productId] ?? 0;

    // Update UI dulu biar kerasa real-time
    setState(() {
      if (newQuantity <= 0) {
        _cartQuantities.remove(productId);
      } else {
        _cartQuantities[productId] = newQuantity;
      }
    });

    try {
      if (newQuantity <= 0) {
        // Qty 0 => hapus item
        if (previousQty > 0) {
          await _cartService.removeProductFromCart(cashierId, productId);
        }
        return;
      }

      if (previousQty == 0 && newQuantity == 1) {
        // Dari 0 ke 1 => pakai endpoint add
        await _cartService.addProductToCart(cashierId, productId);
        return;
      }

      if (newQuantity == previousQty - 1 && newQuantity >= 1) {
        // Turun 1 => pakai endpoint decrease
        await _cartService.decreaseProductQuantity(cashierId, productId);
        return;
      }

      // Selain kasus di atas (misalnya loncat dari 1 -> 5),
      // langsung pakai endpoint updateQuantity.
      await _cartService.updateProductQuantity(
        cashierId,
        productId,
        newQuantity,
      );
    } catch (e) {
      debugPrint('Error update cart: $e');

      if (!mounted) return;

      // Rollback ke qty sebelumnya kalau gagal
      setState(() {
        if (previousQty == 0) {
          _cartQuantities.remove(productId);
        } else {
          _cartQuantities[productId] = previousQty;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memperbarui keranjang. Coba lagi.'),
        ),
      );
    }
  }

  /// Bottom sheet 1/4 layar untuk atur qty
  void _showQuantityBottomSheet(Product product) {
    if (product.id == null) {
      debugPrint('Product id null, tidak bisa show bottom sheet qty');
      return;
    }

    final int productId = product.id!;
    final int currentQty = _cartQuantities[productId] ?? 1;

    const int maxQty = 50; // batas atas qty di picker, bisa kamu ubah

    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        int tempQty = currentQty;
        if (tempQty < 1) tempQty = 1;
        if (tempQty > maxQty) tempQty = maxQty;

        final scrollController =
        FixedExtentScrollController(initialItem: tempQty - 1);

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final height = MediaQuery.of(ctx).size.height;

            return SizedBox(
              height: height * 0.45,   // kira-kira hampir setengah layar
              width: double.infinity,  // full lebar
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // handle kecil di atas
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // "Hapus dari keranjang"
                  GestureDetector(
                    onTap: () {
                      _updateCartQuantity(product, 0);
                      Navigator.of(ctx).pop();
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        'Hapus dari keranjang',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),
                  const Divider(height: 1),

                  // Picker qty
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: scrollController,
                      itemExtent: 40,
                      magnification: 1.1,
                      useMagnifier: true,
                      squeeze: 1.1,
                      onSelectedItemChanged: (index) {
                        final selectedQty = index + 1;
                        setModalState(() {
                          tempQty = selectedQty;
                        });
                        // real-time update UI + DB
                        _updateCartQuantity(product, selectedQty);
                      },
                      children: List.generate(maxQty, (index) {
                        final value = index + 1;
                        final isSelected = value == tempQty;
                        return Center(
                          child: Text(
                            '$value',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? primaryGradientEnd
                                  : Colors.black87,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Tombol "Selesai"
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGradientEnd,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text(
                          'Selesai',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
          const SizedBox(height: 25),

          // ================== HEADER ==================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
                // Title + search / searchField
                _isSearching ? _buildSearchRow() : _buildTitleRow(),
                const SizedBox(height: 14),

                // ================== TAB KATEGORI ==================
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18),
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

          // ================== ISI PRODUK ==================
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _futureProducts,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}'));
                }

                final products = snapshot.data ?? [];
                _allProducts = products; // simpan untuk kebutuhan search

                return TabBarView(
                  controller: _tabController,
                  children: _categories.map((category) {
                    final key = category['key']!;

                    // Filter per kategori dulu
                    final inCategory = products
                        .where((p) => p.category == key)
                        .toList();

                    // Kalau ada searchQuery, filter lagi berdasarkan query
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
              'Pilih produk dan tambahkan ke keranjang.',
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
                  hintText: 'Cari produk...',
                  hintStyle: TextStyle(
                    fontSize: 13,
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

  // ================== GRID PRODUK RESPONSIF ==================
  Widget _buildProductGrid(List<Product> products) {
    if (products.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty
              ? 'Belum ada produk di kategori ini.'
              : 'Tidak ada produk yang cocok dengan pencarian.',
          style: const TextStyle(color: textGrey),
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;

    int crossAxisCount;
    double childAspectRatio;

    if (width >= 1000) {
      // layar gede / web
      crossAxisCount = 5;
      childAspectRatio = 0.75;
    } else if (width >= 700) {
      // tablet
      crossAxisCount = 4;
      childAspectRatio = 0.75;
    } else if (width >= 500) {
      // HP lebar
      crossAxisCount = 3;
      childAspectRatio = 0.7;
    } else {
      // HP biasa
      crossAxisCount = 2;
      childAspectRatio = 0.7;
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
        final qty = product.id == null
            ? 0
            : (_cartQuantities[product.id!] ?? 0);

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

// ================== KARTU PRODUK ==================
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
    final formatted =
    text.replaceAllMapped(reg, (match) => '${match[1]}.');
    return 'Rp $formatted';
  }

  String _resolveImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      // ignore: avoid_print
      print('IMAGE URL (FULL): $url');
      return url;
    }

    if (url.contains('src/main/resources/static/')) {
      url = url.split('src/main/resources/static/').last;
    }

    url = url.replaceAll('\\', '/');
    url = url.replaceAll(' ', '%20');

    if (!url.startsWith('/')) {
      url = '/$url';
    }

    final fullUrl = 'http://10.0.2.2:8080$url';
    // ignore: avoid_print
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
            // gambar produk
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  _resolveImageUrl(product.photoUrl),
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) =>
                  const Center(child: Icon(Icons.broken_image)),
                ),
              ),
            ),
            // teks
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
                    maxLines: 2,
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
