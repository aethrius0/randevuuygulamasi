import 'package:flutter/material.dart';
import '/services/api_service.dart';

class AddAppointmentPage extends StatefulWidget {
  final int userId;
  final Map<String, dynamic>? appointment;
  final String? bayiName;
  final Map<String, double>? bayiPrices;

  const AddAppointmentPage({
    Key? key,
    required this.userId,
    this.appointment,
    this.bayiName,
    this.bayiPrices,
  }) : super(key: key);

  @override
  State<AddAppointmentPage> createState() => _AddAppointmentPageState();
}

class _AddAppointmentPageState extends State<AddAppointmentPage> {
  final _plateController = TextEditingController();
  String? _selectedService;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;

  // Hizmet türleri
  final List<String> _serviceTypes = [
    "Dış Yıkama-Köpük",
    "Detaylı Temizlik",
    "Seramik Kaplama",
    "Pasta Cila",
    "Motor Temizliği",
  ];

  // 09:00 - 18:00 arası 30 dakika aralıklı saatler
  final List<String> _timeSlots = [
    "09:00",
    "09:30",
    "10:00",
    "10:30",
    "11:00",
    "11:30",
    "12:00",
    "12:30",
    "13:00",
    "13:30",
    "14:00",
    "14:30",
    "15:00",
    "15:30",
    "16:00",
    "16:30",
    "17:00",
    "17:30",
    "18:00",
  ];

  @override
  void initState() {
    super.initState();

    if (widget.appointment != null) {
      _plateController.text = widget.appointment!["carPlate"];
      _selectedService = widget.appointment!["serviceType"];
      DateTime dt = DateTime.parse(widget.appointment!["appointmentTime"]);
      _selectedDate = dt;
      // Saat formatını ayarla
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      _selectedTimeSlot = "$hour:$minute";
    }
  }

  // Hizmet türüne göre fiyat (bayiye göre dinamik)
  double _getServicePrice(String serviceType) {
    // Eğer bayi fiyatları varsa oradan al
    if (widget.bayiPrices != null &&
        widget.bayiPrices!.containsKey(serviceType)) {
      return widget.bayiPrices![serviceType]!;
    }
    // Varsayılan fiyatlar
    switch (serviceType) {
      case "Dış Yıkama-Köpük":
        return 150.0;
      case "Detaylı Temizlik":
        return 350.0;
      case "Seramik Kaplama":
        return 1200.0;
      case "Pasta Cila":
        return 800.0;
      case "Motor Temizliği":
        return 250.0;
      default:
        return 0.0;
    }
  }

  // Hizmet adı + fiyat gösterimi için
  String _getServiceDisplayName(String serviceType) {
    final price = _getServicePrice(serviceType);
    return "$serviceType - ₺${price.toInt()}";
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

  Future<void> _saveAppointment() async {
    if (_plateController.text.isEmpty ||
        _selectedService == null ||
        _selectedDate == null ||
        _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Tüm alanları doldurun")));
      return;
    }

    final date = _selectedDate!;
    // Seçilen saatten hour ve minute parse et
    final timeParts = _selectedTimeSlot!.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final appointmentTime = DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    ).toIso8601String();

    // Hizmet türüne göre fiyat belirleme
    final price = _getServicePrice(_selectedService!);

    final data = {
      "carPlate": _plateController.text,
      "serviceType": _selectedService,
      "appointmentTime": appointmentTime,
      "carWashName": widget.bayiName ?? "Self CarWash",
      "price": price,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Text(widget.appointment == null
                    ? "Randevu başarıyla oluşturuldu"
                    : "Randevu güncellendi"),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 10),
              Text("Bir hata oluştu, tekrar deneyin"),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String title;
    if (widget.appointment != null) {
      title = "Randevuyu Düzenle";
    } else if (widget.bayiName != null) {
      title = widget.bayiName!;
    } else {
      title = "Yeni Randevu";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            if (widget.bayiName != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0066FF).withOpacity(0.1),
                      const Color(0xFF00D4FF).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF0066FF)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.bayiName!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0066FF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Form Başlığı
            const Text(
              "Randevu Bilgileri",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),

            // Araç Plakası
            TextField(
              controller: _plateController,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: "Araç Plakası",
                hintText: "34 ABC 123",
                prefixIcon: const Icon(Icons.directions_car_outlined),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0xFF0066FF), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 🔥 HİZMET TÜRÜ DROP-DOWN
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Hizmet Türü",
                prefixIcon: const Icon(Icons.local_car_wash_outlined),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0xFF0066FF), width: 2),
                ),
              ),
              value: _selectedService,
              items: _serviceTypes
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(_getServiceDisplayName(e)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedService = v),
            ),

            const SizedBox(height: 24),

            // Tarih ve Saat Başlığı
            const Text(
              "Tarih ve Saat",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),

            // 🔥 TARİH SEÇİCİ
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF0066FF),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Tarih",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedDate == null
                              ? "Tarih seçin"
                              : "${_selectedDate!.day.toString().padLeft(2, '0')}.${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.year}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _selectedDate == null
                                ? Colors.grey.shade500
                                : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🔥 SAAT SEÇİCİ (09:00 - 18:00, 30 dk aralıklı)
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Saat",
                prefixIcon: const Icon(Icons.access_time_outlined),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0xFF0066FF), width: 2),
                ),
              ),
              value: _selectedTimeSlot,
              items: _timeSlots
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedTimeSlot = v),
            ),

            const SizedBox(height: 40),

            // Kaydet Butonu
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  widget.appointment == null
                      ? "Randevu Oluştur"
                      : "Değişiklikleri Kaydet",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
