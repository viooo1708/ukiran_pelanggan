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
  bool _isObscure = true; // Untuk toggle password
  int _failedAttempts = 0; // Penghitung gagal login
  bool _isLocked = false; // Status kunci tombol
  int _lockoutSeconds = 30; // Durasi hukuman jika spam (30 detik)
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
    // Jangan jalankan jika form tidak valid atau sedang dihukum (locked)
    if (!_formKey.currentState!.validate() || _isLocked) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text,
      _passwordController.text,
    );

    if (success) {
      if (!mounted) return;
      setState(() => _failedAttempts = 0); // Reset jika sukses
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
    } else {
      if (!mounted) return;
      
      // Tambahkan penghitung kegagalan
      setState(() {
        _failedAttempts++;
      });

      if (_failedAttempts >= 3) {
        _startLockoutTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terlalu banyak percobaan. Coba lagi dalam 30 detik.'), 
            backgroundColor: Colors.red
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage), 
            backgroundColor: Colors.red
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.security, size: 80, color: Colors.brown),
                  const SizedBox(height: 24),
                  const Text('Masuk ke Kriya Ukir', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),
                  
                  // FIELD EMAIL
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email', 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Email wajib diisi';
                      // Validasi Regex Email Dasar
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(val)) return 'Format email tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // FIELD PASSWORD
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password', 
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      // Toggle mata (lihat password)
                      suffixIcon: IconButton(
                        icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _isObscure = !_isObscure;
                          });
                        },
                      ),
                    ),
                    obscureText: _isObscure,
                    validator: (val) => val!.isEmpty ? 'Password wajib diisi' : null,
                  ),
                  const SizedBox(height: 24),
                  
                  // TOMBOL LOGIN
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      // Matikan tombol jika loading atau sedang dilock (dihukum)
                      onPressed: (isLoading || _isLocked) ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: isLoading 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : Text(
                              _isLocked ? 'TUNGGU $_lockoutSeconds DETIK' : 'LOGIN', 
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: const Text('Belum punya akun? Daftar di sini'),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}