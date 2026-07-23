import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../models/attribute_model.dart'; // Sesuaikan path model Anda

class CustomScreen extends StatefulWidget {
  const CustomScreen({Key? key}) : super(key: key);

  @override
  State<CustomScreen> createState() => _CustomScreenState();
}

class _CustomScreenState extends State<CustomScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _namaPemesanController = TextEditingController();
  final TextEditingController _teleponController = TextEditingController();
  final TextEditingController _namaProdukController = TextEditingController();
  final TextEditingController _namaUkiranController = TextEditingController();
  final TextEditingController _ukuranController = TextEditingController();
  final TextEditingController _motifController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  
  File? _selectedImageFile;

  // Nilai terpilih untuk dropdown
  String? _selectedJenisUkiran;
  String? _selectedBahan;
  double _estimasiBudget = 1500000;

  // List data dari database API
  List<AttributeModel> _jenisUkiranList = [];
  List<AttributeModel> _bahanList = [];
  bool _isLoadingOptions = true;

  // URL Base API Backend Anda (Sesuaikan dengan IP/domain server Laravel Anda)
  final String baseUrl = 'http://10.0.2.2:8000/api'; // Contoh untuk Emulator Android

  @override
  void initState() {
    super.initState();
    _fetchAttributesFromApi();
  }

  // Fungsi Fetch Data dari AttributeController Laravel
  Future<void> _fetchAttributesFromApi() async {
    try {
      // Mengambil data jenis_ukiran dan bahan secara paralel atau terpisah
      final responseJenis = await http.get(Uri.parse('$baseUrl/attributes?type=jenis_ukiran'));
      final responseBahan = await http.get(Uri.parse('$baseUrl/attributes?type=bahan'));

      if (responseJenis.statusCode == 200 && responseBahan.statusCode == 200) {
        final decodedJenis = jsonDecode(responseJenis.body);
        final decodedBahan = jsonDecode(responseBahan.body);

        List<AttributeModel> tempJenis = (decodedJenis['data'] as List)
            .map((item) => AttributeModel.fromJson(item))
            .toList();

        List<AttributeModel> tempBahan = (decodedBahan['data'] as List)
            .map((item) => AttributeModel.fromJson(item))
            .toList();

        setState(() {
          _jenisUkiranList = tempJenis;
          _bahanList = tempBahan;

          // Set default value jika data dari database tersedia
          if (_jenisUkiranList.isNotEmpty) {
            _selectedJenisUkiran = _jenisUkiranList.first.value;
          }
          if (_bahanList.isNotEmpty) {
            _selectedBahan = _bahanList.first.value;
          }
          
          _isLoadingOptions = false;
        });
      } else {
        throw Exception('Gagal memuat data dari server');
      }
    } catch (e) {
      setState(() {
        _isLoadingOptions = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan koneksi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _namaPemesanController.dispose();
    _teleponController.dispose();
    _namaProdukController.dispose();
    _namaUkiranController.dispose();
    _ukuranController.dispose();
    _motifController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: $e')),
      );
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Data siap dikirim (termasuk _selectedJenisUkiran & _selectedBahan dari database)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pesanan custom untuk ${_namaProdukController.text} berhasil dikirim!'),
          backgroundColor: Colors.brown[800],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Pesan Ukiran Custom', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5)),
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoadingOptions 
          ? Center(child: CircularProgressIndicator(color: Colors.brown[800]))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Info Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.brown[5],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.brown.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.design_services_rounded, color: Colors.brown[800], size: 32),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Wujudkan Ukiran Impian Anda',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Opsi bahan dan jenis ukiran diambil langsung dari database.',
                                  style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Informasi Pemesan
                    const Text('Informasi Pemesan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 10),
                    _buildTextField(
                      controller: _namaPemesanController,
                      label: 'Nama Lengkap',
                      hint: 'Masukkan nama Anda',
                      icon: Icons.person_outline_rounded,
                      validator: (val) => val == null || val.isEmpty ? 'Nama tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _teleponController,
                      label: 'Nomor WhatsApp / Telepon',
                      hint: 'Contoh: 08123456789',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (val) => val == null || val.isEmpty ? 'Nomor telepon wajib diisi' : null,
                    ),
                    const SizedBox(height: 24),

                    // Spesifikasi Kriya Ukir
                    const Text('Spesifikasi Kriya Ukir', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 10),
                    
                    _buildTextField(
                      controller: _namaProdukController,
                      label: 'Nama Produk',
                      hint: 'Contoh: Meja Makan Mewah',
                      icon: Icons.shopping_bag_outlined,
                      validator: (val) => val == null || val.isEmpty ? 'Nama produk wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _namaUkiranController,
                      label: 'Nama Ukiran',
                      hint: 'Contoh: Ukiran Jepara Klasik',
                      icon: Icons.brush_outlined,
                      validator: (val) => val == null || val.isEmpty ? 'Nama ukiran wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),

                    // Dropdown Jenis Ukiran (Dari Database API)
                    _buildDropdownField(
                      label: 'Jenis Ukiran',
                      value: _selectedJenisUkiran,
                      items: _jenisUkiranList.map((e) => e.value).toList(),
                      onChanged: (val) => setState(() => _selectedJenisUkiran = val),
                      icon: Icons.category_outlined,
                    ),
                    const SizedBox(height: 12),

                    // Dropdown Bahan Kayu (Dari Database API)
                    _buildDropdownField(
                      label: 'Bahan Kayu',
                      value: _selectedBahan,
                      items: _bahanList.map((e) => e.value).toList(),
                      onChanged: (val) => setState(() => _selectedBahan = val),
                      icon: Icons.forest_outlined,
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _ukuranController,
                      label: 'Ukuran (P x L x T)',
                      hint: 'Contoh: 120cm x 60cm x 75cm',
                      icon: Icons.straighten_rounded,
                      validator: (val) => val == null || val.isEmpty ? 'Ukuran wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _motifController,
                      label: 'Motif',
                      hint: 'Contoh: Motif Daun & Bunga',
                      icon: Icons.pattern_rounded,
                      validator: (val) => val == null || val.isEmpty ? 'Motif wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // Upload Gambar
                    const Text('Contoh Gambar Ukiran (Opsional)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black87)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickImageFromGallery,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.brown.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            _selectedImageFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(_selectedImageFile!, width: 55, height: 55, fit: BoxFit.cover),
                                  )
                                : Container(
                                    width: 55,
                                    height: 55,
                                    decoration: BoxDecoration(color: Colors.brown[5], borderRadius: BorderRadius.circular(10)),
                                    child: Icon(Icons.add_photo_alternate_rounded, color: Colors.brown[800], size: 26),
                                  ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedImageFile == null ? 'Pilih Foto dari Galeri' : 'Foto Berhasil Dipilih',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedImageFile == null ? 'Ketuk untuk membuka galeri perangkat' : 'Ketuk untuk mengganti foto',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (_selectedImageFile != null)
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: Colors.red, size: 22),
                                onPressed: () => setState(() => _selectedImageFile = null),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Estimasi Budget Slider
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Estimasi Budget', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Colors.black87)),
                              Text(
                                'Rp ${_estimasiBudget.toStringAsFixed(0)}',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.brown[800]),
                              ),
                            ],
                          ),
                          Slider(
                            value: _estimasiBudget,
                            min: 500000,
                            max: 15000000,
                            divisions: 29,
                            activeColor: Colors.brown[800],
                            inactiveColor: Colors.brown[100],
                            label: 'Rp ${_estimasiBudget.toStringAsFixed(0)}',
                            onChanged: (val) => setState(() => _estimasiBudget = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Catatan
                    _buildTextField(
                      controller: _catatanController,
                      label: 'Catatan / Detail Model Khusus (Opsional)',
                      hint: 'Ceritakan detail ukiran atau referensi tambahan...',
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    // Tombol Submit
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown[800],
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _submitForm,
                        child: const Text(
                          'KIRIM PESANAN CUSTOM',
                          style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13.5),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          prefixIcon: Icon(icon, color: Colors.brown[700], size: 22),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value != null && items.contains(value) ? value : null,
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 13.5)))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13.5),
          prefixIcon: Icon(icon, color: Colors.brown[700], size: 22),
          border: InputBorder.none,
        ),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.brown[800]),
        dropdownColor: Colors.white,
      ),
    );
  }
}