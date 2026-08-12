import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
      : 'http://192.168.18.65:1000/api';
      

  // Fungsi untuk Inisialisasi FCM & Mengirim Token ke Backend Laravel
  Future<void> initFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 1. Minta Izin Notifikasi (terutama untuk Android 13+ / iOS)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Ambil token FCM perangkat
      String? fcmToken = await messaging.getToken();
      debugPrint("FCM TOKEN NOTIF: $fcmToken");

      if (fcmToken != null) {
        // 3. Kirim token ke backend Laravel
        await sendFcmTokenToBackend(fcmToken);
      }
    }

    // 4. Listener saat aplikasi dibuka dan pesan masuk (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Menerima pesan foreground: ${message.notification?.title}');
      // Refresh list notifikasi secara otomatis saat ada notifikasi masuk
      fetchNotifications();
    });
  }

  // Fungsi untuk mengirim FCM Token ke API Laravel
  Future<void> sendFcmTokenToBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token') ?? prefs.getString('auth_token');

      if (authToken == null) return;

      await http.post(
        Uri.parse('$baseUrl/update-fcm-token'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'fcm_token': token}),
      );
      debugPrint("FCM Token berhasil dikirim ke server backend");
    } catch (e) {
      debugPrint("Error sending FCM token: $e");
    }
  }

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