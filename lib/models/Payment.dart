// payment.dart
class PaymentItemDTO {
  final int cashierId;
  String name;
  int quantity;
  double price; // Add product price
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
  int cashierId; // This is the cashier ID from SharedPreferences
  String paymentMethod;
  double totalAmount;

  PaymentDTO({
    required this.cashierId,
    required this.paymentMethod,
    required this.totalAmount,
  });

  Map<String, dynamic> toJson() => {
    'cashierId': cashierId,
    'paymentMethod': paymentMethod,
    'totalAmount': totalAmount,
  };

}