import 'package:flutter/material.dart';
import '../../models/Product.dart';
import '../../services/ProductService.dart';
import 'productPage.dart';

class PoSPage extends StatefulWidget {
  const PoSPage({super.key});

  @override
  State<PoSPage> createState() => _PoSPageState();
}

class _PoSPageState extends State<PoSPage> with SingleTickerProviderStateMixin {
  static const Color backgroundColor = Color(0xFFF3F6FD);
  static const Color primaryGradientStart = Color(0xFF3B82F6);
  static const Color primaryGradientEnd = Color(0xFF4F46E5);
  static const Color textGrey = Color(0xFF6B7280);

  late Future<List<Product>> _futureProducts;
  late TabController _tabController;

  /// Pisahkan antara key (untuk backend) dan label (untuk tampilan).
  /// Sesuaikan `key` ini dengan value `category` di database kamu ya.
  final List<Map<String, String>> _categories = [
    {'key': 'makanan', 'label': 'Makanan'},
    {'key': 'minuman', 'label': 'Minuman'},
    {'key': 'sabun', 'label': 'Sabun'},
    {'key': 'perabot', 'label': 'Perabot'},
    {'key': 'pakaian', 'label': 'Pakaian'},
    {'key': 'minyak', 'label': 'Minyak'},
    {'key': 'alat_tulis', 'label': 'Alat Tulis'},
  ];

  @override
  void initState() {
    super.initState();
    _futureProducts = ProductService().getProducts();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // HEADER GRADIENT + TABBAR
          const SizedBox(height: 25),
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
                Row(
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
                      child: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Container Tab kategori (diratakan kiri-kanan)
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
                    dividerColor: Colors.transparent, // biar ga ada garis hitam

                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),

                    // tambahkan horizontal kecil supaya indicator sedikit lebih lebar
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

                    tabs: _categories.map(
                          (cat) => Tab(
                        // ⬇⬇ ini yang bikin pill putih lebih lebar dari teks
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Text(
                            cat['label']!,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ISI PRODUK
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _futureProducts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final products = snapshot.data ?? [];

                return TabBarView(
                  controller: _tabController,
                  children: _categories.map((category) {
                    final key = category['key']!;
                    final filtered = products
                        .where((p) => p.category == key)
                        .toList();
                    return _buildProductGrid(filtered);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    if (products.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada produk di kategori ini.',
          style: TextStyle(color: textGrey),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        // >>> 5 PRODUK PER ROW <<<
        crossAxisCount: 5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        // tinggi tiap kartu (boleh kamu tweak kalau mau lebih pendek/panjang)
        mainAxisExtent: 210,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductItem(
          product: product,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductPage(id: product.id),
              ),
            );
          },
        );
      },
    );
  }
}

class ProductItem extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductItem({
    super.key,
    required this.product,
    required this.onTap,
  });

  String _formatRupiah(double value) {
    final text = value.toStringAsFixed(0);
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = text.replaceAllMapped(reg, (match) => '${match[1]}.');
    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    const Color textGrey = Color(0xFF6B7280);
    const Color priceColor = Color(0xFF111827);

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
                aspectRatio: 1, // supaya square-ish dan rapi untuk 5 kolom
                child: Image.network(
                  product.photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
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
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatRupiah(product.price),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: priceColor,
                    ),
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
