class AppNotification {
  final int id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final String createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id:        j['id'] as int,
        title:     j['title'] as String,
        body:      j['body'] as String,
        type:      j['type'] as String,
        data:      j['data'] as Map<String, dynamic>?,
        isRead:    j['is_read'] as bool? ?? false,
        createdAt: j['created_at'] as String,
      );
}
