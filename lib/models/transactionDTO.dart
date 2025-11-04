class TransactionDTO {
  final int id;
  final int userId;
  final String username;
  final String createdOn;
  final String cartSummary; // Ringkasan produk di cart
  final double totalAmount; // Total harga
  final String paymentMethod; // Metode pembayaran
  final String paymentStatus; // Status pembayaran
  final String address; // Alamat dari pembayaran

  TransactionDTO({
    required this.id,
    required this.userId,
    required this.username,
    required this.createdOn,
    required this.cartSummary,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.address,
  });

  factory TransactionDTO.fromJson(Map<String, dynamic> json) {
    return TransactionDTO(
      id: json['id'],
      userId: json['userId'],
      username: json['username'],
      createdOn: json['createdOn'],
      cartSummary: json['cartSummary'],
      totalAmount: json['totalAmount'].toDouble(),
      paymentMethod: json['paymentMethod'],
      paymentStatus: json['paymentStatus'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'createdOn': createdOn,
      'cartSummary': cartSummary,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'address': address,
    };
  }
}