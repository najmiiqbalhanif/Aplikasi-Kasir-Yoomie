class Cashier {
  final String cashierName;
  final String email;
  final String fullName;
  final String? profileImage;
  final String? password;
  final int? id;
  Cashier({
    required this.cashierName,
    required this.email,
    required this.fullName,
    this.profileImage,
    this.password,
    this.id,
  });

  Map<String, dynamic> toJson() {
    final data = {
      'cashierName': cashierName,
      'email': email,
      'fullName': fullName,
      'profileImage': profileImage ?? '',
    };
    if (password != null) {
      data['password'] = password!;
    }
    return data;
  }

  factory Cashier.fromJson(Map<String, dynamic> json) {
    return Cashier(
      id: json['id'],
      cashierName: json['cashierName'],
      email: json['email'],
      fullName: json['fullName'],
      profileImage: json['profileImage'],
    );
  }
}