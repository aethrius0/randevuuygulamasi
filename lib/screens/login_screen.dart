import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/services/api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool showLogin = true;
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();

  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPhone = TextEditingController();
  final _regPassword = TextEditingController();

  bool loading = false;
  String? message;

  void toggleForm() => setState(() => showLogin = !showLogin);

  Future<void> handleLogin() async {
    setState(() => loading = true);
    final result = await ApiService.login(_loginEmail.text, _loginPassword.text);
    setState(() => loading = false);

    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(result));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      setState(() => message = "E-posta veya şifre hatalı!");
    }
  }

  Future<void> handleRegister() async {
    setState(() => loading = true);
    final ok = await ApiService.register(
      _regName.text,
      _regEmail.text,
      _regPhone.text,
      _regPassword.text,
    );
    setState(() => loading = false);

    setState(() => message = ok ? "Kayıt başarılı! Giriş yapabilirsiniz." : "Kayıt başarısız.");
    if (ok) Future.delayed(const Duration(seconds: 2), toggleForm);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(showLogin ? "AutoWash" : "Kayıt Ol",
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  showLogin ? "Araba Yıkama Randevu Sistemi" : "Yeni hesap oluştur",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 25),

                if (message != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: message!.contains("başarılı")
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      message!,
                      style: TextStyle(
                        color: message!.contains("başarılı")
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                const SizedBox(height: 15),

                if (showLogin)
                  Column(
                    children: [
                      TextField(
                        controller: _loginEmail,
                        decoration: const InputDecoration(labelText: "E-posta"),
                      ),
                      TextField(
                        controller: _loginPassword,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: "Şifre"),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: loading ? null : handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Giriş Yap"),
                      ),
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: toggleForm,
                        child: const Text("Hesabın yok mu? Kayıt ol"),
                      )
                    ],
                  )
                else
                  Column(
                    children: [
                      TextField(
                        controller: _regName,
                        decoration: const InputDecoration(labelText: "Ad Soyad"),
                      ),
                      TextField(
                        controller: _regEmail,
                        decoration: const InputDecoration(labelText: "E-posta"),
                      ),
                      TextField(
                        controller: _regPhone,
                        decoration: const InputDecoration(labelText: "Telefon"),
                      ),
                      TextField(
                        controller: _regPassword,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: "Şifre"),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: loading ? null : handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Kayıt Ol"),
                      ),
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: toggleForm,
                        child: const Text("Zaten hesabın var mı? Giriş yap"),
                      )
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
