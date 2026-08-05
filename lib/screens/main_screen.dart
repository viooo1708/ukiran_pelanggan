import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../providers/cart_provider.dart';
import 'katalog_screen.dart';
import 'custom_screen.dart';
import 'pesanan_screen.dart';
import 'profil_screen.dart';
import 'cart_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  static _MainScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MainScreenState>();

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openNotificationsModal(BuildContext context) {
    final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
    notifProvider.fetchNotifications(); 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pemberitahuan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3e2723)),
                  ),
                  TextButton(
                    onPressed: () {
                      notifProvider.markAllAsRead();
                    },
                    child: const Text(
                      'Tandai dibaca',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFa16207)),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Expanded(
                child: Consumer<NotificationProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFF5d4037)),
                      );
                    }

                    if (provider.notifications.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Tidak ada pemberitahuan baru.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: provider.notifications.length,
                      itemBuilder: (context, index) {
                        final notif = provider.notifications[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: notif.isRead ? Colors.white : const Color(0xFFfaf8f5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFeadfd8).withOpacity(0.6)),
                          ),
                          child: InkWell(
                            onTap: () {
                              provider.markAsRead(notif.id);
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notif.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: notif.isRead ? Colors.grey[700] : const Color(0xFF3e2723),
                                        ),
                                      ),
                                    ),
                                    if (!notif.isRead)
                                      const Icon(Icons.circle, size: 8, color: Colors.red),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notif.message,
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const KatalogScreen(),
      const CustomScreen(),
      const PesananScreen(),
      const ProfilScreen(),
    ];

    final List<String> titles = [
      'Katalog Kriya Ukir',
      'Custom Ukiran',
      'Pesanan Saya',
      'Profil Pelanggan',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFfdfbf7),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white.withOpacity(0.85),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: const Color(0xFFeadfd8).withOpacity(0.6)),
            ),
            title: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5d4037).withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF3e2723).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Image.asset(
                        'assets/logo-ukir.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Adi Ukiran',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF3e2723)),
                    ),
                    Text(
                      titles[_currentIndex],
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFa16207)),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Tombol Notifikasi
              Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Consumer<NotificationProvider>(
                  builder: (context, notifProvider, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          onPressed: () => _openNotificationsModal(context),
                          icon: const Icon(Icons.notifications_outlined, color: Color(0xFF5d4037)),
                          splashRadius: 20,
                        ),
                        if (notifProvider.hasUnread)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              
              // Tombol Keranjang Belanja (Tepat di sebelah kanan notifikasi)
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CartScreen()),
                    );
                  },
                  icon: Consumer<CartProvider>(
                    builder: (context, cart, child) => Badge(
                      isLabelVisible: cart.itemCount > 0,
                      label: Text('${cart.itemCount}'),
                      child: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF5d4037)),
                    ),
                  ),
                  splashRadius: 20,
                ),
              ),
            ],
          ),
        ),
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF5d4037),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront),
              label: 'Katalog',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.brush),
              label: 'Custom',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'Pesanan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}