class NotificationModel {
  final int id;
  final String title;
  final String message;
  final int? orderId;
  final bool isRead;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.orderId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'] ?? 'Pemberitahuan',
      message: json['message'] ?? '',
      orderId: json['order_id'],
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: json['created_at'] ?? '',
    );
  }
}