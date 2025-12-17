class PaymentItemDTO {
  final int cashierId;
  String name;
  int quantity;
  double price;
  double subTotal;


  PaymentItemDTO({
    required this.cashierId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.subTotal,
  });

  Map<String, dynamic> toJson() => {
    'cashierId': cashierId,
    'productName': name,
    'quantity': quantity,
    'price': price,
    'subTotal': subTotal,
  };

}

class PaymentDTO {
  int cashierId;
  String paymentMethod;
  double totalAmount;
  final double? cashPaid;
  final double? changeAmount;

  PaymentDTO({
    required this.cashierId,
    required this.paymentMethod,
    required this.totalAmount,
    this.cashPaid,
    this.changeAmount,
  });

  Map<String, dynamic> toJson() => {
    'cashierId': cashierId,
    'paymentMethod': paymentMethod,
    'totalAmount': totalAmount,
    'cashPaid': cashPaid,
    'changeAmount': changeAmount,
  };
}
