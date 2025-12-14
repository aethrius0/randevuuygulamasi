import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/services/api_service.dart';
import 'add_appointment_screen.dart';
import 'home_screen.dart'; // bayiler listesi için

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
    // Onay dialogu göster
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Randevuyu Sil"),
        content: const Text("Bu randevuyu silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Sil"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ApiService.deleteAppointment(id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text("Randevu başarıyla silindi"),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _fetchAppointments();
    }
  }

  void _openAddAppointmentDialog() {
    _showBayiSelectDialog();
  }

  void _showBayiSelectDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Bayi Seçin",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bayi Listesi
            ...bayiler
                .map((bayi) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddAppointmentPage(
                                userId: userId!,
                                bayiName: bayi.name,
                                bayiPrices: bayi.prices,
                              ),
                            ),
                          ).then((_) => _fetchAppointments());
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0066FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.local_car_wash,
                            color: Color(0xFF0066FF),
                          ),
                        ),
                        title: Text(
                          bayi.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Icon(Icons.star,
                                size: 14, color: Colors.amber.shade600),
                            const SizedBox(width: 4),
                            Text(
                              bayi.rating.toString(),
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.location_on,
                                size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              bayi.city,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF0066FF),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ))
                .toList(),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "";
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'onaylandı':
      case 'approved':
        return Colors.green;
      case 'beklemede':
      case 'pending':
        return Colors.orange;
      case 'iptal':
      case 'cancelled':
      case 'reddedildi':
      case 'rejected':
        return Colors.red;
      case 'tarihi geçti':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Randevularım",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddAppointmentDialog,
        backgroundColor: const Color(0xFF0066FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0066FF)),
            )
          : appointments.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchAppointments,
                  color: const Color(0xFF0066FF),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: appointments.length,
                    itemBuilder: (context, i) {
                      final a = appointments[i];
                      return _buildAppointmentCard(a);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Henüz randevunuz yok",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Yeni bir randevu oluşturmak için\naşağıdaki butona tıklayın",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> a) {
    String status = a['status']?.toString() ?? 'Beklemede';

    // Tarihi geçmiş mi kontrol et
    final appointmentTime = DateTime.tryParse(a['appointmentTime'] ?? '');
    final bool isExpired =
        appointmentTime != null && appointmentTime.isBefore(DateTime.now());

    // Eğer tarihi geçmişse ve durum "onaylandı" veya "beklemede" ise "Tarihi Geçti" yap
    if (isExpired &&
        (status.toLowerCase() == 'onaylandı' ||
            status.toLowerCase() == 'beklemede' ||
            status.toLowerCase() == 'approved' ||
            status.toLowerCase() == 'pending' ||
            status.toLowerCase() == 'aktif')) {
      status = 'Tarihi Geçti';
    }

    final statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Üst Kısım - Durum ve Bayi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_car_wash, color: statusColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      a['carWashName'] ?? 'Self CarWash',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Orta Kısım - Detaylar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Plaka ve Hizmet
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        icon: Icons.directions_car,
                        label: "Plaka",
                        value: a['carPlate'] ?? '-',
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        icon: Icons.build_outlined,
                        label: "Hizmet",
                        value: a['serviceType'] ?? '-',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Tarih ve Saat
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        icon: Icons.calendar_today,
                        label: "Tarih",
                        value: _formatDate(a['appointmentTime'] ?? ''),
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        icon: Icons.access_time,
                        label: "Saat",
                        value: _formatTime(a['appointmentTime'] ?? ''),
                      ),
                    ),
                  ],
                ),
                if (a['price'] != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          icon: Icons.payments_outlined,
                          label: "Ücret",
                          value: "₺${a['price']}",
                          valueColor: const Color(0xFF0066FF),
                        ),
                      ),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Alt Kısım - Butonlar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
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
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text("Düzenle"),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0066FF),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteAppointment(a['id']),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text("Sil"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
