import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/Product.dart';
import 'authHeader.dart';

class ProductService {
  final String baseUrl = 'http://172.20.10.5:8080/api/pospage';

  Future<List<Product>> getProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/get'),
      headers: await authHeader(),
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((jsonItem) => Product.fromJson(jsonItem)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('UNAUTHORIZED');
    } else {
      throw Exception('Failed to load products: ${response.body}');
    }
  }

  Future<Product> getProductById(int id) async {
    final url = Uri.parse(
      'http://172.20.10.5/api/productpage/get/$id',
    );

    final response = await http.get(
      url,
      headers: await authHeader(),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return Product.fromJson(jsonData);
    } else if (response.statusCode == 401) {
      throw Exception('UNAUTHORIZED'); // ✅ trigger auto logout
    } else {
      throw Exception(
        'Failed to load product with id $id: ${response.body}',
      );
    }
  }
}
