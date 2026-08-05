import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/cart_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isCheckingOut = false;

  final String baseUrl = kIsWeb 
      ? 'http://127.0.0.1:1000/api' 
      : 'http://192.168.18.65:1000/api';

  // --- DIALOG KONFIRMASI HAPUS SATU ITEM ---
  void _showDeleteConfirmation(BuildContext context, int index, String productName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Produk', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3E2723))),
        content: Text('Apakah Anda yakin ingin menghapus "$productName" dari keranjang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Provider.of<CartProvider>(context, listen: false).removeItem(index);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Produk berhasil dihapus dari keranjang')),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- PROSES CHECKOUT SEMUA ITEM ---
  Future<void> _processCheckout(BuildContext context, CartProvider cartProvider) async {
  if (cartProvider.items.isEmpty) return;

  setState(() => _isCheckingOut = true);

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    // Ubah list item keranjang menjadi format array JSON "items"
    final List<Map<String, dynamic>> itemsPayload = cartProvider.items.map((cartItem) {
      return {
        'product_id': cartItem.product.id,
        'jumlah': cartItem.jumlah,
        'ukuran': cartItem.ukuran,
        'material': cartItem.material,
        'motif_ukiran': cartItem.motif,
        'catatan': cartItem.catatan,
      };
    }).toList();

    // Kirim SEKALI REQUEST saja untuk seluruh keranjang
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'items': itemsPayload,
        'biaya_tambahan': 0,
        'jumlah_dp': 0, // Sesuaikan jika ada input DP
      }),
    );

    if (!context.mounted) return;

    setState(() => _isCheckingOut = false);

    if (response.statusCode == 201) {
      cartProvider.clearCart(); // Kosongkan keranjang setelah berhasil
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Checkout berhasil! Pesanan Anda telah dibuat.'),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context); 
    } else {
      final decoded = jsonDecode(response.body);
      final message = decoded['message'] ?? 'Gagal memproses checkout.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    setState(() => _isCheckingOut = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Kesalahan koneksi saat checkout: $e'), backgroundColor: Colors.red),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: const Text('Keranjang Belanja', style: TextStyle(color: Color(0xFF3E2723), fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF3E2723)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFEADFD8), height: 1),
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFEADFD8))),
                    child: const Icon(Icons.shopping_cart_outlined, size: 48, color: Color(0xFF9CA3AF)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Keranjang Anda masih kosong', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }

          final cartItemsList = cartProvider.items;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartItemsList.length,
                  itemBuilder: (context, index) {
                    final item = cartItemsList[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEADFD8)),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF5D4037).withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.namaProduct,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF3E2723)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ukuran: ${item.ukuran}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Rp ${(item.product.estimasiHarga * item.jumlah).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFFB45309)),
                                ),
                              ],
                            ),
                          ),
                          
                          // Tombol Tambah & Kurang Kuantitas
                          Row(
                            children: [
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.remove_circle_outline, size: 22, color: Color(0xFF9CA3AF)),
                                onPressed: () {
                                  if (item.jumlah > 1) {
                                    cartProvider.updateQuantity(index, item.jumlah - 1);
                                  } else {
                                    _showDeleteConfirmation(context, index, item.product.namaProduct);
                                  }
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  '${item.jumlah}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF3E2723)),
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.add_circle_outline, size: 22, color: Color(0xFF5D4037)),
                                onPressed: () {
                                  cartProvider.updateQuantity(index, item.jumlah + 1);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),

                          // Tombol Hapus Item
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            onPressed: () => _showDeleteConfirmation(context, index, item.product.namaProduct),
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(top: BorderSide(color: Color(0xFFEADFD8))),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF5D4037).withOpacity(0.05), offset: const Offset(0, -5), blurRadius: 15),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B7280), fontSize: 13)),
                          Text(
                            'Rp ${cartProvider.totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFFB45309)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5D4037),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _isCheckingOut ? null : () => _processCheckout(context, cartProvider),
                          child: _isCheckingOut
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : const Text('CHECKOUT SEKARANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}