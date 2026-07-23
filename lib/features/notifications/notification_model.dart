class AppNotification {
  final int id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id:        json['id'] as int,
        title:     json['title'] as String? ?? '',
        body:      json['body'] as String? ?? '',
        type:      json['type'] as String? ?? 'general',
        data:      (json['data'] as Map<String, dynamic>?) ?? {},
        readAt:    json['read_at'] != null
            ? DateTime.tryParse(json['read_at'] as String)
            : null,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  AppNotification copyWith({DateTime? readAt}) => AppNotification(
        id:        id,
        title:     title,
        body:      body,
        type:      type,
        data:      data,
        readAt:    readAt ?? this.readAt,
        createdAt: createdAt,
      );
}
