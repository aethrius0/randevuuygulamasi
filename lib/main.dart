import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const AutoWashApp());
}

class AutoWashApp extends StatelessWidget {
  const AutoWashApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AutoWash',
      theme: ThemeData(useMaterial3: true, primaryColor: Colors.black),
      home: const LoginScreen(),
    );
  }
}
