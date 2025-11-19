// services/cartService.dart
import 'package:http/http.dart' as http; // Pastikan Anda sudah mengimpor package http
import 'dart:convert'; // Untuk encoding/decoding JSON jika diperlukan
import '../models/CartItem.dart'; // Jika CartItem dibutuhkan di sini (misalnya untuk getCartItems)
import '../models/Product.dart';   // Jika Product dibutuhkan di sini

class CartService {
  // Pastikan BASE_URL tidak memiliki karakter ekstra
  // Gunakan IP 10.0.2.2 untuk emulator Android
  // Gunakan IP 127.0.0.1 atau IP lokal mesin Anda untuk simulator iOS/perangkat fisik
  static const String BASE_URL = 'http://10.0.2.2:8080';

  // --- Metode untuk mendapatkan item keranjang ---
  Future<List<CartItem>> getCartItems(int cashierId) async {
    final url = Uri.parse('$BASE_URL/api/cart/items/$cashierId');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => CartItem.fromJson(data)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to load cart items: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching cart items: $e'); // Untuk debugging
      throw Exception('Failed to connect to server or parse data: $e');
    }
  }

  // --- Metode untuk menambah produk ke keranjang ---
  Future<void> addProductToCart(int cashierId, int productId) async {
    final url = Uri.parse('$BASE_URL/api/cart/add?cashierId=$cashierId&productId=$productId');
    final response = await http.post(url); // Atau GET jika API Anda menggunakan GET untuk add

    if (response.statusCode != 200) {
      throw Exception('Failed to add product to cart: ${response.body}');
    }
  }

  // --- Metode untuk mengurangi kuantitas produk ---
  Future<void> decreaseProductQuantity(int cashierId, int productId) async {
    final url = Uri.parse('$BASE_URL/api/cart/decrease?cashierId=$cashierId&productId=$productId');
    final response = await http.post(url); // Menggunakan POST seperti di controller Anda

    if (response.statusCode != 200) {
      throw Exception('Failed to decrease quantity: ${response.body}');
    }
  }

  // --- Metode untuk menghapus produk dari keranjang ---
  Future<void> removeProductFromCart(int cashierId, int productId) async {
    final url = Uri.parse('$BASE_URL/api/cart/remove?cashierId=$cashierId&productId=$productId');
    final response = await http.delete(url); // Menggunakan DELETE seperti di controller Anda

    if (response.statusCode != 200) {
      throw Exception('Failed to remove item: ${response.body}');
    }
  }

  // --- Metode untuk memperbarui kuantitas produk ---
  Future<void> updateProductQuantity(int cashierId, int productId, int newQuantity) async {
    // PASTIKAN PEMBENTUKAN URL BERSIH DARI KARAKTER TAMBAHAN
    final url = Uri.parse('$BASE_URL/api/cart/updateQuantity?cashierId=$cashierId&productId=$productId&quantity=$newQuantity');

    final response = await http.post(url); // Menggunakan POST seperti di controller Anda

    if (response.statusCode != 200) {
      throw Exception('Failed to update product quantity: ${response.body}');
    }
  }
}