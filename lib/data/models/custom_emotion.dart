class CustomEmotion {
  final String? id;
  final String name;
  final int color;
  final DateTime createdAt;

  CustomEmotion({
    this.id,
    required this.name,
    required this.color,
    required this.createdAt,
  });

  factory CustomEmotion.fromJson(Map<String, dynamic> json) {
    return CustomEmotion(
      id: json['id']?.toString(), // Ensure string conversion
      name: json['name'] ?? '',
      color:
          json['color'] is int
              ? json['color']
              : int.tryParse(json['color']?.toString() ?? '0') ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'color': color};
  }

  // SQLite methods
  factory CustomEmotion.fromMap(Map<String, dynamic> map) {
    return CustomEmotion(
      id: map['id']?.toString(),
      name: map['name'] ?? '',
      color: map['color'] ?? 0,
      createdAt:
          DateTime.now(), // SQLite doesn't store createdAt for custom emotions
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'color': color};
  }
}
