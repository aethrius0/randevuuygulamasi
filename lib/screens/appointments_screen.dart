import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/services/api_service.dart';
import 'add_appointment_screen.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user');

    if (data == null) return;

    final json = jsonDecode(data);
    userId = json['id'];

    await _fetchAppointments();
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

  Future<void> _deleteAppointment(int id) async {
    final success = await ApiService.deleteAppointment(id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Randevu silindi")),
      );
      _fetchAppointments();
    }
  }

  void _openAddAppointmentDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAppointmentPage(userId: userId!),
      ),
    ).then((_) => _fetchAppointments());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Randevularım"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddAppointmentDialog,
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : appointments.isEmpty
          ? const Center(child: Text("Bu kullanıcıya ait randevu bulunmuyor."))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, i) {
          final a = appointments[i];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.directions_car),
              title: Text("${a['carPlate']} - ${a['serviceType']}"),
              subtitle: Text(a['appointmentTime'].toString()),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddAppointmentPage(
                            userId: userId!,
                            appointment: a,
                          ),
                        ),
                      ).then((_) => _fetchAppointments());
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteAppointment(a['id']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
