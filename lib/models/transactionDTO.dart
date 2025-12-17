class TransactionDTO {
  final int id;
  final int cashierId;
  final String cashierName;
  final String createdOn;
  final String cartSummary;
  final double totalAmount;
  final String paymentMethod;
  final double? cashPaid;
  final double? changeAmount;

  TransactionDTO({
    required this.id,
    required this.cashierId,
    required this.cashierName,
    required this.createdOn,
    required this.cartSummary,
    required this.totalAmount,
    required this.paymentMethod,
    this.cashPaid,
    this.changeAmount,
  });

  factory TransactionDTO.fromJson(Map<String, dynamic> json) {
    return TransactionDTO(
      id: json['id'],
      cashierId: json['cashierId'],
      cashierName: json['cashierName'],
      createdOn: json['createdOn'],
      cartSummary: json['cartSummary'],
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paymentMethod: json['paymentMethod'],
      cashPaid: json['cashPaid'] == null ? null : (json['cashPaid'] as num).toDouble(),
      changeAmount: json['changeAmount'] == null ? null : (json['changeAmount'] as num).toDouble(),
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
      'cashPaid': cashPaid,
      'changeAmount': changeAmount,
    };
  }
}
