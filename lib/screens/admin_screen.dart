import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AdminScreen extends StatefulWidget {
  final String adminName;
  final String carWashName;

  const AdminScreen({
    Key? key,
    required this.adminName,
    required this.carWashName,
  }) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> allAppointments = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAppointments() async {
    setState(() => loading = true);
    final list = await ApiService.getAppointmentsByBranch(widget.carWashName);
    setState(() {
      allAppointments = list;
      loading = false;
    });
  }

  List<dynamic> get pendingAppointments => allAppointments
      .where((a) =>
          (a['status']?.toString().toLowerCase() ?? '') == 'beklemede' ||
          (a['status']?.toString().toLowerCase() ?? '') == 'pending')
      .toList();

  List<dynamic> get approvedAppointments => allAppointments
      .where((a) =>
          (a['status']?.toString().toLowerCase() ?? '') == 'onaylandı' ||
          (a['status']?.toString().toLowerCase() ?? '') == 'approved')
      .toList();

  List<dynamic> get rejectedAppointments => allAppointments
      .where((a) =>
          (a['status']?.toString().toLowerCase() ?? '') == 'reddedildi' ||
          (a['status']?.toString().toLowerCase() ?? '') == 'rejected')
      .toList();

  Future<void> _updateStatus(int id, String status) async {
    final success = await ApiService.updateAppointmentStatus(id, status);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                status == 'Onaylandı' ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Text(status == 'Onaylandı'
                  ? 'Randevu onaylandı'
                  : 'Randevu reddedildi'),
            ],
          ),
          backgroundColor: status == 'Onaylandı' ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _fetchAppointments();
    }
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

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          widget.carWashName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            _fetchAppointments();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text('Randevular yenileniyor...'),
                  ],
                ),
                duration: Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          icon: const Icon(Icons.refresh),
          tooltip: 'Yenile',
        ),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Çıkış Yap'),
                  content:
                      const Text('Çıkış yapmak istediğinize emin misiniz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _logout();
                      },
                      child: const Text('Çıkış',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pending_actions, size: 16),
                  const SizedBox(width: 4),
                  Text("Bekleyen (${pendingAppointments.length})",
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, size: 16),
                  const SizedBox(width: 4),
                  Text("Onaylı (${approvedAppointments.length})",
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cancel_outlined, size: 16),
                  const SizedBox(width: 4),
                  Text("Red (${rejectedAppointments.length})",
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentList(pendingAppointments, showActions: true),
                _buildAppointmentList(approvedAppointments, showActions: false),
                _buildAppointmentList(rejectedAppointments, showActions: false),
              ],
            ),
    );
  }

  Widget _buildAppointmentList(List<dynamic> appointments,
      {required bool showActions}) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "Randevu bulunamadı",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final a = appointments[index];
          return _buildAppointmentCard(a, showActions: showActions);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> a,
      {required bool showActions}) {
    final status = a['status']?.toString() ?? 'Beklemede';
    Color statusColor;

    switch (status.toLowerCase()) {
      case 'onaylandı':
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'reddedildi':
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

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

          // Detaylar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Kullanıcı Bilgisi
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.person,
                          color: Colors.blue.shade700, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a['user']?['name'] ?? a['userName'] ?? 'Müşteri',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            a['carPlate'] ?? '-',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 13),
                          ),
                          if (a['user']?['phone'] != null ||
                              a['userPhone'] != null)
                            Text(
                              a['user']?['phone'] ?? a['userPhone'] ?? '',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 12),
                            ),
                        ],
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
                const SizedBox(height: 12),

                // Hizmet ve Fiyat
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        icon: Icons.build_outlined,
                        label: "Hizmet",
                        value: a['serviceType'] ?? '-',
                      ),
                    ),
                    if (a['price'] != null)
                      Expanded(
                        child: _buildDetailItem(
                          icon: Icons.payments_outlined,
                          label: "Ücret",
                          value: "₺${a['price']}",
                          valueColor: Colors.green.shade700,
                        ),
                      ),
                  ],
                ),

                // Onay/Red butonları
                if (showActions) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showConfirmDialog(
                            a['id'],
                            'Onaylandı',
                            'Bu randevuyu onaylamak istediğinize emin misiniz?',
                          ),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text("Onayla"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showConfirmDialog(
                            a['id'],
                            'Reddedildi',
                            'Bu randevuyu reddetmek istediğinize emin misiniz?',
                          ),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text("Reddet"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showConfirmDialog(int id, String status, String message) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
            status == 'Onaylandı' ? "Randevuyu Onayla" : "Randevuyu Reddet"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  status == 'Onaylandı' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(status == 'Onaylandı' ? "Onayla" : "Reddet"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _updateStatus(id, status);
    }
  }
}
