import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transactionDTO.dart'; // Buat model ini jika belum ada

class TransactionService {
  final String baseUrl;

  TransactionService({required this.baseUrl});

  Future<List<TransactionDTO>> fetchAllTransactions() async {
    final url = Uri.parse('$baseUrl/api/transactions'); // Sesuaikan dengan endpoint yang Anda buat
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => TransactionDTO.fromJson(data)).toList();
      } else {
        throw Exception('Failed to load transactions: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching transactions: $e');
      throw Exception('Network error or failed to fetch transactions: $e');
    }
  }

  Future<List<TransactionDTO>> fetchTransactionsByUserId(int userId) async {
    final url = Uri.parse('$baseUrl/api/transactions/user/$userId'); // Endpoint untuk user tertentu
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => TransactionDTO.fromJson(data)).toList();
      } else if (response.statusCode == 404) {

        return [];
      }
      else {
        throw Exception('Failed to load user transactions: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching user transactions: $e');
      throw Exception('Network error or failed to fetch user transactions: $e');
    }
  }
}