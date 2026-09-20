import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'verify_otp_screen.dart';

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

  // Warna utama aplikasi
  static const Color primaryColor = Color(0xFF5D4037);
  static const Color darkColor = Color(0xFF3E2723);
  static const Color accentColor = Color(0xFFD7A86E);
  static const Color softBrown = Color(0xFFF7F1EC);
  static const Color borderColor = Color(0xFFE8DDD4);
  static const Color textSecondary = Color(0xFF78716C);

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

  // Fungsi helper untuk menampilkan SnackBar
  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isSuccess
            ? const Color(0xFF059669)
            : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'nama': _namaController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'password_confirmation': _confirmPasswordController.text,
      'no_hp': _noHpController.text.trim(),
      'alamat': _alamatController.text.trim(),
    };

    final authProvider = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    final success = await authProvider.register(data);

    if (success) {
      if (!mounted) return;

      // Registrasi berhasil, tetapi akun belum aktif
      // karena pengguna harus melakukan verifikasi email terlebih dahulu.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyOtpScreen(
            email: _emailController.text.trim(),
          ),
        ),
      );
    } else {
      if (!mounted) return;

      _showSnackBar(authProvider.errorMessage);
    }
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

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
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: darkColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF292524),
          ),
          cursorColor: primaryColor,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFFA8A29E),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Container(
              width: 48,
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: primaryColor,
                size: 20,
              ),
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFFCFAF8),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: borderColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: borderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: primaryColor,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.5,
              ),
            ),
            errorStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFFDC2626),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: darkColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isLoading =
        Provider.of<AuthProvider>(context).isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F6),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFFAF8F6),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: darkColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Buat Akun',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: darkColor,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              32,
            ),
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 520,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ==================================================
                  // HEADER BRAND
                  // ==================================================

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: softBrown,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: borderColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius:
                                BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons
                                .account_circle_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Selamat Datang di',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textSecondary,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Kriya Ukir',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight:
                                      FontWeight.w900,
                                  color: darkColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // TITLE
                  // ==================================================

                  const Text(
                    'Lengkapi Data Diri',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      color: darkColor,
                      letterSpacing: -0.6,
                    ),
                  ),

                  const SizedBox(height: 7),

                  const Text(
                    'Daftarkan diri Anda untuk mulai melakukan '
                    'pemesanan kriya ukir secara mudah.',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // STEP INDICATOR
                  // ==================================================

                  Row(
                    children: [
                      Container(
                        height: 5,
                        width: 48,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        height: 5,
                        width: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7DDD5),
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        '1 dari 2',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // FORM CARD
                  // ==================================================

                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: borderColor,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.05),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          // ==================================================
                          // DATA DIRI
                          // ==================================================

                          _buildSectionTitle(
                            title: 'Informasi Pribadi',
                            subtitle:
                                'Masukkan informasi dasar untuk akun Anda.',
                          ),

                          const SizedBox(height: 20),

                          // NAMA
                          _buildTextField(
                            controller: _namaController,
                            label: 'Nama Lengkap',
                            hint: 'Masukkan nama lengkap',
                            icon: Icons.person_outline_rounded,
                            validator: (val) {
                              if (val == null ||
                                  val.trim().isEmpty) {
                                return 'Nama wajib diisi';
                              }

                              if (val.length < 3) {
                                return 'Nama minimal 3 karakter';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          // EMAIL
                          _buildTextField(
                            controller: _emailController,
                            label: 'Alamat Email',
                            hint: 'contoh@email.com',
                            icon: Icons
                                .alternate_email_rounded,
                            keyboardType:
                                TextInputType.emailAddress,
                            validator: (val) {
                              if (val == null ||
                                  val.isEmpty) {
                                return 'Email wajib diisi';
                              }

                              final emailRegex = RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              );

                              if (!emailRegex
                                  .hasMatch(val)) {
                                return 'Format email tidak valid';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          // NO HP
                          _buildTextField(
                            controller: _noHpController,
                            label: 'Nomor WhatsApp',
                            hint: '081234567890',
                            icon: Icons
                                .phone_outlined,
                            keyboardType:
                                TextInputType.phone,
                            validator: (val) {
                              if (val != null &&
                                  val.isNotEmpty) {
                                final phoneRegex =
                                    RegExp(r'^[0-9]+$');

                                if (!phoneRegex
                                    .hasMatch(val)) {
                                  return 'Hanya boleh berisi angka';
                                }

                                if (val.length < 10) {
                                  return 'Nomor HP tidak valid';
                                }
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          // ALAMAT
                          _buildTextField(
                            controller: _alamatController,
                            label: 'Alamat Pengiriman',
                            hint:
                                'Jalan, RT/RW, Kota',
                            icon: Icons
                                .location_on_outlined,
                            maxLines: 3,
                          ),

                          const SizedBox(height: 26),

                          // DIVIDER
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(
                                  color: borderColor,
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: softBrown,
                                    borderRadius:
                                        BorderRadius.circular(
                                      20,
                                    ),
                                  ),
                                  child: const Text(
                                    'KEAMANAN AKUN',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight:
                                          FontWeight.w800,
                                      color: primaryColor,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(
                                  color: borderColor,
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // ==================================================
                          // PASSWORD
                          // ==================================================

                          _buildSectionTitle(
                            title: 'Buat Kata Sandi',
                            subtitle:
                                'Gunakan minimal 8 karakter untuk keamanan akun.',
                          ),

                          const SizedBox(height: 18),

                          // PASSWORD
                          _buildTextField(
                            controller:
                                _passwordController,
                            label: 'Kata Sandi',
                            hint: 'Masukkan kata sandi',
                            icon: Icons
                                .lock_outline_rounded,
                            obscureText:
                                _isObscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscurePassword
                                    ? Icons
                                        .visibility_off_outlined
                                    : Icons
                                        .visibility_outlined,
                                color:
                                    const Color(0xFF9CA3AF),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isObscurePassword =
                                      !_isObscurePassword;
                                });
                              },
                            ),
                            validator: (val) {
                              if (val == null ||
                                  val.isEmpty) {
                                return 'Password wajib diisi';
                              }

                              if (val.length < 8) {
                                return 'Password minimal 8 karakter';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          // KONFIRMASI PASSWORD
                          _buildTextField(
                            controller:
                                _confirmPasswordController,
                            label: 'Konfirmasi Kata Sandi',
                            hint:
                                'Masukkan ulang kata sandi',
                            icon: Icons
                                .lock_reset_rounded,
                            obscureText:
                                _isObscureConfirm,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscureConfirm
                                    ? Icons
                                        .visibility_off_outlined
                                    : Icons
                                        .visibility_outlined,
                                color:
                                    const Color(0xFF9CA3AF),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isObscureConfirm =
                                      !_isObscureConfirm;
                                });
                              },
                            ),
                            validator: (val) {
                              if (val == null ||
                                  val.isEmpty) {
                                return 'Konfirmasi password wajib diisi';
                              }

                              if (val !=
                                  _passwordController.text) {
                                return 'Password tidak cocok';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 22),

                          // ==================================================
                          // INFO VERIFIKASI
                          // ==================================================

                          Container(
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFAF3),
                              borderRadius:
                                  BorderRadius.circular(13),
                              border: Border.all(
                                color: const Color(0xFFF0DFC9),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFEFE1D1,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(
                                      9,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons
                                        .mark_email_read_outlined,
                                    size: 16,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Setelah mendaftar, kode OTP akan '
                                    'dikirim ke email Anda untuk '
                                    'memverifikasi akun.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          Color(0xFF6B5B50),
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ==================================================
                          // BUTTON DAFTAR
                          // ==================================================

                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed:
                                  isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor:
                                    primaryColor,
                                foregroundColor:
                                    Colors.white,
                                disabledBackgroundColor:
                                    const Color(0xFFE7E2DE),
                                disabledForegroundColor:
                                    const Color(0xFFA8A29E),
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    14,
                                  ),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 23,
                                      height: 23,
                                      child:
                                          CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .center,
                                      children: const [
                                        Text(
                                          'DAFTAR SEKARANG',
                                          style: TextStyle(
                                            fontWeight:
                                                FontWeight.w800,
                                            fontSize: 13,
                                            letterSpacing: 0.7,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons
                                              .arrow_forward_rounded,
                                          size: 19,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // FOOTER
                  // ==================================================

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 13,
                        color: Color(0xFFA8A29E),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Data Anda diproses dengan aman',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFA8A29E),
                          fontWeight: FontWeight.w500,
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
    );
  }
}