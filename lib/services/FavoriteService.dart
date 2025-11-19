import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/Product.dart'; // Pastikan path ini benar ke model Product Anda

class FavoriteService {
  // Metode untuk menghasilkan kunci unik berdasarkan cashierId
  String _getFavoriteKey(int cashierId) {
    return 'cashier_favorites_$cashierId';
  }

  // Menyimpan daftar produk favorit untuk cashier tertentu
  Future<void> saveFavorites(int cashierId, List<Product> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final String favoriteKey = _getFavoriteKey(cashierId); // Dapatkan kunci unik

    // Konversi List<Product> menjadi List<Map<String, dynamic>>
    List<String> favoriteJson = favorites.map((product) => json.encode(product.toJson())).toList();
    await prefs.setStringList(favoriteKey, favoriteJson);
  }

  // Mendapatkan daftar produk favorit untuk cashier tertentu
  Future<List<Product>> getFavorites(int cashierId) async {
    final prefs = await SharedPreferences.getInstance();
    final String favoriteKey = _getFavoriteKey(cashierId); // Dapatkan kunci unik

    List<String>? favoriteJsonList = prefs.getStringList(favoriteKey);
    if (favoriteJsonList == null) {
      return [];
    }
    // Konversi List<String> JSON kembali menjadi List<Product>
    return favoriteJsonList.map((jsonString) => Product.fromJson(json.decode(jsonString))).toList();
  }

  // Menambah/menghapus produk dari daftar favorit untuk cashier tertentu
  Future<bool> toggleFavorite(int cashierId, Product product) async {
    List<Product> favorites = await getFavorites(cashierId); // Ambil favorit cashier ini
    bool isFavorited = favorites.any((favProduct) => favProduct.id == product.id);

    if (isFavorited) {
      // Hapus dari favorit
      favorites.removeWhere((favProduct) => favProduct.id == product.id);
      print('Product removed from favorites for cashier $cashierId: ${product.name}');
    } else {
      // Tambah ke favorit
      favorites.add(product);
      print('Product added to favorites for cashier $cashierId: ${product.name}');
    }
    await saveFavorites(cashierId, favorites); // Simpan favorit cashier ini
    return !isFavorited; // Mengembalikan status favorit terbaru
  }

  // Memeriksa apakah produk sudah ada di favorit untuk cashier tertentu
  Future<bool> isProductFavorited(int cashierId, Product product) async {
    List<Product> favorites = await getFavorites(cashierId); // Ambil favorit cashier ini
    return favorites.any((favProduct) => favProduct.id == product.id);
  }
}