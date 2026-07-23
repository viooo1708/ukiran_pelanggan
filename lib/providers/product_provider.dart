import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Mengambil daftar produk dari GET /products
  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final token = await ApiService().getToken();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/products'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['data'];
        
        _products = data.map((json) => Product.fromJson(json)).toList();
      } else {
        _errorMessage = 'Gagal memuat produk dari server.';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan.';
    }

    _isLoading = false;
    notifyListeners();
  }
}