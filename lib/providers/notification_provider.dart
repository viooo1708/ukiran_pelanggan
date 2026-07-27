import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;

  bool get hasUnread => _notifications.any((n) => !n.isRead);

  // Sesuaikan URL base ini dengan port Laravel Anda (misal: 1000, 8000, dll)
  final String baseUrl = kIsWeb 
      ? 'http://127.0.0.1:1000/api' 
      : 'http://10.0.2.2:1000/api';

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      // Pastikan key ini sama persis dengan yang disimpan saat login/register ('token' atau 'auth_token')
      final token = prefs.getString('token') ?? prefs.getString('auth_token');

      debugPrint("DEBUG TOKEN NOTIF: $token");

      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint("RESPONSE STATUS: ${response.statusCode}");
      debugPrint("RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['data'] ?? [];
        _notifications = list.map((json) => NotificationModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('auth_token');

      await http.post(
        Uri.parse('$baseUrl/notifications/$id/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      // Update status lokal secara instan
      _notifications = _notifications.map((n) {
        if (n.id == id) {
          return NotificationModel(
            id: n.id,
            title: n.title,
            message: n.message,
            orderId: n.orderId,
            isRead: true,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error mark as read: $e");
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('auth_token');

      await http.post(
        Uri.parse('$baseUrl/notifications/read-all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      await fetchNotifications();
    } catch (e) {
      debugPrint("Error mark all as read: $e");
    }
  }
}