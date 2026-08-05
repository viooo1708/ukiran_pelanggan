import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:ukiran_pelanggan/screens/main_screen.dart';
import '../models/attribute_model.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

class CustomScreen extends StatefulWidget {
  const CustomScreen({Key? key}) : super(key: key);

  @override
  State<CustomScreen> createState() => _CustomScreenState();
}

class _CustomScreenState extends State<CustomScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _jumlahController = TextEditingController(text: '1');
  final TextEditingController _catatanController = TextEditingController();
  
  final TextEditingController _customProductController = TextEditingController();
  final TextEditingController _customUkuranController = TextEditingController();
  final TextEditingController _customJenisUkiranController = TextEditingController();
  final TextEditingController _customBahanController = TextEditingController();
  final TextEditingController _customMotifController = TextEditingController();

  XFile? _selectedImageFile;

  dynamic _selectedProductId; 
  String? _selectedJenisUkiran; 
  String? _selectedBahan; 
  String? _selectedUkuran; 
  String? _selectedMotif; 

  List<AttributeModel> _jenisUkiranList = [];
  List<AttributeModel> _bahanList = [];
  List<AttributeModel> _ukuranList = []; 
  List<AttributeModel> _motifList = []; 
  List<dynamic> _productList = []; 
  
  bool _isLoadingOptions = true;
  bool _isSubmitting = false;

  final String baseUrl = kIsWeb 
      ? 'http://127.0.0.1:1000/api' 
      : 'http://192.168.18.65:1000/api'; 

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      final responseJenis = await http.get(Uri.parse('$baseUrl/attributes?type=jenis_ukiran'));
      final responseBahan = await http.get(Uri.parse('$baseUrl/attributes?type=bahan'));
      final responseUkuran = await http.get(Uri.parse('$baseUrl/attributes?type=ukuran')).catchError((_) => http.Response('', 404));
      final responseMotif = await http.get(Uri.parse('$baseUrl/attributes?type=motif')).catchError((_) => http.Response('', 404));
      final responseProduct = await http.get(Uri.parse('$baseUrl/products')); 

      if (responseJenis.statusCode == 200 && 
          responseBahan.statusCode == 200 && 
          responseProduct.statusCode == 200) {
        
        final decodedJenis = jsonDecode(responseJenis.body);
        final decodedBahan = jsonDecode(responseBahan.body);
        final decodedProduct = jsonDecode(responseProduct.body);

        List<AttributeModel> tempJenis = (decodedJenis['data'] as List)
            .map((item) => AttributeModel.fromJson(item))
            .toList();

        List<AttributeModel> tempBahan = (decodedBahan['data'] as List)
            .map((item) => AttributeModel.fromJson(item))
            .toList();

        List<dynamic> tempProduct = decodedProduct['data'] ?? [];

        List<AttributeModel> tempUkuran = [];
        if (responseUkuran.statusCode == 200) {
          final decodedUkuran = jsonDecode(responseUkuran.body);
          tempUkuran = (decodedUkuran['data'] as List).map((item) => AttributeModel.fromJson(item)).toList();
        }

        List<AttributeModel> tempMotif = [];
        if (responseMotif.statusCode == 200) {
          final decodedMotif = jsonDecode(responseMotif.body);
          tempMotif = (decodedMotif['data'] as List).map((item) => AttributeModel.fromJson(item)).toList();
        }

        setState(() {
          _jenisUkiranList = tempJenis;
          _bahanList = tempBahan;
          _ukuranList = tempUkuran;
          _motifList = tempMotif;
          _productList = tempProduct;

          if (_productList.isNotEmpty) {
            _selectedProductId = _productList.first['id'];
          } else {
            _selectedProductId = 'OTHER';
          }

          _selectedJenisUkiran = _jenisUkiranList.isNotEmpty ? _jenisUkiranList.first.value : 'OTHER';
          _selectedBahan = _bahanList.isNotEmpty ? _bahanList.first.value : 'OTHER';
          _selectedUkuran = _ukuranList.isNotEmpty ? _ukuranList.first.value : 'OTHER';
          _selectedMotif = _motifList.isNotEmpty ? _motifList.first.value : 'OTHER';
          
          _isLoadingOptions = false;
        });
      } else {
        throw Exception('Gagal memuat data dari server');
      }
    } catch (e) {
      setState(() => _isLoadingOptions = false);
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan koneksi: $e'), backgroundColor: const Color(0xFFEF4444)),
      );
    }
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    _catatanController.dispose();
    _customProductController.dispose();
    _customUkuranController.dispose();
    _customJenisUkiranController.dispose();
    _customBahanController.dispose();
    _customMotifController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _selectedImageFile = image);
      }
    } catch (e) {
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: $e'), backgroundColor: const Color(0xFFEF4444)),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProductId == 'OTHER' && _customProductController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan isi nama produk custom Anda!', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        setState(() => _isSubmitting = false);
        if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anda belum login. Silakan login terlebih dahulu!'), backgroundColor: Color(0xFFEF4444)),
        );
        return; 
      }

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/orders'));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      if (_selectedProductId == 'OTHER') {
        request.fields['nama_custom'] = _customProductController.text.trim();
      } else if (_selectedProductId != null) {
        request.fields['product_id'] = _selectedProductId.toString();
      }

      request.fields['jumlah'] = _jumlahController.text;
      request.fields['ukuran'] = _selectedUkuran == 'OTHER' ? _customUkuranController.text : (_selectedUkuran ?? '');
      request.fields['material'] = _selectedBahan == 'OTHER' ? _customBahanController.text : (_selectedBahan ?? '');
      request.fields['motif_ukiran'] = _selectedJenisUkiran == 'OTHER' ? _customJenisUkiranController.text : (_selectedJenisUkiran ?? '');
      request.fields['motif'] = _selectedMotif == 'OTHER' ? _customMotifController.text : (_selectedMotif ?? '');
      request.fields['catatan'] = _catatanController.text;

      if (_selectedImageFile != null) {
        if (kIsWeb) {
          final bytes = await _selectedImageFile!.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes('gambar', bytes, filename: _selectedImageFile!.name));
        } else {
          request.files.add(await http.MultipartFile.fromPath('gambar', _selectedImageFile!.path));
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      setState(() => _isSubmitting = false);
      if(!mounted) return;

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final kodePesanan = responseData['data']['kode_pesanan'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pesanan berhasil dibuat! Kode: $kodePesanan', style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        MainScreen.of(context)?.changeTab(2); // Pindah ke tab Pesanan (indeks 2)
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Gagal membuat pesanan';
        if (errorData['message'] != null) errorMessage = errorData['message'];
        if (errorData['errors'] != null) {
          final errors = errorData['errors'] as Map<String, dynamic>;
          errorMessage = errors.values.first[0]; 
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoadingOptions 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF5D4037)))
        : SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEADFD8), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF5D4037).withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5D4037).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.design_services_rounded, color: Color(0xFF5D4037), size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Wujudkan Ukiran Impian Anda',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF3E2723)),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Harga & estimasi waktu pengerjaan akan ditentukan langsung oleh owner setelah pesanan dikirim.',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280), height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 1. PILIH PRODUK REFERENSI / LAINNYA
                  const Text('PRODUK REFERENSI / DASAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEADFD8)),
                    ),
                    child: DropdownButtonFormField<dynamic>(
                      value: _selectedProductId,
                      items: [
                        ..._productList.map<DropdownMenuItem<dynamic>>((prod) {
                          return DropdownMenuItem<dynamic>(
                            value: prod['id'],
                            child: Text(prod['nama_product'] ?? 'Produk', style: const TextStyle(fontSize: 13, color: Color(0xFF3E2723), fontWeight: FontWeight.w600)),
                          );
                        }).toList(),
                        const DropdownMenuItem<dynamic>(
                          value: 'OTHER',
                          child: Text('Lainnya (Isi Sendiri)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                        ),
                      ],
                      onChanged: (val) => setState(() => _selectedProductId = val),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        prefixIcon: Icon(Icons.shopping_bag_outlined, color: Color(0xFF9CA3AF), size: 20),
                      ),
                      icon: const Padding(
                        padding: EdgeInsets.only(right: 12.0),
                        child: Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9CA3AF)),
                      ),
                      dropdownColor: Colors.white,
                    ),
                  ),
                  
                  if (_selectedProductId == 'OTHER') ...[
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _customProductController,
                      label: 'NAMA PRODUK CUSTOM ANDA',
                      hint: 'Contoh: Kursi Goyang Raja Ukir',
                      icon: Icons.edit_note_rounded,
                      validator: (val) => _selectedProductId == 'OTHER' && (val == null || val.isEmpty) ? 'Nama produk wajib diisi' : null,
                    ),
                  ],
                  const SizedBox(height: 24),

                  // SPESIFIKASI KRIYA UKIR
                  const Text('SPESIFIKASI KRIYA UKIR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8)),
                  const SizedBox(height: 12),
                  
                  _buildCustomDropdownWithOther(
                    label: 'Jenis Ukiran',
                    value: _selectedJenisUkiran,
                    items: _jenisUkiranList.map((e) => e.value).toList(),
                    onChanged: (val) => setState(() => _selectedJenisUkiran = val),
                    icon: Icons.category_outlined,
                    customController: _customJenisUkiranController,
                    customHint: 'Contoh: Ukiran Klasik Modern',
                  ),
                  const SizedBox(height: 12),

                  _buildCustomDropdownWithOther(
                    label: 'Bahan / Material Kayu',
                    value: _selectedBahan,
                    items: _bahanList.map((e) => e.value).toList(),
                    onChanged: (val) => setState(() => _selectedBahan = val),
                    icon: Icons.forest_outlined,
                    customController: _customBahanController,
                    customHint: 'Contoh: Kayu Mahoni Pilihan',
                  ),
                  const SizedBox(height: 12),

                  _buildCustomDropdownWithOther(
                    label: 'Ukuran (P x L x T)',
                    value: _selectedUkuran,
                    items: _ukuranList.isNotEmpty ? _ukuranList.map((e) => e.value).toList() : ['120cm x 60cm x 75cm', '180cm x 200cm'],
                    onChanged: (val) => setState(() => _selectedUkuran = val),
                    icon: Icons.straighten_rounded,
                    customController: _customUkuranController,
                    customHint: 'Contoh: 150cm x 70cm x 80cm',
                  ),
                  const SizedBox(height: 12),

                  _buildCustomDropdownWithOther(
                    label: 'Motif Ukiran',
                    value: _selectedMotif,
                    items: _motifList.isNotEmpty ? _motifList.map((e) => e.value).toList() : ['Lung-lungan', 'Geometris', 'Floral'],
                    onChanged: (val) => setState(() => _selectedMotif = val),
                    icon: Icons.pattern_rounded,
                    customController: _customMotifController,
                    customHint: 'Contoh: Motif Naga & Mega Mendung',
                  ),
                  const SizedBox(height: 12),

                  _buildTextField(
                    controller: _jumlahController,
                    label: 'JUMLAH PESANAN',
                    hint: '1',
                    icon: Icons.format_list_numbered_rounded,
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Jumlah wajib diisi';
                      if (int.tryParse(val) == null || int.parse(val) < 1) return 'Minimal jumlah adalah 1';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // UPLOAD GAMBAR
                  const Text('CONTOH GAMBARAN PRODUK (OPSIONAL)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickImageFromGallery,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEADFD8)),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF5D4037).withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          _selectedImageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: kIsWeb 
                                      ? Image.network(_selectedImageFile!.path, width: 50, height: 50, fit: BoxFit.cover)
                                      : Image.file(File(_selectedImageFile!.path), width: 50, height: 50, fit: BoxFit.cover),
                                )
                              : Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(color: const Color(0xFFFDFBF7), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEADFD8))),
                                  child: const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF5D4037), size: 22),
                                ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedImageFile == null ? 'Pilih Foto dari Galeri' : 'Foto Berhasil Dipilih',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3E2723)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedImageFile == null ? 'Ketuk untuk membuka galeri perangkat' : 'Ketuk untuk mengganti foto referensi',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (_selectedImageFile != null)
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 20),
                              onPressed: () => setState(() => _selectedImageFile = null),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // CATATAN
                  _buildTextField(
                    controller: _catatanController,
                    label: 'CATATAN / DETAIL MODEL KHUSUS (OPSIONAL)',
                    hint: 'Ceritakan detail ukiran atau referensi tambahan...',
                    icon: Icons.notes_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  // TOMBOL SUBMIT
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              'KIRIM PESANAN CUSTOM',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildCustomDropdownWithOther({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    required IconData icon,
    required TextEditingController customController,
    required String customHint,
  }) {
    List<String> dropdownItems = [...items, 'OTHER'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEADFD8)),
          ),
          child: DropdownButtonFormField<String>(
            value: value != null && dropdownItems.contains(value) ? value : (dropdownItems.isNotEmpty ? dropdownItems.first : null),
            items: dropdownItems.map((item) {
              bool isOther = item == 'OTHER';
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  isOther ? 'Lainnya (Isi Sendiri)' : item,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isOther ? FontWeight.bold : FontWeight.w600,
                    color: isOther ? const Color(0xFFB45309) : const Color(0xFF3E2723),
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
            ),
            icon: const Padding(
              padding: EdgeInsets.only(right: 12.0),
              child: Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9CA3AF)),
            ),
            dropdownColor: Colors.white,
          ),
        ),
        if (value == 'OTHER') ...[
          const SizedBox(height: 12),
          _buildTextField(
            controller: customController,
            label: 'MASUKKAN ${label.toUpperCase()} CUSTOM',
            hint: customHint,
            icon: Icons.edit_note_rounded,
            validator: (val) => value == 'OTHER' && (val == null || val.isEmpty) ? '$label wajib diisi' : null,
          ),
        ],
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
          ),
        ),
      ],
    );
  }
}