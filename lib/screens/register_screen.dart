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
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _noHpController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  // Fungsi helper untuk menampilkan SnackBar bergaya modern
  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isSuccess ? const Color(0xFF059669) : const Color(0xFFEF4444), // Emerald 600 atau Red 500
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
      
      // Hapus token agar user harus login ulang
      await authProvider.logout(); 

      if (!mounted) return;
      
      _showSnackBar('Registrasi berhasil! Silakan masuk dengan akun Anda.', isSuccess: true);
      Navigator.pop(context); // Kembali ke halaman Login
    } else {
      if (!mounted) return;
      _showSnackBar(authProvider.errorMessage);
    }
  }

  // Widget helper yang sudah disederhanakan karena mengandalkan Theme global
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B7280), // Muted Text
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          // Dekorasi border dll sudah otomatis dari main.dart
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
            suffixIcon: suffixIcon,
          ),
          validator: validator,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Sesuai tema (FDFBF7)
      appBar: AppBar(
        title: const Text('Daftar Akun', style: TextStyle(fontSize: 16)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        // Garis pemisah bawah AppBar yang halus
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFEADFD8), height: 1.0),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24), // Sesuai rounded-2xl
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Judul Form
                    const Text(
                      'Lengkapi Data Diri',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF3E2723),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Buat akun baru untuk mulai memesan kriya ukir',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // FIELD NAMA
                    _buildTextField(
                      controller: _namaController,
                      label: 'Nama Lengkap',
                      hint: 'Masukkan nama sesuai KTP',
                      icon: Icons.person_outline,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Nama wajib diisi';
                        if (val.length < 3) return 'Nama minimal 3 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // FIELD EMAIL
                    _buildTextField(
                      controller: _emailController,
                      label: 'Alamat Email',
                      hint: 'pelanggan@kriyaukir.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Email wajib diisi';
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(val)) return 'Format email tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // FIELD NO HP
                    _buildTextField(
                      controller: _noHpController,
                      label: 'Nomor WhatsApp (Opsional)',
                      hint: '081234567890',
                      icon: Icons.phone_outlined,
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
                    const SizedBox(height: 20),
                    
                    // FIELD ALAMAT
                    _buildTextField(
                      controller: _alamatController,
                      label: 'Alamat Pengiriman (Opsional)',
                      hint: 'Masukkan alamat lengkap (Jalan, RT/RW, Kota)',
                      icon: Icons.home_outlined,
                      maxLines: 2,
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Divider(color: Color(0xFFEADFD8), thickness: 1, height: 1),
                    ),
                    
                    // FIELD PASSWORD
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Kata Sandi Baru',
                      hint: '••••••••',
                      icon: Icons.lock_outline,
                      obscureText: _isObscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xFF9CA3AF),
                          size: 20,
                        ),
                        onPressed: () => setState(() => _isObscurePassword = !_isObscurePassword),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Password wajib diisi';
                        if (val.length < 8) return 'Password minimal 8 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // FIELD KONFIRMASI PASSWORD
                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: 'Konfirmasi Kata Sandi',
                      hint: '••••••••',
                      icon: Icons.lock_reset_outlined,
                      obscureText: _isObscureConfirm,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xFF9CA3AF),
                          size: 20,
                        ),
                        onPressed: () => setState(() => _isObscureConfirm = !_isObscureConfirm),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Konfirmasi password wajib diisi';
                        if (val != _passwordController.text) return 'Password tidak cocok';
                        return null;
                      },
                    ),
                    const SizedBox(height: 36),
                    
                    // TOMBOL DAFTAR
                    SizedBox(
                      height: 52, // Disamakan tingginya dengan LoginScreen
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
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
                            : const Text(
                                'DAFTAR SEKARANG', 
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 13,
                                  letterSpacing: 1.0,
                                ),
                              ),
                      ),
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