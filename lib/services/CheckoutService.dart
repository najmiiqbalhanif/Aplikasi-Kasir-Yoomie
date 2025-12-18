// services/CheckoutService.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/Payment.dart';
import '../models/cashier.dart';
import 'authHeader.dart'; // ✅ TAMBAHKAN

class CheckoutService {
  final String baseUrl;

  CheckoutService({required this.baseUrl});

  Future<void> submitCheckout(
      PaymentDTO payment,
      List<PaymentItemDTO> items,
      ) async {
    final url = Uri.parse('$baseUrl/api/checkoutpayment/submit');

    final body = {
      ...payment.toJson(),
      'paymentItems': items.map((item) => item.toJson()).toList(),
    };

    final response = await http.post(
      url,
      headers: await authHeader(), // ✅ WAJIB
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      throw Exception('UNAUTHORIZED');
    }

    if (response.statusCode != 200) {
      try {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Checkout gagal');
      } catch (_) {
        throw Exception('Checkout gagal: ${response.body}');
      }
    }
  }

  Future<Cashier> getCashierById(int cashierId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/cashiers/$cashierId'),
      headers: await authHeader(), // ✅ WAJIB
    );

    if (response.statusCode == 401) {
      throw Exception('UNAUTHORIZED');
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Cashier.fromJson(data);
    } else {
      throw Exception(
        'Failed to load cashier: ${response.statusCode} - ${response.body}',
      );
    }
  }
}
