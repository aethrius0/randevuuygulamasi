import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = "Bilinmiyor";
  String email = "example@mail.com";
  String phone = "0555 123 4567";

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('user');
      if (data != null) {
        final user = jsonDecode(data);
        setState(() {
          name = user['name'] ?? "Bilinmiyor";
          email = user['email'] ?? "example@mail.com";
          phone = user['phone'] ?? "0555 123 4567";
        });
      }
    } catch (e) {
      debugPrint("Profil yükleme hatası: $e");
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 6),
                )
              ],
            ),
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person, size: 100, color: Colors.black87),
                const SizedBox(height: 10),
                Text(name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(email, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 5),
                Text(phone, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 25),
                ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text("Çıkış Yap"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
