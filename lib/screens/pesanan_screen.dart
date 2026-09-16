import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../services/api_service.dart';

class PesananScreen extends StatefulWidget {
  const PesananScreen({Key? key}) : super(key: key);

  @override
  State<PesananScreen> createState() => _PesananScreenState();
}

class _PesananScreenState extends State<PesananScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  String _selectedStatusFilter = 'Semua Status';
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();
  final String baseUrl = ApiService.baseUrl;

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

  // ============================================================
  // FORMAT ANGKA
  // ============================================================

  num _parseNumber(dynamic value) {
    if (value == null) return 0;
    if (value is num) {
      return value;
    }
    return num.tryParse(value.toString()) ?? 0;
  }

  String _formatRupiah(dynamic value) {
    final number = _parseNumber(value);
    return number.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  bool _parseBool(dynamic value) {
    return value == true ||
        value == 1 ||
        value == '1' ||
        value.toString().toLowerCase() == 'true';
  }

  // ============================================================
  // FETCH PESANAN
  // ============================================================

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
          SnackBar(
            content: Text(decoded['message'] ?? 'Gagal memuat pesanan'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan koneksi: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  // ============================================================
  // STATUS PESANAN
  // ============================================================

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return const Color(0xFF059669);
      case 'diproses':
        return const Color(0xFF2563EB);
      case 'dibatalkan':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFB45309);
    }
  }

  String _getOrderCategoryLabel(Map<String, dynamic> order) {
    final statusPesanan = (order['status_pesanan'] ?? '').toString().toLowerCase();
    final latestStatus = order['latest_status'];

    final currentTahap = latestStatus != null
        ? (latestStatus['status'] ?? '').toString().toLowerCase()
        : '';

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

  // ============================================================
  // DETAIL PESANAN
  // ============================================================

  void _showOrderDetailModal(BuildContext context, Map<String, dynamic> order) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _OrderDetailModalContent(
          orderId: _parseNumber(order['id']).toInt(),
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredOrders = _orders.where((order) {
      final statusPesanan = (order['status_pesanan'] ?? '').toString().toLowerCase();
      bool matchesStatus = true;

      if (_selectedStatusFilter != 'Semua Status') {
        if (_selectedStatusFilter.toLowerCase() == 'menunggu') {
          matchesStatus = statusPesanan == 'menunggu' || statusPesanan == 'menunggu_konfirmasi';
        } else {
          matchesStatus = statusPesanan == _selectedStatusFilter.toLowerCase();
        }
      }

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
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF5D4037),
              ),
            )
          : Column(
              children: [
                // ====================================================
                // FILTER & SEARCH
                // ====================================================
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [
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
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF6B7280),
                            ),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3E2723),
                            ),
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
                              setState(() => _selectedStatusFilter = newValue!);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Cari nama, produk, atau kode...',
                            hintStyle: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 18,
                              color: Color(0xFF9CA3AF),
                            ),
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
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF3E2723),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(
                  height: 1,
                  color: Color(0xFFEADFD8),
                ),

                // ====================================================
                // LIST PESANAN
                // ====================================================
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
                                child: const Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Tidak ada pesanan ditemukan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3E2723),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Coba ubah filter atau kata kunci pencarian Anda.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
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
                              final statusPesanan = (order['status_pesanan'] ?? 'menunggu').toString();

                              final estimasiBiaya = _parseNumber(order['estimasi_biaya']);
                              final kodePesanan = order['kode_pesanan'] ?? '-';
                              final rawTanggal = (order['tanggal_pesanan'] ?? '').toString();

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
                                                    kodePesanan.toString(),
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
                                                        style: const TextStyle(
                                                          fontSize: 8.5,
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFF5D4037),
                                                        ),
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
                                          padding: EdgeInsets.symmetric(vertical: 12),
                                          child: Divider(
                                            color: Color(0xFFEADFD8),
                                            height: 1,
                                          ),
                                        ),
                                        Text(
                                          productName,
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF3E2723),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Tanggal: $tanggal',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                color: Color(0xFF6B7280),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              'Rp ${_formatRupiah(estimasiBiaya)}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFFB45309),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Ketuk untuk melihat detail & progres ➔',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.brown[700],
                                                fontWeight: FontWeight.w700,
                                              ),
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

// ============================================================================
// WIDGET MODAL DETAIL PESANAN
// ============================================================================

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
  bool _isActionLoading = false;
  bool _isLaunchingWhatsApp = false;

  final ImagePicker _imagePicker = ImagePicker();

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _orderData = widget.initialOrder;
    _fetchLatestOrderDetail();

    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        _fetchLatestOrderDetail(isBackground: true);
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ============================================================
  // FORMAT ANGKA
  // ============================================================

  num _parseNumber(dynamic value) {
    if (value == null) return 0;
    if (value is num) {
      return value;
    }
    return num.tryParse(value.toString()) ?? 0;
  }

  String _formatRupiah(dynamic value) {
    final number = _parseNumber(value);
    return number.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  bool _parseBool(dynamic value) {
    return value == true ||
        value == 1 ||
        value == '1' ||
        value.toString().toLowerCase() == 'true';
  }

  // ============================================================
  // STATUS PEMBAYARAN
  // ============================================================

  String _getPaymentStatusLabel(String status) {
    switch (status) {
      case 'menunggu_konfirmasi_biaya':
        return 'Menunggu Persetujuan Biaya';
      case 'menunggu_pembayaran_dp':
        return 'Menunggu Pembayaran DP';
      case 'menunggu_verifikasi_dp':
        return 'Menunggu Verifikasi DP';
      case 'dp_dibayar':
        return 'DP Sudah Dibayar';
      case 'menunggu_verifikasi_lunas':
        return 'Menunggu Verifikasi Pelunasan';
      case 'lunas':
        return 'Lunas';
      case 'belum_bayar':
        return 'Belum Bayar';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'lunas':
        return const Color(0xFF059669);
      case 'dp_dibayar':
        return const Color(0xFFB45309);
      case 'menunggu_verifikasi_dp':
      case 'menunggu_verifikasi_lunas':
        return const Color(0xFF2563EB);
      case 'menunggu_pembayaran_dp':
        return const Color(0xFFB45309);
      case 'menunggu_konfirmasi_biaya':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF6B7280);
    }
  }

  // ============================================================
  // FETCH DETAIL TERBARU
  // ============================================================

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
            if (!isBackground) {
              _isLoadingDetail = false;
            }
          });
        }
      } else {
        if (!isBackground && mounted) {
          setState(() => _isLoadingDetail = false);
        }
      }
    } catch (e) {
      if (!isBackground && mounted) {
        setState(() => _isLoadingDetail = false);
      }
    }
  }

  // ============================================================
  // AKSI 1: PELANGGAN MENYETUJUI ESTIMASI BIAYA
  // ============================================================

  Future<void> _confirmEstimasiBiaya() async {
    final estimasiBiaya = _parseNumber(_orderData['estimasi_biaya']);
    num jumlahDp = _parseNumber(_orderData['jumlah_dp']);
    if (jumlahDp == 0 && estimasiBiaya > 0) {
      jumlahDp = estimasiBiaya * 0.4;
    }
    final sisaPembayaran = estimasiBiaya - jumlahDp;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Setujui Estimasi Biaya',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3E2723),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogAmountRow('Total Estimasi Biaya', 'Rp ${_formatRupiah(estimasiBiaya)}'),
            const SizedBox(height: 6),
            _buildDialogAmountRow('Jumlah DP (40%)', 'Rp ${_formatRupiah(jumlahDp)}', color: const Color(0xFFB45309)),
            const SizedBox(height: 6),
            _buildDialogAmountRow('Sisa Pembayaran', 'Rp ${_formatRupiah(sisaPembayaran)}', color: const Color(0xFF6B7280)),
            const SizedBox(height: 12),
            const Text(
              'Dengan menyetujui, Anda dapat melanjutkan ke pembayaran DP secara manual.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Setuju', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionLoading = true);

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
        body: jsonEncode({'action': 'konfirmasi_biaya'}),
      );

      if (!mounted) return;
      setState(() => _isActionLoading = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Estimasi biaya disetujui. Silakan lakukan pembayaran DP.'),
            backgroundColor: Color(0xFF059669),
          ),
        );
        _fetchLatestOrderDetail();
      } else {
        final decoded = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decoded['message'] ?? 'Gagal menyetujui estimasi biaya'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isActionLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Widget _buildDialogAmountRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280))),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color ?? const Color(0xFF3E2723)),
        ),
      ],
    );
  }

  // ============================================================
  // AKSI 2 & 3: PELANGGAN MENGIRIM BUKTI PEMBAYARAN (DP / LUNAS)
  // ============================================================

  Future<void> _sendPaymentProof(String actionName, String dialogTitle, String successMessage) async {
    File? selectedImage;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickImage(ImageSource source) async {
              final XFile? picked = await _imagePicker.pickImage(
                source: source,
                imageQuality: 80,
              );
              if (picked != null) {
                setDialogState(() => selectedImage = File(picked.path));
              }
            }

            return AlertDialog(
              title: Text(
                dialogTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E2723),
                ),
              ),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Unggah foto bukti transfer (struk/screenshot) sebagai bukti pembayaran:',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 160,
                        width: double.infinity,
                        child: selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDFBF7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFEADFD8)),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    color: Color(0xFF9CA3AF),
                                    size: 36,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt_outlined, size: 16),
                              label: const Text('Kamera', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                side: const BorderSide(color: Color(0xFFEADFD8)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined, size: 16),
                              label: const Text('Galeri', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                side: const BorderSide(color: Color(0xFFEADFD8)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
                ),
                ElevatedButton(
                  onPressed: selectedImage == null ? null : () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Kirim Bukti', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm != true || selectedImage == null) return;

    setState(() => _isActionLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // Karena mengirim file gambar dan method PUT, gunakan http.MultipartRequest dengan _method spoofing Laravel
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${widget.baseUrl}/orders/${widget.orderId}'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['_method'] = 'PUT';
      request.fields['action'] = actionName;

      request.files.add(
        await http.MultipartFile.fromPath('bukti_pembayaran', selectedImage!.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;
      setState(() => _isActionLoading = false);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _orderData = decoded['data'] ?? _orderData;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: const Color(0xFF059669),
          ),
        );
        _fetchLatestOrderDetail();
      } else {
        final decoded = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decoded['message'] ?? 'Gagal mengunggah bukti pembayaran'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isActionLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  // ============================================================
  // WHATSAPP
  // ============================================================

  Future<void> _openWhatsApp() async {
    setState(() => _isLaunchingWhatsApp = true);

    try {
      final userData = _orderData['user'] ?? {};
      final userName = userData['name'] ?? userData['nama'] ?? 'Pelanggan';
      final kodePesanan = _orderData['kode_pesanan'] ?? '-';
      final estimasiBiaya = _parseNumber(_orderData['estimasi_biaya']);
      final formattedBiaya = _formatRupiah(estimasiBiaya);
      List items = _orderData['order_items'] ?? _orderData['items'] ?? [];
      String detailProdukText = "";

      if (items.isNotEmpty) {
        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          final pName = item['product']?['nama_product'] ?? item['nama_custom'] ?? 'Produk Custom';
          final qty = item['jumlah'] ?? 1;
          final ukuran = item['ukuran'] ?? item['specification']?['ukuran'] ?? '-';
          final material = item['material'] ?? item['specification']?['material'] ?? '-';

          detailProdukText += "\n- ${i + 1}. *$pName* ($qty Pcs) | Ukuran: $ukuran | Bahan: $material";
        }
      } else {
        detailProdukText = "\n- Pesanan Custom";
      }

      final message = "Halo Owner Adi Ukiran, saya *$userName*. "
          "Saya ingin menanyakan tentang pesanan saya "
          "dengan nomor *$kodePesanan*.\n\n"
          "*Detail Pesanan:*$detailProdukText\n\n"
          "*Total Biaya:* Rp $formattedBiaya";

      const ownerPhoneNumber = "6283815535218";
      final whatsappUrl = "https://wa.me/$ownerPhoneNumber?text=${Uri.encodeComponent(message)}";
      final Uri uri = Uri.parse(whatsappUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Tidak dapat membuka aplikasi WhatsApp';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLaunchingWhatsApp = false);
      }
    }
  }

  // ============================================================
  // BATALKAN PESANAN
  // ============================================================

  Future<void> _cancelOrder() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Batalkan Pesanan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3E2723),
          ),
        ),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan pesanan ini? Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Tidak',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Ya, Batalkan',
              style: TextStyle(color: Colors.white),
            ),
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
          const SnackBar(
            content: Text('Pesanan berhasil dibatalkan'),
            backgroundColor: Color(0xFF059669),
          ),
        );
        Navigator.pop(context, true);
      } else {
        final decoded = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decoded['message'] ?? 'Gagal membatalkan pesanan'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCancelling = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan koneksi: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  // ============================================================
  // BUILD DETAIL
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final statusPesanan = (_orderData['status_pesanan'] ?? 'menunggu').toString();
    final estimasiBiaya = _parseNumber(_orderData['estimasi_biaya']);

    num jumlahDp = _parseNumber(_orderData['jumlah_dp']);
    if (jumlahDp == 0 && estimasiBiaya > 0) {
      jumlahDp = estimasiBiaya * 0.4;
    }
    final num sisaPembayaran = estimasiBiaya > 0 ? (estimasiBiaya - jumlahDp) : 0;

    final statusPembayaran = (_orderData['status_pembayaran'] ?? 'menunggu_konfirmasi_biaya').toString();
    final biayaDikonfirmasi = _parseBool(_orderData['biaya_dikonfirmasi']);
    final estimasiWaktu = (_orderData['estimasi_waktu'] ?? 'Menunggu konfirmasi').toString();
    final estimasiSelesai = (_orderData['estimasi_selesai'] ?? '-').toString();
    final kodePesanan = (_orderData['kode_pesanan'] ?? '-').toString();
    final categoryLabel = widget.getOrderCategoryLabel(_orderData);
    final rawTanggal = (_orderData['tanggal_pesanan'] ?? '').toString();

    String tanggal = '-';
    if (rawTanggal.isNotEmpty) {
      try {
        DateTime parsedDate = DateTime.parse(rawTanggal).toLocal();
        tanggal = "${parsedDate.day.toString().padLeft(2, '0')}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.year} ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}";
      } catch (e) {
        tanggal = rawTanggal;
      }
    }

    final catatan = (_orderData['catatan'] ?? 'Tidak ada catatan khusus.').toString();

    List<dynamic> orderItems = _orderData['order_items'] ?? _orderData['items'] ?? [];
    if (orderItems.isEmpty && (_orderData['product'] != null || _orderData['nama_custom'] != null)) {
      orderItems = [_orderData];
    }

    List<dynamic> statusHistory = List.from(_orderData['status_history'] ?? []);
    final paymentColor = _getPaymentStatusColor(statusPembayaran);
    final paymentLabel = _getPaymentStatusLabel(statusPembayaran);

    final bool isOrderClosed = statusPesanan.toLowerCase() == 'dibatalkan' || statusPesanan.toLowerCase() == 'selesai';

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: Stack(
        children: [
          Column(
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
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF3E2723),
                              ),
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
                              style: const TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5D4037),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF6B7280),
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(
                color: Color(0xFFEADFD8),
                height: 1,
              ),
              Expanded(
                child: _isLoadingDetail && statusHistory.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF5D4037),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          // =================================================
                        // INFORMASI PESANAN
                        // =================================================
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
                                  const Text(
                                    'Status Pesanan',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF3E2723),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: widget.getStatusColor(statusPesanan).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      statusPesanan.replaceAll('_', ' ').toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: widget.getStatusColor(statusPesanan),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildSpecRow(
                                'Kategori / Tahapan',
                                categoryLabel.toUpperCase(),
                                valueColor: const Color(0xFF5D4037),
                              ),
                              const Divider(height: 16, color: Color(0xFFEADFD8)),
                              _buildSpecRow(
                                'Tanggal & Waktu Pesanan',
                                tanggal,
                              ),
                              // Baris 'Estimasi Waktu' dihapus di sini agar konsisten dengan panel owner
                              const Divider(height: 16, color: Color(0xFFEADFD8)),
                              _buildSpecRow(
                                'Perkiraan Tanggal Selesai',
                                estimasiSelesai,
                                valueColor: const Color(0xFF059669),
                              ),
                              const Divider(height: 16, color: Color(0xFFEADFD8)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Estimasi Biaya',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  Text(
                                    estimasiBiaya > 0 ? 'Rp ${_formatRupiah(estimasiBiaya)}' : 'Belum ditentukan',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: estimasiBiaya > 0 ? const Color(0xFFB45309) : const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                              if (!biayaDikonfirmasi && estimasiBiaya > 0) ...[
                                const SizedBox(height: 4),
                                const Text(
                                  '⏳ Menunggu persetujuan Anda',
                                  style: TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF)),
                                ),
                              ],
                              const Divider(height: 16, color: Color(0xFFEADFD8)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Jumlah DP (40%)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  Text(
                                    estimasiBiaya > 0 ? 'Rp ${_formatRupiah(jumlahDp)}' : '-',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16, color: Color(0xFFEADFD8)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Sisa Pembayaran (Pelunasan)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  Text(
                                    estimasiBiaya > 0 ? 'Rp ${_formatRupiah(sisaPembayaran)}' : '-',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16, color: Color(0xFFEADFD8)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Status Pembayaran',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: paymentColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        paymentLabel,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: paymentColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                          // =================================================
                          // AKSI PELANGGAN
                          // =================================================
                          if (!isOrderClosed) ...[
                            const SizedBox(height: 20),
                            const Text(
                              'Aksi Pelanggan',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF3E2723),
                              ),
                            ),
                            const SizedBox(height: 10),

                            if (statusPembayaran == 'belum_bayar' || statusPembayaran == 'menunggu_pembayaran_dp') ...[
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isActionLoading
                                      ? null
                                      : () => _sendPaymentProof(
                                            'konfirmasi_bayar_dp',
                                            'Konfirmasi Pembayaran DP',
                                            'Konfirmasi pembayaran DP beserta bukti berhasil dikirim.',
                                          ),
                                  icon: const Icon(Icons.payments_outlined, size: 18),
                                  label: const Text('Konfirmasi Sudah Bayar DP (Unggah Bukti)'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],

                            if (statusPembayaran == 'dp_dibayar') ...[
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isActionLoading
                                      ? null
                                      : () => _sendPaymentProof(
                                            'konfirmasi_bayar_lunas',
                                            'Konfirmasi Pelunasan',
                                            'Konfirmasi pelunasan beserta bukti berhasil dikirim.',
                                          ),
                                  icon: const Icon(Icons.task_alt_rounded, size: 18),
                                  label: const Text('Konfirmasi Sudah Bayar Lunas (Unggah Bukti)'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF059669),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],

                            if (statusPembayaran == 'menunggu_verifikasi_dp' || statusPembayaran == 'menunggu_verifikasi_lunas') ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFF59E0B)),
                                ),
                                child: const Text(
                                  'Bukti pembayaran Anda sedang diverifikasi oleh owner. Mohon menunggu sebentar.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],

                            if (statusPembayaran == 'lunas' && statusPesanan.toLowerCase() != 'selesai') ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF6EE7B7)),
                                ),
                                child: const Text(
                                  'Pembayaran sudah lunas. Pesanan sedang dalam proses produksi.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],

                            if (statusPesanan.toLowerCase() == 'menunggu_konfirmasi' || statusPesanan.toLowerCase() == 'menunggu') ...[
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _isCancelling ? null : _cancelOrder,
                                  icon: _isCancelling
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFFEF4444),
                                          ),
                                        )
                                      : const Icon(Icons.cancel_outlined, size: 18, color: Color(0xFFEF4444)),
                                  label: Text(
                                    _isCancelling ? 'Memproses...' : 'Batalkan Pesanan',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFEF4444)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],

                          // =================================================
                          // DAFTAR PRODUK
                          // =================================================
                          const SizedBox(height: 24),
                          const Text(
                            'Daftar Produk Pesanan',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF3E2723),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...orderItems.map((item) {
                            final productName = item['product']?['nama_product'] ?? item['nama_custom'] ?? 'Produk Custom';
                            final jumlah = item['jumlah'] ?? 1;
                            final ukuran = item['ukuran'] ?? item['specification']?['ukuran'] ?? '-';
                            final material = item['material'] ?? item['specification']?['material'] ?? '-';
                            final motif = item['motif_ukiran'] ?? item['motif'] ?? item['specification']?['motif_ukiran'] ?? '-';
                            final rawSubtotal = item['subtotal'] ?? item['estimasi_biaya'] ?? 0;
                            final num subtotal = _parseNumber(rawSubtotal);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFEADFD8)),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF5D4037).withOpacity(0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
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
                                          productName.toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Color(0xFF3E2723),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF5D4037).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '$jumlah Pcs',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF5D4037),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Divider(
                                      height: 1,
                                      color: Color(0xFFEADFD8),
                                    ),
                                  ),
                                  _buildSpecRow('Ukuran', ukuran.toString()),
                                  const SizedBox(height: 6),
                                  _buildSpecRow('Material / Bahan', material.toString()),
                                  const SizedBox(height: 6),
                                  _buildSpecRow('Motif Ukiran', motif.toString()),
                                  if (subtotal > 0) ...[
                                    const SizedBox(height: 6),
                                    _buildSpecRow(
                                      'Subtotal',
                                      'Rp ${_formatRupiah(subtotal)}',
                                      valueColor: const Color(0xFFB45309),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),

                          // =================================================
                          // CATATAN
                          // =================================================
                          const SizedBox(height: 16),
                          const Text(
                            'Catatan Tambahan',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF3E2723),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDFBF7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFEADFD8)),
                            ),
                            child: Text(
                              // Mengambil catatan utama, atau fallback ke catatan dari item pertama jika ada
                              (_orderData['catatan'] ?? 
                              (_orderData['order_items'] != null && (_orderData['order_items'] as List).isNotEmpty 
                                  ? _orderData['order_items'][0]['catatan'] 
                                  : null) ?? 
                              'Tidak ada catatan khusus.'
                              ).toString(),
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF6B7280),
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                              ),
                            ),
                          ),

                          // =================================================
                          // RIWAYAT STATUS
                          // =================================================
                          const SizedBox(height: 24),
                          const Text(
                            'Riwayat Status Produksi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF3E2723),
                            ),
                          ),
                          const SizedBox(height: 10),
                          statusHistory.isEmpty
                              ? const Text(
                                  'Belum ada riwayat progres status.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: statusHistory.length,
                                  itemBuilder: (context, idx) {
                                    final history = statusHistory[idx];
                                    final rawDate = history['tanggal_update'] ?? history['created_at'] ?? '';
                                    String formattedDate = '-';

                                    if (rawDate.toString().isNotEmpty) {
                                      try {
                                        DateTime parsedDate = DateTime.parse(rawDate.toString()).toLocal();
                                        formattedDate = "${parsedDate.day.toString().padLeft(2, '0')}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.year} ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}";
                                      } catch (e) {
                                        formattedDate = rawDate.toString();
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
                                                    Flexible(
                                                      child: Text(
                                                        (history['status'] ?? '').toString().replaceAll('_', ' ').toUpperCase(),
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                          color: isCancelledHistory ? const Color(0xFFEF4444) : const Color(0xFF3E2723),
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      formattedDate,
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Color(0xFF9CA3AF),
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  history['keterangan'] ?? (isCancelledHistory ? 'Pesanan telah dibatalkan.' : 'Tidak ada keterangan.'),
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

          // ============================================================
          // WHATSAPP
          // ============================================================
          Positioned(
            right: 20,
            bottom: 20,
            child: GestureDetector(
              onTap: _isLaunchingWhatsApp ? null : _openWhatsApp,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF25D366).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: _isLaunchingWhatsApp
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const FaIcon(
                          FontAwesomeIcons.whatsapp,
                          color: Colors.white,
                          size: 30,
                        ),
                ),
              ),
            ),
          ),

          if (_isActionLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.15),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF5D4037)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SPEC ROW
  // ============================================================
  Widget _buildSpecRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor ?? const Color(0xFF3E2723),
            ),
          ),
        ),
      ],
    );
  }
}