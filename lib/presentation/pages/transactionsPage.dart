import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Untuk mendapatkan userId
import '../../models/transaction_dto.dart';
import '../../services/transactionService.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  List<TransactionDTO> transactions = [];
  bool isLoading = true;
  String? errorMessage;
  final TransactionService transactionService = TransactionService(baseUrl: 'http://10.0.2.2:8080'); // Inisialisasi service

  final NumberFormat currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchTransactions(); // Panggil saat initState
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId'); // Ambil userId dari SharedPreferences

      if (userId == null) {
        setState(() {
          isLoading = false;
          errorMessage = "User not logged in. Please log in to view your transactions.";
        });
        return;
      }

      // Ambil Transaction berdasarkan userId (lebih relevan)
      final fetchedTransactions = await transactionService.fetchTransactionsByUserId(userId);

      setState(() {
        transactions = fetchedTransactions;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching transactions: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load transactions. Please try again later. ($e)';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Transactions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchTransactions,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      )
          : transactions.isEmpty
          ? const Center(child: Text("No transactions found."))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Transaction ID: ${transaction.id}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text("Date: ${transaction.createdOn.split('T')[0]}") // Mengambil tanggal saja
                  ],
                ),
                Text(
                  currencyFormat.format(transaction.totalAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            children: [
              // Karena cartSummary adalah String, kita akan menampilkannya langsung
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment Method: ${transaction.paymentMethod}'),
                    Text('Payment Status: ${transaction.paymentStatus}'),
                    Text('Address: ${transaction.address}'),
                    const Divider(),
                    Text(
                      'Items: ${transaction.cartSummary}', // Menampilkan ringkasan cart
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}