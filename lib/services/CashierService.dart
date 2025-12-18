import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cashier.dart';

class CashierService {
  final String profileUrl = "http://10.0.2.2:8080/api/profilepage";
  final String editProfileUrl = "http://10.0.2.2:8080/api/editprofilepage";

  Future<Cashier?> fetchCashierProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cashierId = prefs.getInt('cashierId');

      if (cashierId == null) {
        print("Cashier ID not found in SharedPreferences.");
        return null;
      }

      final response = await http.get(Uri.parse("$profileUrl/$cashierId"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Cashier.fromJson(data);
      } else {
        print("Failed to load profile. Status code: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error fetching profile: $e");
      return null;
    }
  }

  Future<bool> updateCashierProfile({
    required String cashierName,
    required String email,
    required String fullName,
    String? profileImage,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cashierId = prefs.getInt('cashierId');

      if (cashierId == null) {
        print("Cashier ID not found in SharedPreferences.");
        return false;
      }

      var uri = Uri.parse("$editProfileUrl/$cashierId");
      var request = http.MultipartRequest("PUT", uri);
      request.fields['cashierName'] = cashierName;
      request.fields['email'] = email;
      request.fields['fullName'] = fullName;

      if (profileImage != null) {
        request.files.add(await http.MultipartFile.fromPath('profileImage', profileImage));
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        print("Profile updated successfully");
        return true;
      } else {
        print("Failed to update profile. Status code: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Error updating profile: $e");
      return false;
    }
  }

  // ✅ NEW: change password
  Future<String?> changeCashierPassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cashierId = prefs.getInt('cashierId');

      if (cashierId == null) {
        return "Cashier ID tidak ditemukan. Silakan login ulang.";
      }

      final url = Uri.parse("$editProfileUrl/$cashierId/password");
      final res = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "currentPassword": currentPassword,
          "newPassword": newPassword,
          "confirmPassword": confirmPassword,
        }),
      );

      if (res.statusCode == 200) return null;
      return res.body.isNotEmpty ? res.body : "Gagal update password.";
    } catch (e) {
      return "Error update password: $e";
    }
  }
}
