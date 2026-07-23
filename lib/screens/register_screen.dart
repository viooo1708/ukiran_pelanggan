import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _noHpController = TextEditingController();
  final _alamatController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Status untuk toggle visibilitas password
  bool _isObscurePassword = true;
  bool _isObscureConfirm = true;

  @override
  void dispose() {
    // Membersihkan controller untuk mencegah memory leak
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _noHpController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'nama': _namaController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'password_confirmation': _confirmPasswordController.text,
      'no_hp': _noHpController.text,
      'alamat': _alamatController.text,
    };

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(data);

    if (success) {
      if (!mounted) return;
      
      // Karena endpoint register Laravel Anda langsung mengembalikan token,
      // kita hapus token tersebut agar user benar-benar harus login ulang.
      await authProvider.logout(); 

      if (!mounted) return;
      
      // Tampilkan pesan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi berhasil! Silakan login dengan akun Anda.'),
          backgroundColor: Colors.green,
        ),
      );

      // Kembali ke halaman Login (karena sebelumnya kita push dari LoginScreen)
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Akun'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lengkapi Data Diri',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown),
                ),
                const SizedBox(height: 24),
                
                // FIELD NAMA
                TextFormField(
                  controller: _namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap', 
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Nama wajib diisi';
                    if (val.length < 3) return 'Nama minimal 3 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
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
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(val)) return 'Format email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // FIELD NO HP
                TextFormField(
                  controller: _noHpController,
                  decoration: const InputDecoration(
                    labelText: 'No HP (Opsional)', 
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (val) {
                    if (val != null && val.isNotEmpty) {
                      final phoneRegex = RegExp(r'^[0-9]+$');
                      if (!phoneRegex.hasMatch(val)) return 'Hanya boleh berisi angka';
                      if (val.length < 10) return 'Nomor HP tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // FIELD ALAMAT
                TextFormField(
                  controller: _alamatController,
                  decoration: const InputDecoration(
                    labelText: 'Alamat (Opsional)', 
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                const Divider(),
                const SizedBox(height: 16),
                
                // FIELD PASSWORD
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password', 
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_isObscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _isObscurePassword = !_isObscurePassword),
                    ),
                  ),
                  obscureText: _isObscurePassword,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Password wajib diisi';
                    if (val.length < 8) return 'Password minimal 8 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // FIELD KONFIRMASI PASSWORD
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password', 
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_isObscureConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _isObscureConfirm = !_isObscureConfirm),
                    ),
                  ),
                  obscureText: _isObscureConfirm,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Konfirmasi password wajib diisi';
                    if (val != _passwordController.text) return 'Password tidak cocok';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                
                // TOMBOL DAFTAR
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text('DAFTAR SEKARANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}