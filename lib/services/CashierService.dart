import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cashier.dart';
import 'authHeader.dart';

class CashierService {
  final String profileUrl = "http://172.20.10.5/api/profilepage";
  final String editProfileUrl = "http://172.20.10.5/api/editprofilepage";

  Future<Cashier?> fetchCashierProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cashierId = prefs.getInt('cashierId');
      final token = prefs.getString('token');
      if (cashierId == null) return null;

      final response = await http.get(
        Uri.parse("$profileUrl/$cashierId"),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Cashier.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('UNAUTHORIZED');
      } else {
        return null;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateCashierProfile({
    required String cashierName,
    required String email,
    required String fullName,
    String? profileImage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cashierId = prefs.getInt('cashierId');
    if (cashierId == null) return false;

    var uri = Uri.parse("$editProfileUrl/$cashierId");
    var request = http.MultipartRequest("PUT", uri);

    request.fields['cashierName'] = cashierName;
    request.fields['email'] = email;
    request.fields['fullName'] = fullName;

    // ✅ tambahkan Authorization ke MultipartRequest
    request.headers.addAll(await authHeader());

    if (profileImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath('profileImage', profileImage),
      );
    }

    var response = await request.send();

    if (response.statusCode == 200) return true;
    if (response.statusCode == 401) throw Exception('UNAUTHORIZED');
    return false;
  }

  Future<String?> changeCashierPassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cashierId = prefs.getInt('cashierId');
      if (cashierId == null) return "Cashier ID tidak ditemukan. Silakan login ulang.";

      final url = Uri.parse("$editProfileUrl/$cashierId/password");
      final res = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          ...await authHeader(), // ✅ WAJIB
        },
        body: jsonEncode({
          "currentPassword": currentPassword,
          "newPassword": newPassword,
          "confirmPassword": confirmPassword,
        }),
      );

      if (res.statusCode == 200) return null;
      if (res.statusCode == 401) return "UNAUTHORIZED";
      return res.body.isNotEmpty ? res.body : "Gagal update password.";
    } catch (e) {
      return "Error update password: $e";
    }
  }
}
