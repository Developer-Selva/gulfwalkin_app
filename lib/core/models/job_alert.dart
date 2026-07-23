class JobAlert {
  final int id;
  final String? keywords;
  final String? location;
  final String? category;
  final String createdAt;

  const JobAlert({
    required this.id,
    this.keywords,
    this.location,
    this.category,
    required this.createdAt,
  });

  factory JobAlert.fromJson(Map<String, dynamic> j) => JobAlert(
        id:        j['id'] as int,
        keywords:  j['keywords'] as String?,
        location:  j['location'] as String?,
        category:  j['category'] as String?,
        createdAt: j['created_at'] as String,
      );
}
