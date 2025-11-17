import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2:5227/api";

  // LOGIN
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  // REGISTER
  static Future<bool> register(String name, String email, String phone, String password) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "phone": phone,
        "passwordHash": password
      }),
    );
    return res.statusCode == 200;
  }

  // GET appointments (USER’A ÖZEL)
  static Future<List<dynamic>> getAppointments(int userId) async {
    final res = await http.get(Uri.parse("$baseUrl/Randevu/$userId"));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  // CREATE appointment
  static Future<bool> createAppointment(Map<String, dynamic> appointment) async {
    final res = await http.post(
      Uri.parse("$baseUrl/Randevu"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(appointment),
    );
    return res.statusCode == 200;
  }

  // UPDATE appointment
  static Future<bool> updateAppointment(int id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse("$baseUrl/Randevu/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    return res.statusCode == 200;
  }

  // DELETE appointment
  static Future<bool> deleteAppointment(int id) async {
    final res = await http.delete(Uri.parse("$baseUrl/Randevu/$id"));
    return res.statusCode == 200;
  }
}
