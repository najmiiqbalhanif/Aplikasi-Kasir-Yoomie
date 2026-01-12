import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // NEW
import '../models/cashier.dart';

class AuthService {
  static const String baseUrl = 'http://172.20.10.5/api/auth';

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

  // NEW: logout
  static Future<void> logout() async {
    try {
      final url = Uri.parse('$baseUrl/logout');
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
      );
    } catch (e) {
      // kalau API error, tetap lanjut clear local session
      print('Logout API error: $e');
    }

    // bersihkan sesi lokal
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cashierId');
    await prefs.remove('cashierName');
  }
}
