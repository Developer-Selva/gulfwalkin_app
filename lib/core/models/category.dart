class Category {
  final int id;
  final String name;
  final String? icon;
  final String? color;

  const Category({required this.id, required this.name, this.icon, this.color});

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id:    j['id'] as int,
        name:  j['name'] as String,
        icon:  j['icon'] as String?,
        color: j['color'] as String?,
      );
}
