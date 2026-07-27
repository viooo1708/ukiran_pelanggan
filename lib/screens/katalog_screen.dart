import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/product_provider.dart';
import '../models/product_model.dart';

class KatalogScreen extends StatefulWidget {
  const KatalogScreen({Key? key}) : super(key: key);

  @override
  State<KatalogScreen> createState() => _KatalogScreenState();
}

class _KatalogScreenState extends State<KatalogScreen> {
  String _searchQuery = '';

  // URL Base otomatis mendeteksi Web vs Android
  final String baseUrl = kIsWeb 
      ? 'http://127.0.0.1:1000/api' 
      : 'http://10.0.2.2:1000/api';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      Provider.of<ProductProvider>(context, listen: false).fetchProducts()
    );
  }

  String _getImageUrl(String? gambarPath) {
    if (gambarPath == null || gambarPath.isEmpty) return '';

    if (gambarPath.contains('storgge')) {
      gambarPath = gambarPath.replaceAll('storgge', 'storage');
    }

    if (gambarPath.startsWith('http')) {
      String correctedUrl = gambarPath;
      if (correctedUrl.contains(':1001')) {
        correctedUrl = correctedUrl.replaceAll(':1001', ':1000');
      }
      if (correctedUrl.contains('storgge')) {
        correctedUrl = correctedUrl.replaceAll('storgge', 'storage');
      }

      if (!kIsWeb && (correctedUrl.contains('127.0.0.1') || correctedUrl.contains('localhost'))) {
        return correctedUrl.replaceAll(RegExp(r'127\.0\.0\.1|localhost'), '10.0.2.2');
      }
      return correctedUrl;
    }

    final String host = kIsWeb ? 'http://127.0.0.1:1000' : 'http://10.0.2.2:1000';

    if (gambarPath.startsWith('storage/')) {
      return '$host/$gambarPath';
    } else if (gambarPath.startsWith('/storage/')) {
      return '$host$gambarPath';
    }

    return '$host/storage/$gambarPath';
  }

  // --- MODAL FORM PEMESANAN ---
  void _showOrderFormModal(BuildContext context, Product product) {
    int jumlah = 1;
    final TextEditingController catatanController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Konfirmasi Pesanan',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF3E2723)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.namaProduct,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Divider(color: Color(0xFFEADFD8), height: 1),
                      ),
                      
                      // Pengatur Jumlah Pesanan
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Jumlah Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3E2723))),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (jumlah > 1) setStateModal(() => jumlah--);
                                },
                                icon: const Icon(Icons.remove_circle_outline),
                                color: const Color(0xFF9CA3AF),
                              ),
                              SizedBox(
                                width: 24,
                                child: Text('$jumlah', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3E2723))),
                              ),
                              IconButton(
                                onPressed: () => setStateModal(() => jumlah++),
                                icon: const Icon(Icons.add_circle_outline),
                                color: const Color(0xFF5D4037),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Input Catatan
                      const Text(
                        'CATATAN KHUSUS (OPSIONAL)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280), letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: catatanController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Misal: Ubah sedikit ukuran atau warna finishing...',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Total Harga Estimasi
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDFBF7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEADFD8)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Estimasi Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF6B7280))),
                            Text(
                              'Rp ${(product.estimasiHarga * jumlah).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFFB45309)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tombol Kirim Pesanan
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  setStateModal(() => isSubmitting = true);
                                  try {
                                    final prefs = await SharedPreferences.getInstance();
                                    final token = prefs.getString('auth_token');

                                    final response = await http.post(
                                      Uri.parse('$baseUrl/orders'),
                                      headers: {
                                        'Authorization': 'Bearer $token',
                                        'Accept': 'application/json',
                                        'Content-Type': 'application/json',
                                      },
                                      body: jsonEncode({
                                        'product_id': product.id,
                                        'jumlah': jumlah,
                                        'ukuran': product.ukuran ?? '-',
                                        'material': product.bahan ?? '-',
                                        'motif_ukiran': product.motif ?? '-',
                                        'catatan': catatanController.text,
                                        'biaya_tambahan': 0,
                                      }),
                                    );

                                    if (!context.mounted) return;

                                    if (response.statusCode == 201) {
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Pesanan berhasil dibuat! Menunggu konfirmasi owner.', style: TextStyle(fontWeight: FontWeight.bold)),
                                          backgroundColor: const Color(0xFF059669),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      );
                                    } else {
                                      setStateModal(() => isSubmitting = false);
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membuat pesanan.'), backgroundColor: Colors.red));
                                    }
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    setStateModal(() => isSubmitting = false);
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kesalahan koneksi: $e'), backgroundColor: Colors.red));
                                  }
                                },
                          child: isSubmitting
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : const Text('KIRIM PESANAN SEKARANG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- MODAL DETAIL PRODUK ---
  void _showProductDetailModal(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(10)),
                  ),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFEADFD8)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: product.gambar != null
                                    ? Image.network(
                                        _getImageUrl(product.gambar),
                                        height: 280,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          height: 280, color: const Color(0xFFFDFBF7),
                                          child: const Icon(Icons.broken_image_outlined, size: 48, color: Color(0xFF9CA3AF)),
                                        ),
                                      )
                                    : Container(
                                        height: 280, color: const Color(0xFFFDFBF7),
                                        child: const Icon(Icons.image_outlined, size: 48, color: Color(0xFF9CA3AF)),
                                      ),
                              ),
                            ),
                            Positioned(
                              top: 12, right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB45309),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Kayu Pilihan',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          product.namaProduct,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF3E2723), height: 1.2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rp ${(product.estimasiHarga).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Divider(color: Color(0xFFEADFD8), height: 1),
                        ),
                        const Text('Spesifikasi Detail', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF3E2723))),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDFBF7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEADFD8)),
                          ),
                          child: Column(
                            children: [
                              _buildSpecRow('Jenis Ukiran', product.jenisUkiran ?? '-'),
                              const Divider(height: 20, color: Color(0xFFEADFD8)),
                              _buildSpecRow('Ukuran', product.ukuran ?? '-'),
                              const Divider(height: 20, color: Color(0xFFEADFD8)),
                              _buildSpecRow('Bahan Kayu', product.bahan ?? '-'),
                              const Divider(height: 20, color: Color(0xFFEADFD8)),
                              _buildSpecRow('Motif', product.motif ?? '-'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('Deskripsi Produk', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF3E2723))),
                        const SizedBox(height: 8),
                        Text(
                          product.deskripsi ?? 'Tidak ada deskripsi untuk produk ini.',
                          style: const TextStyle(color: Color(0xFF6B7280), height: 1.6, fontSize: 13),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: const Border(top: BorderSide(color: Color(0xFFEADFD8))),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF5D4037).withOpacity(0.04), offset: const Offset(0, -10), blurRadius: 20),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => _showOrderFormModal(context, product),
                          child: const Text('PESAN SEKARANG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          flex: 3,
          child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF3E2723))),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari produk ukiran impian...',
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 22),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFEADFD8)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFEADFD8)),
                ),
              ),
            ),
          ),
          
          // Grid Produk
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF5D4037)));
                }

                if (productProvider.errorMessage.isNotEmpty) {
                  return Center(child: Text(productProvider.errorMessage, style: const TextStyle(color: Colors.red)));
                }

                List<Product> filteredProducts = productProvider.products.where((product) {
                  return product.namaProduct.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFEADFD8))),
                          child: const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF9CA3AF)),
                        ),
                        const SizedBox(height: 16),
                        const Text('Produk tidak ditemukan', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72, // Sedikit disesuaikan agar lebih proporsional
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFEADFD8)),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF5D4037).withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _showProductDetailModal(context, product),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Area Gambar Clean (Mengambil proporsi flex lebih pas)
                              Expanded(
                                flex: 12,
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                                      child: product.gambar != null
                                          ? Image.network(
                                              _getImageUrl(product.gambar),
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                color: const Color(0xFFFDFBF7),
                                                child: const Icon(Icons.broken_image_outlined, color: Color(0xFF9CA3AF)),
                                              ),
                                            )
                                          : Container(
                                              color: const Color(0xFFFDFBF7),
                                              child: const Center(child: Icon(Icons.image_outlined, color: Color(0xFF9CA3AF))),
                                            ),
                                    ),
                                    Positioned(
                                      top: 10, left: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFDFBF7).withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFEADFD8), width: 0.5),
                                        ),
                                        child: const Text('Kriya Ukir', style: TextStyle(color: Color(0xFF3E2723), fontSize: 9, fontWeight: FontWeight.w800)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Area Teks Dirapatkan ke Atas dan Tepat di Atas Harga
                              Expanded(
                                flex: 8,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start, // Mengalir rapat dari atas ke bawah
                                    children: [
                                      Text(
                                        product.namaProduct,
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF3E2723), height: 1.2),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        product.bahan ?? 'Kayu Pilihan',
                                        style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Spacer(), // Mendorong harga agar pas menempel di bagian bawah card
                                      Text(
                                        'Rp ${(product.estimasiHarga).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                                        style: const TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.w900, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
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
  }
}