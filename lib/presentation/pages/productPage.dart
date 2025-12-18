import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/Product.dart';
import '../../services/ProductService.dart';
import '../../services/FavoriteService.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ambil cashierId dari SharedPreferences (kalau ada)
Future<int?> getCashierId() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.containsKey('cashierId')) {
    return prefs.getInt('cashierId');
  }
  return null;
}

class ProductPage extends StatefulWidget {
  final int? id;

  const ProductPage({
    Key? key,
    required this.id,
  }) : super(key: key);

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  Product? product;
  bool isLoading = true;
  bool _isFavorited = false;
  final FavoriteService _favoriteService = FavoriteService();
  int? _currentCashierId;

  String _resolveImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    url = url.replaceAll('\\', '/');
    url = url.replaceAll(' ', '%20');

    if (!url.startsWith('/')) {
      url = '/$url';
    }

    return 'http://10.0.2.2:8080$url';
  }

  @override
  void initState() {
    super.initState();
    _initializeProductAndFavorites();
  }

  Future<void> _initializeProductAndFavorites() async {
    _currentCashierId = await getCashierId();
    // Walaupun cashierId null, kita tetap fetch produk (favorit cuma aktif kalau cashierId ada)
    fetchProductDetail();
  }

  Future<void> _forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('cashierId');
    await prefs.remove('cashierName');

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void fetchProductDetail() async {
    try {
      Product fetchedProduct =
          await ProductService().getProductById(widget.id!);

      bool favorited = false;
      if (_currentCashierId != null) {
        favorited = await _favoriteService.isProductFavorited(
          _currentCashierId!,
          fetchedProduct,
        );
      }

      setState(() {
        product = fetchedProduct;
        _isFavorited = favorited;
        isLoading = false;
      });
    } catch (e) {
      if (e.toString().contains('UNAUTHORIZED')) {
        await _forceLogout();
        return;
      }

      print('Error fetching product: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (product == null) {
      return const Scaffold(
        body: Center(child: Text('Gagal memuat produk')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          product!.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar
            SizedBox(
              height: 350,
              child: Image.network(
                _resolveImageUrl(product!.photoUrl),
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.broken_image)),
              ),
            ),
            const SizedBox(height: 20),

            // Nama produk (dibesarkan)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                product!.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 24, // <<< dibesarin di sini
                    ),
              ),
            ),

            // Kategori
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                product!.category,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
              ),
            ),
            const SizedBox(height: 8),

            // Harga
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                NumberFormat.currency(locale: 'id', symbol: 'Rp')
                    .format(product!.price),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
              ),
            ),
            const SizedBox(height: 16),

            // Tombol Favorit (tanpa ukuran, tanpa pesan login)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _currentCashierId == null
                      ? null // kalau belum ada cashierId, tombol non-aktif (silent)
                      : () async {
                          bool newFavoriteStatus =
                              await _favoriteService.toggleFavorite(
                            _currentCashierId!,
                            product!,
                          );
                          setState(() {
                            _isFavorited = newFavoriteStatus;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _isFavorited
                                    ? '${product!.name} ditambahkan ke favorit.'
                                    : '${product!.name} dihapus dari favorit.',
                              ),
                            ),
                          );
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.blueAccent),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isFavorited
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: _isFavorited
                            ? Colors.red
                            : Colors.blueAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isFavorited
                            ? "Sudah Favorit"
                            : "Tambahkan ke Favorit",
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
