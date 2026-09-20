import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ============================================================
  // BASE URL
  // ============================================================

  static final String baseUrl = kIsWeb
      ? 'http://127.0.0.1:1000/api'
      : 'http://10.184.161.201:1000/api';


  // ============================================================
  // TOKEN
  // ============================================================

  // Menyimpan token ke SharedPreferences
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Mengambil token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Menghapus token
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }


  // ============================================================
  // REGISTER
  // ============================================================

  Future<Map<String, dynamic>> register(
      Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(data),
    );

    return jsonDecode(response.body);
  }


  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<Map<String, dynamic>> verifyOtp(
      String email,
      String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-otp'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'otp': otp,
      }),
    );

    return jsonDecode(response.body);
  }


  // ============================================================
  // RESEND OTP
  // ============================================================

  Future<Map<String, dynamic>> resendOtp(
      String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/resend-otp'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
      }),
    );

    return jsonDecode(response.body);
  }


  // ============================================================
  // LOGIN
  // ============================================================

  Future<Map<String, dynamic>> login(
      String email,
      String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    return jsonDecode(response.body);
  }


  // ============================================================
  // LOGOUT
  // ============================================================

  Future<bool> logout() async {
    final token = await getToken();

    if (token == null) {
      return false;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }
}