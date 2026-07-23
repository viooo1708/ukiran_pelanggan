import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';

class KatalogScreen extends StatefulWidget {
  const KatalogScreen({Key? key}) : super(key: key);

  @override
  State<KatalogScreen> createState() => _KatalogScreenState();
}

class _KatalogScreenState extends State<KatalogScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      Provider.of<ProductProvider>(context, listen: false).fetchProducts()
    );
  }

  // Modal Bottom Sheet Detail Produk yang Mewah & Minimalis
  void _showProductDetailModal(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 5),
                ],
              ),
              child: Column(
                children: [
                  // Handle Bar
                  const SizedBox(height: 12),
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      padding: const EdgeInsets.all(24),
                      children: [
                        // Gambar Produk Utama
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: product.gambar != null
                                  ? Image.network(
                                      product.gambar!,
                                      height: 260,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        height: 260,
                                        color: Colors.grey[100],
                                        child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                                      ),
                                    )
                                  : Container(
                                      height: 260,
                                      color: Colors.grey[100],
                                      child: const Icon(Icons.image, size: 60, color: Colors.grey),
                                    ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.brown[800],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Kayu Pilihan',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Nama Produk & Harga
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                product.namaProduct,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Rp ${product.estimasiHarga.toStringAsFixed(0)}',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown[700]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(thickness: 1, height: 1),
                        const SizedBox(height: 16),

                        // Spesifikasi Card
                        const Text('Spesifikasi Detail', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.brown[5]?.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.brown.withOpacity(0.1)),
                          ),
                          child: Column(
                            children: [
                              _buildSpecRow('Jenis Ukiran', product.jenisUkiran ?? '-'),
                              const Divider(height: 16, color: Colors.black12),
                              _buildSpecRow('Ukuran', product.ukuran ?? '-'),
                              const Divider(height: 16, color: Colors.black12),
                              _buildSpecRow('Bahan Kayu', product.bahan ?? '-'),
                              const Divider(height: 16, color: Colors.black12),
                              _buildSpecRow('Motif', product.motif ?? '-'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Deskripsi
                        const Text('Deskripsi Produk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 8),
                        Text(
                          product.deskripsi ?? 'Tidak ada deskripsi untuk produk ini.',
                          style: TextStyle(color: Colors.grey[600], height: 1.6, fontSize: 14),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),

                  // Bottom Action Button di Modal
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -4), blurRadius: 10),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown[800],
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Memproses pesanan untuk: ${product.namaProduct}'),
                              backgroundColor: Colors.brown[800],
                            ),
                          );
                        },
                        child: const Text(
                          'PESAN SEKARANG', 
                          style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.8)
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Katalog Kriya Ukir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5)),
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header Minimalis (Hanya Search Bar yang Bersih)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), offset: const Offset(0, 4), blurRadius: 10),
              ],
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari produk ukiran impian...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.brown[700]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Daftar Produk (Grid View)
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading) {
                  return Center(child: CircularProgressIndicator(color: Colors.brown[800]));
                }

                if (productProvider.errorMessage.isNotEmpty) {
                  return Center(child: Text(productProvider.errorMessage));
                }

                List<Product> filteredProducts = productProvider.products.where((product) {
                  return product.namaProduct.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 70, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text('Produk tidak ditemukan', style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.64, // Diperlemah rasionya agar card sedikit lebih tinggi dan lapang
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            spreadRadius: 0,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            _showProductDetailModal(context, product);
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Area Gambar Produk dengan Desain Modern
                              Expanded(
                                flex: 7,
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                      child: product.gambar != null
                                          ? Image.network(
                                              product.gambar!,
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                color: Colors.grey[100],
                                                child: const Icon(Icons.broken_image, color: Colors.grey),
                                              ),
                                            )
                                          : Container(
                                              color: Colors.grey[100],
                                              child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                            ),
                                    ),
                                    // Badge Kategori Kecil di Pojok Kiri Atas Gambar
                                    Positioned(
                                      top: 10,
                                      left: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.55),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Kriya Ukir',
                                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Area Informasi Produk & Harga
                              Expanded(
                                flex: 5,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.namaProduct,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold, 
                                              fontSize: 13.5,
                                              color: Colors.black87,
                                              height: 1.2,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            product.bahan ?? 'Kayu Pilihan',
                                            style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                      
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Rp ${product.estimasiHarga.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                color: Colors.brown[800], 
                                                fontWeight: FontWeight.bold, 
                                                fontSize: 13.5,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(7),
                                            decoration: BoxDecoration(
                                              color: Colors.brown[800],
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                                          ),
                                        ],
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