import 'package:flutter/material.dart';
import '/services/api_service.dart';

class AddAppointmentPage extends StatefulWidget {
  final int userId;
  final Map<String, dynamic>? appointment;

  const AddAppointmentPage({Key? key, required this.userId, this.appointment})
      : super(key: key);

  @override
  State<AddAppointmentPage> createState() => _AddAppointmentPageState();
}

class _AddAppointmentPageState extends State<AddAppointmentPage> {
  final _plateController = TextEditingController();
  String? _selectedService;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final List<String> _serviceTypes = [
    "İç-Dış Yıkama",
    "Detaylı Temizlik",
    "Seramik Kaplama"
  ];

  @override
  void initState() {
    super.initState();

    if (widget.appointment != null) {
      _plateController.text = widget.appointment!["carPlate"];
      _selectedService = widget.appointment!["serviceType"];
      DateTime dt = DateTime.parse(widget.appointment!["appointmentTime"]);
      _selectedDate = dt;
      _selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      initialDate: _selectedDate ?? DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked =
    await showTimePicker(context: context, initialTime: TimeOfDay.now());

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveAppointment() async {
    if (_plateController.text.isEmpty ||
        _selectedService == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Tüm alanları doldurun")));
      return;
    }

    final date = _selectedDate!;
    final time = _selectedTime!;
    final appointmentTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    ).toIso8601String();

    final data = {
      "carPlate": _plateController.text,
      "serviceType": _selectedService,
      "appointmentTime": appointmentTime,
      "userId": widget.userId
    };

    bool success;

    if (widget.appointment == null) {
      // YENİ RANDEVU
      success = await ApiService.createAppointment(data);
    } else {
      // DÜZENLEME
      success =
      await ApiService.updateAppointment(widget.appointment!["id"], data);
    }

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hata oluştu")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appointment == null
            ? "Yeni Randevu"
            : "Randevuyu Düzenle"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _plateController,
              decoration: const InputDecoration(labelText: "Plaka"),
            ),
            const SizedBox(height: 15),

            // 🔥 DROP-DOWN
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Hizmet Türü"),
              value: _selectedService,
              items: _serviceTypes
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedService = v),
            ),

            const SizedBox(height: 20),

            // 🔥 TARİH SEÇİCİ
            ListTile(
              tileColor: Colors.grey.shade200,
              title: Text(
                _selectedDate == null
                    ? "Tarih seç"
                    : "${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}",
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),

            const SizedBox(height: 10),

            // 🔥 SAAT SEÇİCİ
            ListTile(
              tileColor: Colors.grey.shade200,
              title: Text(_selectedTime == null
                  ? "Saat seç"
                  : "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}"),
              trailing: const Icon(Icons.access_time),
              onTap: _pickTime,
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: _saveAppointment,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                backgroundColor: Colors.black,
              ),
              child: const Text("Kaydet"),
            ),
          ],
        ),
      ),
    );
  }
}
