import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class PesananScreen extends StatefulWidget {
  const PesananScreen({Key? key}) : super(key: key);

  @override
  State<PesananScreen> createState() => _PesananScreenState();
}

class _PesananScreenState extends State<PesananScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  final String baseUrl = kIsWeb 
      ? 'http://127.0.0.1:1000/api' 
      : 'http://10.0.2.2:1000/api';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        setState(() {
          _orders = decodedData['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat riwayat pesanan'), backgroundColor: Color(0xFFEF4444)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan koneksi: $e'), backgroundColor: const Color(0xFFEF4444)),
      );
    }
  }

  // Fungsi helper untuk menentukan warna badge status pesanan (Tema Earth Tones)
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return const Color(0xFF059669); // Emerald 600
      case 'diproses':
        return const Color(0xFF2563EB); // Blue 600
      case 'dibatalkan':
        return const Color(0xFFEF4444); // Red 500
      default:
        return const Color(0xFFB45309); // Amber 700
    }
  }

  void _showOrderDetailModal(BuildContext context, Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _OrderDetailModalContent(
          orderId: order['id'],
          initialOrder: order,
          baseUrl: baseUrl,
          getStatusColor: _getStatusColor,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold dihapus, langsung mereturn Container agar menyatu dengan MainScreen
    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF5D4037)))
        : _orders.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFEADFD8)),
                      ),
                      child: const Icon(Icons.receipt_long_outlined, size: 48, color: Color(0xFF9CA3AF)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum ada pesanan aktif',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF3E2723)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pesanan custom atau katalog Anda akan muncul di sini.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                color: const Color(0xFF5D4037),
                onRefresh: _fetchOrders,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final productName = order['product']?['nama_product'] ?? order['nama_custom'] ?? 'Pesanan Custom';
                    final statusPesanan = order['status_pesanan'] ?? 'menunggu';
                    final estimasiBiaya = order['estimasi_biaya'] ?? 0;
                    final kodePesanan = order['kode_pesanan'] ?? '-';
                    final tanggal = order['tanggal_pesanan'] ?? '';

                    return GestureDetector(
                      onTap: () => _showOrderDetailModal(context, order),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFEADFD8)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5D4037).withOpacity(0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    kodePesanan,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      color: Color(0xFF5D4037),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(statusPesanan).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      statusPesanan.replaceAll('_', ' ').toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: _getStatusColor(statusPesanan),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: Divider(color: Color(0xFFEADFD8), height: 1),
                              ),
                              Text(
                                productName,
                                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Color(0xFF3E2723)),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Tanggal: $tanggal',
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    'Rp ${estimasiBiaya.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Ketuk untuk melihat detail & progres ➔',
                                    style: TextStyle(fontSize: 11, color: Colors.brown[700], fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
  }
}

// Widget Stateful terpisah untuk Modal Detail dengan Polling Real-time
class _OrderDetailModalContent extends StatefulWidget {
  final int orderId;
  final Map<String, dynamic> initialOrder;
  final String baseUrl;
  final Color Function(String) getStatusColor;

  const _OrderDetailModalContent({
    Key? key,
    required this.orderId,
    required this.initialOrder,
    required this.baseUrl,
    required this.getStatusColor,
  }) : super(key: key);

  @override
  State<_OrderDetailModalContent> createState() => _OrderDetailModalContentState();
}

class _OrderDetailModalContentState extends State<_OrderDetailModalContent> {
  late Map<String, dynamic> _orderData;
  bool _isLoadingDetail = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _orderData = widget.initialOrder;
    _fetchLatestOrderDetail();

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchLatestOrderDetail(isBackground: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLatestOrderDetail({bool isBackground = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('${widget.baseUrl}/orders/${widget.orderId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _orderData = decoded['data'] ?? widget.initialOrder;
            if (!isBackground) _isLoadingDetail = false;
          });
        }
      } else {
        if (!isBackground && mounted) setState(() => _isLoadingDetail = false);
      }
    } catch (e) {
      if (!isBackground && mounted) setState(() => _isLoadingDetail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productName = _orderData['product']?['nama_product'] ?? _orderData['nama_custom'] ?? 'Pesanan Custom';
    final statusPesanan = _orderData['status_pesanan'] ?? 'menunggu';
    final estimasiBiaya = _orderData['estimasi_biaya'] ?? 0;
    final estimasiWaktu = _orderData['estimasi_waktu'] ?? 'Menunggu konfirmasi';
    final kodePesanan = _orderData['kode_pesanan'] ?? '-';
    final tanggal = _orderData['tanggal_pesanan'] ?? '';
    final jumlah = _orderData['jumlah'] ?? 1;
    final catatan = _orderData['catatan'] ?? 'Tidak ada catatan khusus.';
    
    final spec = _orderData['specification'] ?? {};
    final statusHistory = _orderData['status_history'] ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detail Pesanan ($kodePesanan)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF3E2723)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFEADFD8), height: 1),
          Expanded(
            child: _isLoadingDetail && statusHistory.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF5D4037)))
                : ListView(
                    padding: const EdgeInsets.all(24),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDFBF7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEADFD8)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(productName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF3E2723)))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: widget.getStatusColor(statusPesanan).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    statusPesanan.replaceAll('_', ' ').toUpperCase(),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: widget.getStatusColor(statusPesanan)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildSpecRow('Jumlah Pesanan', '$jumlah Pcs'),
                            const Divider(height: 16, color: Color(0xFFEADFD8)),
                            _buildSpecRow('Tanggal Pesanan', tanggal),
                            const Divider(height: 16, color: Color(0xFFEADFD8)),
                            _buildSpecRow('Estimasi Waktu', estimasiWaktu, valueColor: const Color(0xFFB45309)),
                            const Divider(height: 16, color: Color(0xFFEADFD8)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Estimasi Biaya', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
                                Text(
                                  'Rp ${estimasiBiaya.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Spesifikasi Produk', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF3E2723))),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEADFD8)),
                        ),
                        child: Column(
                          children: [
                            _buildSpecRow('Ukuran', spec['ukuran'] ?? '-'),
                            const Divider(height: 20, color: Color(0xFFEADFD8)),
                            _buildSpecRow('Material / Bahan', spec['material'] ?? '-'),
                            const Divider(height: 20, color: Color(0xFFEADFD8)),
                            _buildSpecRow('Jenis / Motif Ukiran', spec['motif_ukiran'] ?? spec['motif'] ?? '-'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Catatan Tambahan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF3E2723))),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDFBF7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEADFD8)),
                        ),
                        child: Text(catatan, style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280), fontStyle: FontStyle.italic, height: 1.4)),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Riwayat Status Produksi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF3E2723))),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF5D4037)),
                            onPressed: () {
                              setState(() => _isLoadingDetail = true);
                              _fetchLatestOrderDetail();
                            },
                            tooltip: 'Perbarui Status',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      statusHistory.isEmpty
                          ? const Text('Belum ada riwayat progres status.', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: statusHistory.length,
                              itemBuilder: (context, idx) {
                                final history = statusHistory[idx];
                                final rawDate = history['created_at'] ?? history['tanggal_update'] ?? '';
                                String formattedDate = '-';
                                
                                if (rawDate.isNotEmpty) {
                                  try {
                                    DateTime parsedDate = DateTime.parse(rawDate).toLocal();
                                    formattedDate = "${parsedDate.day.toString().padLeft(2, '0')}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.year} "
                                        "${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}";
                                  } catch (e) {
                                    formattedDate = rawDate;
                                  }
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF5D4037),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          if (idx != statusHistory.length - 1)
                                            Container(
                                              width: 2,
                                              height: 45,
                                              color: const Color(0xFFEADFD8),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  (history['status'] ?? '').toString().replaceAll('_', ' ').toUpperCase(),
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3E2723)),
                                                ),
                                                Text(
                                                  formattedDate,
                                                  style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              history['keterangan'] ?? 'Tidak ada keterangan.',
                                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                      const SizedBox(height: 30),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: valueColor ?? const Color(0xFF3E2723))),
      ],
    );
  }
}