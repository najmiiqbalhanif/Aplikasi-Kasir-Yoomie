import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, String>> authHeader() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  print("-------------------AUTH HEADER TOKEN: $token");

  return {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}
