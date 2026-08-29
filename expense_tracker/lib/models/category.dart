class Category {
  final int id;
  final String name;
  final String color;
  final String icon;

  const Category({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as int,
        name: json['name'] as String,
        color: json['color'] as String,
        icon: json['icon'] as String,
      );
}
