import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // --- Variabel Keamanan Tambahan ---
  bool _isObscure = true;
  int _failedAttempts = 0;
  bool _isLocked = false;
  int _lockoutSeconds = 30;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startLockoutTimer() {
    setState(() {
      _isLocked = true;
      _lockoutSeconds = 30;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lockoutSeconds == 0) {
        setState(() {
          _isLocked = false;
          _failedAttempts = 0; // Reset percobaan
        });
        timer.cancel();
      } else {
        setState(() {
          _lockoutSeconds--;
        });
      }
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() || _isLocked) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text,
      _passwordController.text,
    );

    if (success) {
      if (!mounted) return;
      setState(() => _failedAttempts = 0);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
    } else {
      if (!mounted) return;
      
      setState(() {
        _failedAttempts++;
      });

      if (_failedAttempts >= 3) {
        _startLockoutTimer();
        _showSnackBar('Terlalu banyak percobaan. Coba lagi dalam 30 detik.');
      } else {
        _showSnackBar(authProvider.errorMessage);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFEF4444), // Red 500
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;

    return Scaffold(
      // Menggunakan warna latar global dari tema (Krem FDFBF7)
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24), // Sesuai rounded-2xl di web
                border: Border.all(color: const Color(0xFFEADFD8), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5D4037).withOpacity(0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Ikon Header (Mengikuti gaya SplashScreen)
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF5D4037), Color(0xFF3E2723)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5D4037).withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.chair_rounded, size: 36, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Teks Judul & Subjudul
                    const Text(
                      'Selamat Datang',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900, // Extra Bold
                        color: Color(0xFF3E2723),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Masuk ke portal pelanggan Kriya Ukir',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280), // Muted text
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // FIELD EMAIL
                    const Text(
                      'ALAMAT EMAIL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B7280),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      // Dekorasi (border, fill color) sudah di-handle oleh main.dart
                      // Kita hanya perlu menambahkan hint dan icon spesifik
                      decoration: const InputDecoration(
                        hintText: 'pelanggan@kriyaukir.com',
                        prefixIcon: Icon(Icons.email_outlined, size: 20, color: Color(0xFF9CA3AF)),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Email wajib diisi';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // FIELD PASSWORD
                    const Text(
                      'KATA SANDI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B7280),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _isObscure,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20, color: Color(0xFF9CA3AF)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: const Color(0xFF9CA3AF),
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _isObscure = !_isObscure;
                            });
                          },
                        ),
                      ),
                      validator: (val) => val!.isEmpty ? 'Password wajib diisi' : null,
                    ),
                    const SizedBox(height: 32),
                    
                    // TOMBOL LOGIN
                    SizedBox(
                      height: 52, // Sedikit lebih tinggi agar nyaman ditekan
                      child: ElevatedButton(
                        onPressed: (isLoading || _isLocked) ? null : _submit,
                        // style ElevatedButton sudah di-handle di main.dart
                        // Kecuali jika ada state spesifik (seperti disabled)
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: const Color(0xFFE5E7EB),
                          disabledForegroundColor: const Color(0xFF9CA3AF),
                        ),
                        child: isLoading 
                            ? const SizedBox(
                                width: 24, 
                                height: 24, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                              ) 
                            : Text(
                                _isLocked ? 'TUNGGU $_lockoutSeconds DETIK' : 'MASUK SEKARANG', 
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 13,
                                  letterSpacing: 1.0,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Tombol Register
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Belum punya akun? ',
                          style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: const Text(
                            'Daftar di sini',
                            style: TextStyle(
                              color: Color(0xFFB45309), // Amber 700
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}