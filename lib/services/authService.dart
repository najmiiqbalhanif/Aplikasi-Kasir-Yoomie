import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cashier.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/auth'; // ganti sesuai IP

  Future<bool> register(Cashier cashier) async {
    final url = Uri.parse('$baseUrl/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(cashier.toJson()),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print("Register failed: ${response.body}");
      return false;
    }
  }

  static Future<Cashier?> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Cashier.fromJson(data);
    } else {
      print("Login failed: ${response.body}");
      return null;
    }
  }
}
