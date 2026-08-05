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

  // State untuk filter & pencarian
  String _selectedStatusFilter = 'Semua Status';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final String baseUrl = kIsWeb 
      ? 'http://127.0.0.1:1000/api' 
      : 'http://192.168.18.65:1000/api';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        final decoded = jsonDecode(response.body);
        setState(() {
          _orders = decoded['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        final decoded = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(decoded['message'] ?? 'Gagal memuat pesanan'), backgroundColor: const Color(0xFFEF4444)),
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

  String _getOrderCategoryLabel(Map<String, dynamic> order) {
    final statusPesanan = (order['status_pesanan'] ?? '').toString().toLowerCase();
    final latestStatus = order['latest_status'];
    final currentTahap = latestStatus != null ? (latestStatus['status'] ?? '').toString().toLowerCase() : '';

    if (statusPesanan == 'menunggu_konfirmasi') {
      return 'Menunggu Konfirmasi';
    } else if (statusPesanan == 'dibatalkan') {
      return 'Dibatalkan';
    } else if (statusPesanan == 'selesai') {
      return 'Selesai';
    } else if (statusPesanan == 'diproses') {
      switch (currentTahap) {
        case 'persiapan':
          return 'Tahap: Persiapan';
        case 'pengukiran':
          return 'Tahap: Pengukiran';
        case 'finishing':
          return 'Tahap: Finishing';
        default:
          return 'Sedang Diproses';
      }
    }
    return statusPesanan.replaceAll('_', ' ').toUpperCase();
  }

  void _showOrderDetailModal(BuildContext context, Map<String, dynamic> order) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _OrderDetailModalContent(
          orderId: order['id'],
          initialOrder: order,
          baseUrl: baseUrl,
          getStatusColor: _getStatusColor,
          getOrderCategoryLabel: _getOrderCategoryLabel,
        );
      },
    );

    if (result == true) {
      _fetchOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter & Pencarian Pesanan
    List<dynamic> filteredOrders = _orders.where((order) {
      final statusPesanan = (order['status_pesanan'] ?? '').toString().toLowerCase();
      
      // Filter berdasarkan Dropdown Status
      bool matchesStatus = true;
      if (_selectedStatusFilter != 'Semua Status') {
        if (_selectedStatusFilter.toLowerCase() == 'menunggu') {
          matchesStatus = statusPesanan == 'menunggu' || statusPesanan == 'menunggu_konfirmasi';
        } else {
          matchesStatus = statusPesanan == _selectedStatusFilter.toLowerCase();
        }
      }

      // Filter berdasarkan Pencarian (Nama Produk / Kode Pesanan)
      final items = order['order_items'] ?? order['items'] ?? [];
      String productName = '';
      if (items.isNotEmpty) {
        productName = items.map((i) => i['product']?['nama_product'] ?? 'Produk').join(', ');
      } else {
        productName = order['product']?['nama_product'] ?? order['nama_custom'] ?? 'Pesanan Custom';
      }
      final kodePesanan = (order['kode_pesanan'] ?? '').toString();

      bool matchesSearch = _searchQuery.isEmpty ||
          productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          kodePesanan.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesStatus && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF5D4037)))
          : Column(
              children: [
                // Bagian Filter Dropdown & Search Bar ala Gambar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      // Dropdown Filter Status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDFBF7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEADFD8)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatusFilter,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280)),
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF3E2723)),
                            items: <String>[
                              'Semua Status',
                              'Menunggu',
                              'Diproses',
                              'Selesai',
                              'Dibatalkan',
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedStatusFilter = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Kolom Pencarian
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Cari nama, produk, atau kode...',
                            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF9CA3AF)),
                            filled: true,
                            fillColor: const Color(0xFFFDFBF7),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFEADFD8)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFEADFD8)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF5D4037)),
                            ),
                          ),
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF3E2723)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFEADFD8)),

                // Daftar Pesanan
                Expanded(
                  child: filteredOrders.isEmpty
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
                                'Tidak ada pesanan ditemukan',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF3E2723)),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Coba ubah filter atau kata kunci pencarian Anda.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFF5D4037),
                          onRefresh: _fetchOrders,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = filteredOrders[index];
                              
                              final items = order['order_items'] ?? order['items'] ?? [];
                              String productName = '';
                              if (items.isNotEmpty) {
                                productName = items.map((i) => i['product']?['nama_product'] ?? 'Produk').join(', ');
                              } else {
                                productName = order['product']?['nama_product'] ?? order['nama_custom'] ?? 'Pesanan Custom';
                              }

                              final categoryLabel = _getOrderCategoryLabel(order);
                              final statusPesanan = order['status_pesanan'] ?? 'menunggu';
                              final estimasiBiaya = order['estimasi_biaya'] ?? 0;
                              final kodePesanan = order['kode_pesanan'] ?? '-';
                              final rawTanggal = order['tanggal_pesanan'] ?? '';
                              String tanggal = '-';
                              if (rawTanggal.isNotEmpty) {
                                try {
                                  DateTime parsedDate = DateTime.parse(rawTanggal).toLocal();
                                  tanggal = "${parsedDate.day.toString().padLeft(2, '0')}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.year} ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}";
                                } catch (e) {
                                  tanggal = rawTanggal;
                                }
                              }

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
                                            Expanded(
                                              child: Row(
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
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF5D4037).withOpacity(0.08),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        categoryLabel.toUpperCase(),
                                                        style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
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
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
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
                        ),
                ),
              ],
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
  final String Function(Map<String, dynamic>) getOrderCategoryLabel;

  const _OrderDetailModalContent({
    Key? key,
    required this.orderId,
    required this.initialOrder,
    required this.baseUrl,
    required this.getStatusColor,
    required this.getOrderCategoryLabel,
  }) : super(key: key);

  @override
  State<_OrderDetailModalContent> createState() => _OrderDetailModalContentState();
}

class _OrderDetailModalContentState extends State<_OrderDetailModalContent> {
  late Map<String, dynamic> _orderData;
  bool _isLoadingDetail = true;
  bool _isCancelling = false;
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

  Future<void> _cancelOrder() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3E2723))),
        content: const Text('Apakah Anda yakin ingin membatalkan pesanan ini? Tindakan ini tidak dapat dibatalkan.', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.put(
        Uri.parse('${widget.baseUrl}/orders/${widget.orderId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'status_pesanan': 'dibatalkan',
        }),
      );

      if (!mounted) return;
      setState(() => _isCancelling = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan berhasil dibatalkan'), backgroundColor: Color(0xFF059669)),
        );
        Navigator.pop(context, true); 
      } else {
        final decoded = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(decoded['message'] ?? 'Gagal membatalkan pesanan'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan koneksi: $e'), backgroundColor: const Color(0xFFEF4444)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusPesanan = _orderData['status_pesanan'] ?? 'menunggu';
    final estimasiBiaya = _orderData['estimasi_biaya'] ?? 0;
    final jumlahDp = _orderData['jumlah_dp'] ?? 0;
    final statusPembayaran = _orderData['status_pembayaran'] ?? 'belum_bayar';
    final estimasiWaktu = _orderData['estimasi_waktu'] ?? 'Menunggu konfirmasi';
    final kodePesanan = _orderData['kode_pesanan'] ?? '-';
    final categoryLabel = widget.getOrderCategoryLabel(_orderData);
    
    final rawTanggal = _orderData['tanggal_pesanan'] ?? '';
    String tanggal = '-';
    if (rawTanggal.isNotEmpty) {
      try {
        DateTime parsedDate = DateTime.parse(rawTanggal).toLocal();
        tanggal = "${parsedDate.day.toString().padLeft(2, '0')}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.year} ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}";
      } catch (e) {
        tanggal = rawTanggal;
      }
    }

    final catatan = _orderData['catatan'] ?? 'Tidak ada catatan khusus.';
    
    List<dynamic> orderItems = _orderData['order_items'] ?? _orderData['items'] ?? [];
    if (orderItems.isEmpty && (_orderData['product'] != null || _orderData['nama_custom'] != null)) {
      orderItems = [_orderData];
    }

    List<dynamic> statusHistory = List.from(_orderData['status_history'] ?? []);
    
    bool hasCancelledInHistory = statusHistory.any((h) => (h['status'] ?? '').toString().toLowerCase() == 'dibatalkan');
    if (statusPesanan.toLowerCase() == 'dibatalkan' && !hasCancelledInHistory) {
      statusHistory.insert(0, {
        'status': 'dibatalkan',
        'keterangan': 'Pesanan telah dibatalkan oleh pelanggan.',
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
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
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Detail Pesanan ($kodePesanan)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF3E2723)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5D4037).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          categoryLabel.toUpperCase(),
                          style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
                        ),
                      ),
                    ],
                  ),
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
                                const Text('Status Pesanan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF3E2723))),
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
                            _buildSpecRow('Kategori / Tahapan', categoryLabel.toUpperCase(), valueColor: const Color(0xFF5D4037)),
                            const Divider(height: 16, color: Color(0xFFEADFD8)),
                            _buildSpecRow('Tanggal & Waktu Pesanan', tanggal),
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
                            const Divider(height: 16, color: Color(0xFFEADFD8)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Jumlah DP (Uang Muka)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
                                Text(
                                  'Rp ${jumlahDp.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                                ),
                              ],
                            ),
                            const Divider(height: 16, color: Color(0xFFEADFD8)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Status Pembayaran', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusPembayaran == 'lunas' 
                                        ? const Color(0xFF059669).withOpacity(0.1) 
                                        : (statusPembayaran == 'dp_dibayar' ? const Color(0xFFB45309).withOpacity(0.1) : const Color(0xFF6B7280).withOpacity(0.1)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    statusPembayaran.replaceAll('_', ' ').toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10, 
                                      fontWeight: FontWeight.w800, 
                                      color: statusPembayaran == 'lunas' 
                                          ? const Color(0xFF059669) 
                                          : (statusPembayaran == 'dp_dibayar' ? const Color(0xFFB45309) : const Color(0xFF6B7280)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  orderId: widget.orderId,
                                  kodePesanan: kodePesanan,
                                  baseUrl: widget.baseUrl,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.white),
                          label: const Text('Diskusi & Chat dengan Owner', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5D4037),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),

                      if (statusPesanan.toLowerCase() == 'menunggu_konfirmasi') ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isCancelling ? null : _cancelOrder,
                            icon: _isCancelling 
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEF4444)))
                                : const Icon(Icons.cancel_outlined, size: 18, color: Color(0xFFEF4444)),
                            label: Text(
                              _isCancelling ? 'Memproses...' : 'Batalkan Pesanan', 
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFEF4444)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      const Text('Daftar Produk Pesanan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF3E2723))),
                      const SizedBox(height: 10),
                      ...orderItems.map((item) {
                        final productName = item['product']?['nama_product'] ?? item['nama_custom'] ?? 'Produk Custom';
                        final jumlah = item['jumlah'] ?? 1;
                        final ukuran = item['ukuran'] ?? item['specification']?['ukuran'] ?? '-';
                        final material = item['material'] ?? item['specification']?['material'] ?? '-';
                        final motif = item['motif_ukiran'] ?? item['motif'] ?? item['specification']?['motif_ukiran'] ?? '-';
                        
                        final rawSubtotal = item['subtotal'] ?? item['estimasi_biaya'] ?? 0;
                        final num subtotal = num.tryParse(rawSubtotal.toString()) ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEADFD8)),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF5D4037).withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      productName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF3E2723)),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF5D4037).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text('$jumlah Pcs', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10.0),
                                child: Divider(height: 1, color: Color(0xFFEADFD8)),
                              ),
                              _buildSpecRow('Ukuran', ukuran),
                              const SizedBox(height: 6),
                              _buildSpecRow('Material / Bahan', material),
                              const SizedBox(height: 6),
                              _buildSpecRow('Motif Ukiran', motif),
                              if (subtotal > 0) ...[
                                const SizedBox(height: 6),
                                _buildSpecRow(
                                  'Subtotal', 
                                  'Rp ${subtotal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                                  valueColor: const Color(0xFFB45309),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 16),
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
                      
                      const Text('Riwayat Status Produksi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF3E2723))),
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

                                final bool isCancelledHistory = (history['status'] ?? '').toString().toLowerCase() == 'dibatalkan';

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
                                            decoration: BoxDecoration(
                                              color: isCancelledHistory ? const Color(0xFFEF4444) : const Color(0xFF5D4037),
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
                                                  style: TextStyle(
                                                    fontSize: 12, 
                                                    fontWeight: FontWeight.bold, 
                                                    color: isCancelledHistory ? const Color(0xFFEF4444) : const Color(0xFF3E2723),
                                                  ),
                                                ),
                                                Text(
                                                  formattedDate,
                                                  style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              history['keterangan'] ?? (isCancelledHistory ? 'Pesanan telah dibatalkan oleh pelanggan.' : 'Tidak ada keterangan.'),
                                              style: TextStyle(
                                                fontSize: 11.5, 
                                                color: isCancelledHistory ? const Color(0xFFEF4444) : const Color(0xFF6B7280),
                                              ),
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

// ==========================================
// LAYAR CHAT FLUTTER (CHAT SCREEN)
// ==========================================
class ChatScreen extends StatefulWidget {
  final int orderId;
  final String kodePesanan;
  final String baseUrl;

  const ChatScreen({
    Key? key,
    required this.orderId,
    required this.kodePesanan,
    required this.baseUrl,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<dynamic> _messages = [];
  bool _isLoading = true;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchMessages();

    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _fetchMessages(isBackground: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages({bool isBackground = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('${widget.baseUrl}/orders/${widget.orderId}/chats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _messages = decoded['data'] ?? [];
            if (!isBackground) _isLoading = false;
          });
          if (!isBackground) _scrollToBottom();
        }
      } else {
        if (!isBackground && mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!isBackground && mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse('${widget.baseUrl}/orders/${widget.orderId}/chats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'message': text}),
      );

      if (response.statusCode == 201) {
        _fetchMessages(isBackground: true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim pesan'), backgroundColor: Color(0xFFEF4444)),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF3E2723)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chat Diskusi Owner', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF3E2723))),
            Text('Pesanan: ${widget.kodePesanan}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFEADFD8), height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF5D4037)))
                : _messages.isEmpty
                    ? const Center(child: Text('Belum ada pesan. Mulai diskusi sekarang!', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg['sender']?['id'] != 1;

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: isMe ? const Color(0xFF5D4037) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: isMe ? null : Border.all(color: const Color(0xFFEADFD8)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg['sender']?['name'] ?? 'User',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isMe ? Colors.white70 : const Color(0xFF5D4037),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    msg['message'] ?? '',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: isMe ? Colors.white : const Color(0xFF3E2723),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Tulis pesan...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                      filled: true,
                      fillColor: const Color(0xFFFDFBF7),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFEADFD8)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFEADFD8)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF5D4037)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF5D4037)),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFEADFD8).withOpacity(0.5),
                    padding: const EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}