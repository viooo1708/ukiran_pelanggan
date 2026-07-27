import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({Key? key}) : super(key: key);

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _noHpController = TextEditingController();
  final _alamatController = TextEditingController();
  
  // Controller untuk Ganti Password
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isObscurePassword = true;
  bool _isObscureConfirm = true;
  bool _isLoading = true;
  bool _isSaving = false;

  // Variabel untuk menampung foto profil (URL dari server atau File baru yang dipilih)
  String? _fotoUrl;
  XFile? _selectedImageFile;

  final String baseUrl = kIsWeb 
      ? 'http://127.0.0.1:1000/api' 
      : 'http://10.0.2.2:1000/api';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _noHpController.dispose();
    _alamatController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final userData = result['data'];

        setState(() {
          _namaController.text = userData['nama'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _noHpController.text = userData['no_hp'] ?? '';
          _alamatController.text = userData['alamat'] ?? '';
          _fotoUrl = userData['foto']; // Mengambil URL foto dari database
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Fungsi untuk memilih gambar dari galeri/perangkat
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    
    if (image != null) {
      setState(() {
        _selectedImageFile = image;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('auth_token');

      // Karena ada upload file foto, kita gunakan http.MultipartRequest (Metode PUT disiasati dengan _method = PUT khas Laravel)
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/profile'));
      
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Menambahkan field teks ke multipart request
      request.fields['_method'] = 'PUT'; // Laravel mendeteksi ini sebagai request PUT
      request.fields['nama'] = _namaController.text;
      request.fields['no_hp'] = _noHpController.text;
      request.fields['alamat'] = _alamatController.text;

      if (_passwordController.text.isNotEmpty) {
        request.fields['password'] = _passwordController.text;
        request.fields['password_confirmation'] = _confirmPasswordController.text;
      }

      // Jika user memilih foto baru
      if (_selectedImageFile != null) {
        if (kIsWeb) {
          // Khusus Flutter Web membaca bytes
          Uint8List bytes = await _selectedImageFile!.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'foto',
              bytes,
              filename: _selectedImageFile!.name,
            ),
          );
        } else {
          // Untuk Android / iOS
          request.files.add(
            await http.MultipartFile.fromPath('foto', _selectedImageFile!.path),
          );
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          _fotoUrl = result['data']['foto']; // Perbarui URL foto terbaru dari server
          _selectedImageFile = null; // Reset pilihan file lokal
        });

        _passwordController.clear();
        _confirmPasswordController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil & Foto berhasil diperbarui!'), backgroundColor: Colors.green),
        );
      } else {
        final errorData = jsonDecode(response.body);
        String errorMsg = 'Gagal memperbarui profil.';
        if (errorData['errors'] != null) {
          final errors = errorData['errors'] as Map<String, dynamic>;
          errorMsg = errors.values.first[0];
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint("Error updating profile: $e");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
    bool obscureText = false,
    Widget? suffixIcon,
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
            color: Colors.grey,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          obscureText: obscureText,
          style: TextStyle(
            fontSize: 13, 
            fontWeight: FontWeight.w600, 
            color: readOnly ? Colors.grey[600] : const Color(0xFF3e2723),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? Colors.grey[100] : Colors.white.withOpacity(0.7),
            prefixIcon: Icon(icon, color: Colors.grey, size: 20),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFe5e7eb)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFe5e7eb)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF5d4037), width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfdfbf7),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF5d4037)))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFeadfd8).withOpacity(0.6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(28.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Avatar Header Profil dengan Tombol Ganti Foto
                          Center(
                            child: Stack(
                              children: [
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF5d4037), Color(0xFF3e2723)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF5d4037).withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: _selectedImageFile != null
                                        ? FutureBuilder<Uint8List>(
                                            future: _selectedImageFile!.readAsBytes(),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                return Image.memory(snapshot.data!, fit: BoxFit.cover);
                                              }
                                              return const Center(child: CircularProgressIndicator(color: Colors.white));
                                            },
                                          )
                                        : (_fotoUrl != null && _fotoUrl!.isNotEmpty
                                            ? Image.network(
                                                _fotoUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Center(
                                                  child: Text(
                                                    _namaController.text.isNotEmpty 
                                                        ? _namaController.text.substring(0, 1).toUpperCase() 
                                                        : 'P',
                                                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                                  ),
                                                ),
                                              )
                                            : Center(
                                                child: Text(
                                                  _namaController.text.isNotEmpty 
                                                      ? _namaController.text.substring(0, 1).toUpperCase() 
                                                      : 'P',
                                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                                ),
                                              )),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: InkWell(
                                    onTap: _pickImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFa16207),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Profil Pengguna',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF3e2723),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // FIELD NAMA
                          _buildTextField(
                            controller: _namaController,
                            label: 'Nama Lengkap',
                            icon: Icons.person_outline,
                            validator: (val) => val == null || val.isEmpty ? 'Nama wajib diisi' : null,
                          ),
                          const SizedBox(height: 16),

                          // FIELD EMAIL (Read-Only)
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email (Tidak dapat diubah)',
                            icon: Icons.email_outlined,
                            readOnly: true,
                          ),
                          const SizedBox(height: 16),

                          // FIELD NO HP
                          _buildTextField(
                            controller: _noHpController,
                            label: 'No HP',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),

                          // FIELD ALAMAT
                          _buildTextField(
                            controller: _alamatController,
                            label: 'Alamat',
                            icon: Icons.home_outlined,
                            maxLines: 2,
                          ),
                          
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 12),

                          // BAGIAN GANTI PASSWORD (OPSIONAL)
                          const Text(
                            'Ubah Password (Opsional)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3e2723),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Kosongkan jika tidak ingin mengganti password.',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),

                          // FIELD PASSWORD BARU
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password Baru',
                            icon: Icons.lock_outline,
                            obscureText: _isObscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _isObscurePassword = !_isObscurePassword),
                            ),
                            validator: (val) {
                              if (val != null && val.isNotEmpty && val.length < 8) {
                                return 'Password minimal 8 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // FIELD KONFIRMASI PASSWORD BARU
                          _buildTextField(
                            controller: _confirmPasswordController,
                            label: 'Konfirmasi Password Baru',
                            icon: Icons.lock_reset,
                            obscureText: _isObscureConfirm,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscureConfirm ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _isObscureConfirm = !_isObscureConfirm),
                            ),
                            validator: (val) {
                              if (_passwordController.text.isNotEmpty && val != _passwordController.text) {
                                return 'Konfirmasi password tidak cocok';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),

                          // TOMBOL SIMPAN PERUBAHAN
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _updateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5d4037),
                                disabledBackgroundColor: Colors.grey[300],
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text(
                                      'SIMPAN PERUBAHAN',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // TOMBOL KELUAR APLIKASI / LOGOUT
                          SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await Provider.of<AuthProvider>(context, listen: false).logout();
                                if (!mounted) return;
                                Navigator.pushAndRemoveUntil(
                                  context, 
                                  MaterialPageRoute(builder: (_) => const LoginScreen()), 
                                  (route) => false,
                                );
                              },
                              icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
                              label: const Text(
                                'KELUAR APLIKASI',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.redAccent, width: 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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