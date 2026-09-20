import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String _errorMessage = '';

  // Status email belum diverifikasi
  bool _requiresVerification = false;

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get requiresVerification => _requiresVerification;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<bool> login(
    String email,
    String password,
  ) async {
    _setLoading(true);

    _errorMessage = '';
    _requiresVerification = false;

    try {
      final response = await _apiService.login(
        email.trim(),
        password,
      );

      // ========================================================
      // EMAIL BELUM DIVERIFIKASI
      // ========================================================

      if (response['requires_verification'] == true) {
        _requiresVerification = true;

        _errorMessage =
            response['message'] ??
            'Email Anda belum diverifikasi.';

        _setLoading(false);
        return false;
      }

      // ========================================================
      // LOGIN BERHASIL
      // ========================================================

      final token = response['token'];

      if (token != null && token.toString().isNotEmpty) {
        await _apiService.saveToken(
          token.toString(),
        );

        _setLoading(false);
        return true;
      }

      // ========================================================
      // LOGIN GAGAL
      // ========================================================

      _errorMessage =
          response['message'] ??
          'Email atau password salah.';

      _setLoading(false);
      return false;

    } catch (e) {
      _errorMessage =
          'Terjadi kesalahan jaringan.';

      _setLoading(false);
      return false;
    }
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<bool> register(
    Map<String, dynamic> data,
  ) async {
    _setLoading(true);

    _errorMessage = '';
    _requiresVerification = false;

    try {
      final response =
          await _apiService.register(data);

      // ========================================================
      // REGISTRASI BERHASIL
      // AKUN MENUNGGU VERIFIKASI OTP
      // ========================================================

      if (response['requires_verification'] == true) {
        _setLoading(false);
        return true;
      }

      // ========================================================
      // ERROR VALIDASI
      // ========================================================

      if (response.containsKey('errors')) {
        final errors = response['errors'];

        if (errors is Map<String, dynamic> &&
            errors.isNotEmpty) {
          final firstError = errors.values.first;

          if (firstError is List &&
              firstError.isNotEmpty) {
            _errorMessage =
                firstError.first.toString();
          } else {
            _errorMessage =
                'Data registrasi tidak valid.';
          }
        } else {
          _errorMessage =
              'Registrasi gagal.';
        }
      } else {
        _errorMessage =
            response['message'] ??
            'Registrasi gagal.';
      }

      _setLoading(false);
      return false;

    } catch (e) {
      _errorMessage =
          'Terjadi kesalahan jaringan.';

      _setLoading(false);
      return false;
    }
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<bool> verifyOtp(
    String email,
    String otp,
  ) async {
    _setLoading(true);

    _errorMessage = '';

    try {
      final response =
          await _apiService.verifyOtp(
        email.trim(),
        otp.trim(),
      );

      // ========================================================
      // OTP BERHASIL
      // ========================================================

      if (response['verified'] == true) {
        _requiresVerification = false;

        _setLoading(false);
        return true;
      }

      // ========================================================
      // OTP GAGAL
      // ========================================================

      _errorMessage =
          response['message'] ??
          'Kode OTP tidak valid.';

      _setLoading(false);
      return false;

    } catch (e) {
      _errorMessage =
          'Terjadi kesalahan jaringan.';

      _setLoading(false);
      return false;
    }
  }

  // ============================================================
  // RESEND OTP
  // ============================================================

  Future<bool> resendOtp(
    String email,
  ) async {
    _setLoading(true);

    _errorMessage = '';

    try {
      final response =
          await _apiService.resendOtp(
        email.trim(),
      );

      // Pastikan memang ada pesan dari backend
      if (response['message'] != null) {
        _setLoading(false);
        return true;
      }

      _errorMessage =
          'Gagal mengirim ulang kode OTP.';

      _setLoading(false);
      return false;

    } catch (e) {
      _errorMessage =
          'Terjadi kesalahan jaringan.';

      _setLoading(false);
      return false;
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await _apiService.logout();

    await _apiService.removeToken();

    _requiresVerification = false;
    _errorMessage = '';

    notifyListeners();
  }
}