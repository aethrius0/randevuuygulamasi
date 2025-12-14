import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/bottom_navbar.dart';
import '../services/api_service.dart';
import 'appointments_screen.dart';
import 'profile_screen.dart';
import 'add_appointment_screen.dart';

// Bayi modeli
class Bayi {
  final String name;
  final String city;
  final LatLng location;
  final double rating;
  final String distance;
  final int id;
  final Map<String, double> prices;
  final String imageAsset;

  Bayi({
    required this.name,
    required this.city,
    required this.location,
    required this.rating,
    required this.distance,
    required this.id,
    required this.prices,
    required this.imageAsset,
  });
}

// Bayiler listesi
final List<Bayi> bayiler = [
  Bayi(
    id: 1,
    name: "Self CarWash İstanbul",
    city: "İstanbul",
    location: LatLng(41.0082, 28.9784),
    rating: 4.5,
    distance: "444.7 km",
    imageAsset: "assets/images/carwash3.jpg",
    prices: {
      "Dış Yıkama-Köpük": 200,
      "Detaylı Temizlik": 450,
      "Seramik Kaplama": 1600,
      "Pasta Cila": 1000,
      "Motor Temizliği": 350,
    },
  ),
  Bayi(
    id: 2,
    name: "Self CarWash Tekirdağ",
    city: "Tekirdağ",
    location: LatLng(40.9833, 27.5167),
    rating: 4.9,
    distance: "592.2 km",
    imageAsset: "assets/images/carwash2.png",
    prices: {
      "Dış Yıkama-Köpük": 180,
      "Detaylı Temizlik": 400,
      "Seramik Kaplama": 1400,
      "Pasta Cila": 900,
      "Motor Temizliği": 300,
    },
  ),
  Bayi(
    id: 3,
    name: "Self CarWash Ankara",
    city: "Ankara",
    location: LatLng(39.9334, 32.8597),
    rating: 4.7,
    distance: "13.55 km",
    imageAsset: "assets/images/carwash4.jpg",
    prices: {
      "Dış Yıkama-Köpük": 170,
      "Detaylı Temizlik": 380,
      "Seramik Kaplama": 1300,
      "Pasta Cila": 850,
      "Motor Temizliği": 280,
    },
  ),
  Bayi(
    id: 4,
    name: "Self CarWash Şanlıurfa",
    city: "Şanlıurfa",
    location: LatLng(37.1674, 38.7955),
    rating: 5.0,
    distance: "854.1 km",
    imageAsset: "assets/images/carwash.png",
    prices: {
      "Dış Yıkama-Köpük": 150,
      "Detaylı Temizlik": 350,
      "Seramik Kaplama": 1200,
      "Pasta Cila": 800,
      "Motor Temizliği": 250,
    },
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "Kullanıcı";
  int? userId;
  int currentIndex = 0;
  final PageController _pageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user');
    if (data != null) {
      final json = jsonDecode(data);
      setState(() {
        userName = json["name"] ?? "Kullanıcı";
        userId = json["id"];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeMap(userName: userName, userId: userId),
      const AppointmentsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: pages,
        onPageChanged: (index) {
          setState(() => currentIndex = index);
        },
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: currentIndex,
        onTap: (i) {
          _pageController.animateToPage(
            i,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          setState(() => currentIndex = i);
        },
      ),
    );
  }
}

class HomeMap extends StatefulWidget {
  final String userName;
  final int? userId;

  const HomeMap({Key? key, required this.userName, this.userId})
      : super(key: key);

  @override
  State<HomeMap> createState() => _HomeMapState();
}

class _HomeMapState extends State<HomeMap> {
  int totalAppointments = 0;
  int activeAppointments = 0;
  Map<String, dynamic>? upcomingAppointment;
  bool loading = true;
  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  @override
  void didUpdateWidget(HomeMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // userId değiştiğinde verileri yeniden çek
    if (oldWidget.userId != widget.userId && widget.userId != null) {
      _fetchStats();
    }
  }

  Future<void> _fetchStats() async {
    if (widget.userId == null) {
      setState(() => loading = false);
      return;
    }
    try {
      final appointments = await ApiService.getAppointments(widget.userId!);
      final now = DateTime.now();
      setState(() {
        totalAppointments = appointments.length;
        // Aktif = Onaylandı/Beklemede/Aktif ve tarihi geçmemiş
        activeAppointments = appointments.where((a) {
          final status = a['status']?.toString().toLowerCase() ?? '';
          final dt = DateTime.tryParse(a['appointmentTime'] ?? '');
          final isNotExpired = dt != null && dt.isAfter(now);
          final isActiveStatus = status == 'aktif' ||
              status == 'onaylandı' ||
              status == 'approved' ||
              status == 'beklemede' ||
              status == 'pending';
          return isActiveStatus && isNotExpired;
        }).length;
        // Yaklaşan randevuyu bul (reddedilmemiş ve tarihi geçmemiş)
        final upcoming = appointments.where((a) {
          final dt = DateTime.tryParse(a['appointmentTime'] ?? '');
          final status = a['status']?.toString().toLowerCase() ?? '';
          final isRejected = status == 'reddedildi' ||
              status == 'rejected' ||
              status == 'iptal' ||
              status == 'cancelled';
          return dt != null && dt.isAfter(now) && !isRejected;
        }).toList();
        upcoming.sort(
            (a, b) => a['appointmentTime'].compareTo(b['appointmentTime']));
        upcomingAppointment = upcoming.isNotEmpty ? upcoming.first : null;

        // Reddedilen randevuları bildirimlere ekle
        notifications = appointments
            .where((a) {
              final status = a['status']?.toString().toLowerCase() ?? '';
              return status == 'reddedildi' || status == 'rejected';
            })
            .map((a) => {
                  'title': 'Randevu Reddedildi',
                  'message':
                      '${a['carPlate']} plakalı aracınız için ${a['carWashName'] ?? 'Self CarWash'} randevusu reddedildi.',
                  'date': a['appointmentTime'],
                })
            .toList();

        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  void _showBayiDetails(BuildContext context, Bayi bayi) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.local_car_wash,
                      color: Colors.blue.shade700, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bayi.name,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(bayi.city,
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildInfoCard(Icons.location_on, "Uzaklık", bayi.distance),
                const SizedBox(width: 16),
                _buildInfoCard(Icons.star, "Puan", bayi.rating.toString()),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (widget.userId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddAppointmentPage(
                          userId: widget.userId!,
                          bayiName: bayi.name,
                          bayiPrices: bayi.prices,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Lütfen önce giriş yapın")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text("Randevu Al",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue.shade700),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return '';
    final months = [
      "",
      "Ocak",
      "Şubat",
      "Mart",
      "Nisan",
      "Mayıs",
      "Haziran",
      "Temmuz",
      "Ağustos",
      "Eylül",
      "Ekim",
      "Kasım",
      "Aralık"
    ];
    return "${dt.day} ${months[dt.month]} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Bildirimler",
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
            if (notifications.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.notifications_off_outlined,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        "Bildirim yok",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.cancel_outlined,
                                color: Colors.red.shade700, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notif['title'] ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notif['message'] ?? '',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Üst kısım - Profil
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.wb_sunny,
                                    size: 24, color: Colors.amber),
                                const SizedBox(width: 8),
                                Text(
                                  "Merhaba ${widget.userName}",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  "Türkiye",
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                        PopupMenuButton<int>(
                          icon: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.notifications_outlined,
                                    color: Colors.blue.shade700, size: 26),
                              ),
                              if (notifications.isNotEmpty)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      notifications.length.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          offset: const Offset(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: Colors.white,
                          elevation: 8,
                          constraints: const BoxConstraints(
                            maxWidth: 300,
                            minWidth: 280,
                          ),
                          itemBuilder: (context) {
                            if (notifications.isEmpty) {
                              return [
                                PopupMenuItem<int>(
                                  enabled: false,
                                  child: SizedBox(
                                    height: 100,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.notifications_off_outlined,
                                              size: 36,
                                              color: Colors.grey.shade300),
                                          const SizedBox(height: 8),
                                          Text(
                                            "Bildirim yok",
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ];
                            }
                            return [
                              PopupMenuItem<int>(
                                enabled: false,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      const Text(
                                        "Bildirimler",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          "${notifications.length}",
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ...notifications.map((notif) =>
                                  PopupMenuItem<int>(
                                    enabled: false,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      margin: const EdgeInsets.only(bottom: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: Colors.red.shade100),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.cancel_outlined,
                                              color: Colors.red.shade600,
                                              size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  notif['title'] ?? '',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.red.shade700,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  notif['message'] ?? '',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade700,
                                                    fontSize: 11,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )),
                            ];
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Öne çıkan bayi kartı
                    Center(
                      child: GestureDetector(
                        onTap: () => _showBayiDetails(context, bayiler[3]),
                        child: Container(
                          height: 220,
                          width: MediaQuery.of(context).size.width * 0.75,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.35),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.2),
                                blurRadius: 30,
                                spreadRadius: -5,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  bayiler[3].imageAsset,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.blue.shade700,
                                      child: Center(
                                        child: Icon(Icons.local_car_wash,
                                            size: 80,
                                            color:
                                                Colors.white.withOpacity(0.3)),
                                      ),
                                    );
                                  },
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.7),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.3),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.star,
                                                color: Colors.amber, size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              bayiler[3].rating.toString(),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        bayiler[3].name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.directions_walk,
                                              color: Colors.white70, size: 16),
                                          const SizedBox(width: 4),
                                          Text(bayiler[3].distance,
                                              style: const TextStyle(
                                                  color: Colors.white70)),
                                          const SizedBox(width: 16),
                                          const Text("₺",
                                              style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 4),
                                          Text(
                                              "${bayiler[3].prices.values.first.toInt()} TL'den başlayan...",
                                              style: const TextStyle(
                                                  color: Colors.white70)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tüm Bayiler başlık
                    const Text(
                      "Tüm Bayiler",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 12),

                    // Yatay kayan bayi kartları
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: bayiler.length,
                        itemBuilder: (context, index) {
                          final bayi = bayiler[index];
                          return GestureDetector(
                            onTap: () => _showBayiDetails(context, bayi),
                            child: Container(
                              width: 165,
                              margin: EdgeInsets.only(right: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(18)),
                                    ),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                  top: Radius.circular(18)),
                                          child: Image.asset(
                                            bayi.imageAsset,
                                            width: double.infinity,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                width: double.infinity,
                                                height: 100,
                                                color: Colors.blue.shade100,
                                                child: Icon(
                                                    Icons.local_car_wash,
                                                    size: 40,
                                                    color:
                                                        Colors.blue.shade300),
                                              );
                                            },
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          left: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.star,
                                                    color: Colors.amber,
                                                    size: 12),
                                                const SizedBox(width: 2),
                                                Text(
                                                  bayi.rating.toString(),
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          bayi.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              letterSpacing: 0.2),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on,
                                                size: 12,
                                                color: Colors.grey.shade500),
                                            const SizedBox(width: 2),
                                            Text(
                                              bayi.distance,
                                              style: TextStyle(
                                                  color: Colors.grey.shade500,
                                                  fontSize: 11),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "${bayi.prices.values.first.toInt()} TL'den başlayan...",
                                          style: TextStyle(
                                              color: Colors.green.shade600,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Randevularım - sadece yaklaşan randevu varsa göster
                    if (upcomingAppointment != null) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Randevularım",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B)),
                          ),
                          Row(
                            children: [
                              _miniStatCard(
                                  activeAppointments, "Aktif", Colors.green),
                              const SizedBox(width: 8),
                              _miniStatCard(
                                  totalAppointments, "Toplam", Colors.blue),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
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
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.directions_car,
                                  color: Colors.blue.shade700, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    upcomingAppointment!['carWashName'] ??
                                        'Self CarWash',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    upcomingAppointment!['carPlate'] ?? '',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatDate(
                                      upcomingAppointment!['appointmentTime']),
                                  style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "Yaklaşan",
                                    style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _miniStatCard(int value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(value.toString(),
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _bayiBox(String label, Bayi bayi) {
    return GestureDetector(
      onTap: () => _showBayiDetails(context, bayi),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200, width: 2),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blue.shade700)),
        ),
      ),
    );
  }
}
