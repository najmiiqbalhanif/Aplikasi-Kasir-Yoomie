import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/CartItem.dart';
import 'authHeader.dart';

class CartService {
  static const String BASE_URL = 'http://10.0.2.2:8080';

  Future<List<CartItem>> getCartItems(int cashierId) async {
    final url = Uri.parse('$BASE_URL/api/cart/items/$cashierId');

    final response = await http.get(
      url,
      headers: await authHeader(), // ← WAJIB
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => CartItem.fromJson(data)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else if (response.statusCode == 401) {
      throw Exception('UNAUTHORIZED');
    } else {
      throw Exception('Failed to load cart items: ${response.body}');
    }
  }

  Future<void> addProductToCart(int cashierId, int productId) async {
    final url = Uri.parse(
        '$BASE_URL/api/cart/add?cashierId=$cashierId&productId=$productId');

    final response = await http.post(
      url,
      headers: await authHeader(),
    );

    if (response.statusCode == 401) {
      throw Exception('UNAUTHORIZED');
    }
    if (response.statusCode != 200) {
      throw Exception('Failed to add product to cart');
    }
  }

  Future<void> decreaseProductQuantity(int cashierId, int productId) async {
    final url = Uri.parse(
        '$BASE_URL/api/cart/decrease?cashierId=$cashierId&productId=$productId');

    final response = await http.post(
      url,
      headers: await authHeader(),
    );

    if (response.statusCode == 401) {
      throw Exception('UNAUTHORIZED');
    }
    if (response.statusCode != 200) {
      throw Exception('Failed to decrease quantity');
    }
  }

  Future<void> removeProductFromCart(int cashierId, int productId) async {
    final url = Uri.parse(
        '$BASE_URL/api/cart/remove?cashierId=$cashierId&productId=$productId');

    final response = await http.delete(
      url,
      headers: await authHeader(),
    );

    if (response.statusCode == 401) {
      throw Exception('UNAUTHORIZED');
    }
    if (response.statusCode != 200) {
      throw Exception('Failed to remove item');
    }
  }

  Future<void> updateProductQuantity(
      int cashierId, int productId, int newQuantity) async {
    final url = Uri.parse(
        '$BASE_URL/api/cart/updateQuantity?cashierId=$cashierId&productId=$productId&quantity=$newQuantity');

    final response = await http.post(
      url,
      headers: await authHeader(),
    );

    if (response.statusCode == 401) {
      throw Exception('UNAUTHORIZED');
    }
    if (response.statusCode != 200) {
      throw Exception('Failed to update product quantity');
    }
  }
}
