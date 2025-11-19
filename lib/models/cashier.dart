class Cashier {
  final String cashierName;
  final String email;
  final String fullName;
  final String? profileImage;
  final String? password; // Optional, hanya dipakai saat register/login
  final int? id; // ID cashier dari backend, nullable karena tidak selalu dikirim dari client

  Cashier({
    required this.cashierName,
    required this.email,
    required this.fullName,
    this.profileImage,
    this.password,
    this.id,
  });

  // Digunakan saat ingin mengirim data ke backend (register/login)
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

  // Digunakan saat menerima data dari backend (login response)
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