import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import 'authHeader.dart';

class Homepageservice {
  static const String baseUrl = 'http://192.168.0.194:8080';
  static const String endpoint = '/api/cashier/homepage-products';

  static Future<List<Product>> fetchHomepageProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await authHeader(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Product.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('UNAUTHORIZED');
    } else {
      throw Exception('Failed to load products: ${response.body}');
    }
  }
}
