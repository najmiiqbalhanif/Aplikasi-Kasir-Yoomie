import '../models/Product.dart';

class CartItem {
  Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice => product.price * quantity;

  void incrementQuantity() {
    quantity++;
  }

  void decrementQuantity() {
    if (quantity > 1) {
      quantity--;
    }
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {

    return CartItem(
      product: Product.fromJson(json['product']),
      quantity: json['quantity'] as int,
    );
  }

  void updateQuantity(int newQuantity) {
    if (newQuantity >= 0) {
      quantity = newQuantity;
    }
  }
}