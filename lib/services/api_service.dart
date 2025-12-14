import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class ApiService {
  // HTTPS kullanmak için URL'i değiştirin
  static const String baseUrl = "https://10.0.2.2:7041/api";

  // Self-signed sertifikaları kabul eden HTTP client
  static http.Client _createHttpClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    return IOClient(httpClient);
  }

  static final http.Client _client = _createHttpClient();

  // giriş
  static Future<Map<String, dynamic>?> login(
      String email, String password) async {
    final res = await _client.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  // kayıt ol
  static Future<bool> register(
      String name, String email, String phone, String password) async {
    final res = await _client.post(
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

  // GET appointment000
  static Future<List<dynamic>> getAppointments(int userId) async {
    final res = await _client.get(Uri.parse("$baseUrl/Randevu/$userId"));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  // CREATE appointment
  static Future<bool> createAppointment(
      Map<String, dynamic> appointment) async {
    final res = await _client.post(
      Uri.parse("$baseUrl/Randevu"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(appointment),
    );
    return res.statusCode == 200;
  }

  // UPDATE appointment
  static Future<bool> updateAppointment(
      int id, Map<String, dynamic> data) async {
    final res = await _client.put(
      Uri.parse("$baseUrl/Randevu/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    return res.statusCode == 200;
  }

  // DELETE appointment
  static Future<bool> deleteAppointment(int id) async {
    final res = await _client.delete(Uri.parse("$baseUrl/Randevu/$id"));
    return res.statusCode == 200;
  }

  // GET appointments by branchName (Bayi Admin için)
  static Future<List<dynamic>> getAppointmentsByBranch(
      String branchName) async {
    final encodedName = Uri.encodeComponent(branchName);
    final res = await _client
        .get(Uri.parse("$baseUrl/admin/appointments/$encodedName"));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  // Randevu durumunu güncelle (Admin için)
  static Future<bool> updateAppointmentStatus(int id, String status) async {
    final res = await _client.put(
      Uri.parse("$baseUrl/admin/appointments/$id/status"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"status": status}),
    );
    return res.statusCode == 200;
  }

  // Admin login
  static Future<Map<String, dynamic>?> adminLogin(
      String email, String password) async {
    final res = await _client.post(
      Uri.parse("$baseUrl/admin/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }
}
