class TransactionDTO {
  final int id;
  final int cashierId;
  final String cashierName;
  final String createdOn;
  final String cartSummary; // Ringkasan produk di cart
  final double totalAmount; // Total harga
  final String paymentMethod; // Metode pembayaran

  TransactionDTO({
    required this.id,
    required this.cashierId,
    required this.cashierName,
    required this.createdOn,
    required this.cartSummary,
    required this.totalAmount,
    required this.paymentMethod,
  });

  factory TransactionDTO.fromJson(Map<String, dynamic> json) {
    return TransactionDTO(
      id: json['id'],
      cashierId: json['cashierId'],
      cashierName: json['cashierName'],
      createdOn: json['createdOn'],
      cartSummary: json['cartSummary'],
      totalAmount: json['totalAmount'].toDouble(),
      paymentMethod: json['paymentMethod'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cashierId': cashierId,
      'cashierName': cashierName,
      'createdOn': createdOn,
      'cartSummary': cartSummary,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
    };
  }
}