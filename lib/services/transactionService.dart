import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transactionDTO.dart';
import 'authHeader.dart';

class TransactionService {
  final String baseUrl;

  TransactionService({required this.baseUrl});

  Future<List<TransactionDTO>> fetchAllTransactions() async {
    final url = Uri.parse('$baseUrl/api/transactions');

    try {
      final response = await http.get(
        url,
        headers: await authHeader(),
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse
            .map((data) => TransactionDTO.fromJson(data))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('UNAUTHORIZED');
      } else {
        throw Exception(
          'Failed to load transactions: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TransactionDTO>> fetchTransactionsByCashierId(int cashierId) async {
    final url =
    Uri.parse('$baseUrl/api/transactions/cashier/$cashierId');

    try {
      final response = await http.get(
        url,
        headers: await authHeader(),
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse
            .map((data) => TransactionDTO.fromJson(data))
            .toList();
      } else if (response.statusCode == 404) {
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('UNAUTHORIZED');
      } else {
        throw Exception(
          'Failed to load cashier transactions: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
