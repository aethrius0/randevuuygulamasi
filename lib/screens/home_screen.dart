import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/bottom_navbar.dart';
import 'appointments_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "Kullanıcı";
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user');
    if (data != null) {
      final json = jsonDecode(data);
      setState(() {
        userName = json["name"] ?? "Kullanıcı";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeMap(userName: userName),
      const AppointmentsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavbar(
        currentIndex: currentIndex,
        onTap: (i) {
          setState(() => currentIndex = i);
        },
      ),
    );
  }
}

class HomeMap extends StatelessWidget {
  final String userName;

  const HomeMap({Key? key, required this.userName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // DİNAMİK HARİTA
        FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(41.0082, 28.9784), // İstanbul
            initialZoom: 12,
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            ),
          ],
        ),

        // HOŞ GELDİN BAR
        Positioned(
          top: 50,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black12,
                  ),
                ],
              ),
              child: Text(
                "Hoş geldin, $userName",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
