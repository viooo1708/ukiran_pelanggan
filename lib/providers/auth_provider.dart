import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = '';
    
    try {
      final response = await _apiService.login(email, password);
      
      if (response.containsKey('token')) {
        await _apiService.saveToken(response['token']);
        _setLoading(false);
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Login gagal';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    _setLoading(true);
    _errorMessage = '';
    
    try {
      final response = await _apiService.register(data);
      
      if (response.containsKey('token')) {
        await _apiService.saveToken(response['token']);
        _setLoading(false);
        return true;
      } else {
        // Menangkap validasi error dari Laravel
        if (response.containsKey('errors')) {
           Map<String, dynamic> errors = response['errors'];
           _errorMessage = errors.values.first[0]; // Ambil pesan error pertama
        } else {
           _errorMessage = 'Registrasi gagal.';
        }
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan.';
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    await _apiService.removeToken();
    notifyListeners();
  }
}