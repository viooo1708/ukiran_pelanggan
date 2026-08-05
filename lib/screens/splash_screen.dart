import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// Tambahkan SingleTickerProviderStateMixin untuk mengendalikan animasi
class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Konfigurasi durasi animasi (1.2 detik untuk kesan halus)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Animasi memudar dari transparan ke solid
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Animasi membesar sedikit dengan efek memantul di akhir (easeOutBack)
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    // Mulai animasi
    _animationController.forward();

    _checkAuth();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _checkAuth() async {
    // Waktu tunggu disesuaikan agar animasi punya waktu untuk selesai
    await Future.delayed(const Duration(seconds: 3)); 
    final token = await ApiService().getToken();
    
    if (!mounted) return;
    
    if (token != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7), // Sesuai background web
      body: SafeArea(
        child: Center(
          // Membungkus konten dengan widget Animasi
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Kotak Logo Kustom dengan Bayangan Lembut
                  Container(
                    width: 85,
                    height: 85,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5D4037).withOpacity(0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFF3E2723).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(23),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset(
                          'assets/logo-ukir.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // Nama Aplikasi
                  const Text(
                    'ADI UKIRAN', 
                    style: TextStyle(
                      color: Color(0xFF3E2723), 
                      fontSize: 26, 
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Subjudul Sistem Pelanggan Eksklusif
                  Text(
                    'Sistem Pelanggan Eksklusif'.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFB45309), // Amber 700 yang lebih kontras
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Indikator Loading Mini
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Color(0xFF5D4037),
                      strokeWidth: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}