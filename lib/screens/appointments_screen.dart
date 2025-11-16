import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  bool loading = true;
  List<dynamic> appointments = [];
  int? userId;

  @override
  void initState() {
    super.initState();
    _loadUserAndAppointments();
  }

  Future<void> _loadUserAndAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('user');
      if (data == null) {
        setState(() {
          loading = false;
        });
        return;
      }

      final json = jsonDecode(data);
      userId = json['id'];
      await _fetchAppointments();
    } catch (e) {
      debugPrint("Randevu yükleme hatası: $e");
      setState(() => loading = false);
    }
  }

  Future<void> _fetchAppointments() async {
    if (userId == null) return;

    setState(() => loading = true);
    final list = await ApiService.getAppointments(userId!);
    setState(() {
      appointments = list;
      loading = false;
    });
  }

  // İLERİDE POST/DELETE ekleriz, şimdilik sadece listeleme

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Randevularım"),
        centerTitle: true,
      ),
      body: appointments.isEmpty
          ? const Center(child: Text("Bu hesaba ait randevu bulunmuyor."))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final a = appointments[index];
          final plate = a['carPlate'] ?? '';
          final service = a['serviceType'] ?? '';
          final timeStr = a['appointmentTime']?.toString() ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text("$plate - $service"),
              subtitle: Text(timeStr),
              leading: const Icon(Icons.directions_car),
            ),
          );
        },
      ),
    );
  }
}
