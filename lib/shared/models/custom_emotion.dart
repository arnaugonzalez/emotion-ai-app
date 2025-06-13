import 'package:flutter/material.dart';

class CustomEmotion {
  final int? id;
  final String name;
  final Color color;

  CustomEmotion({this.id, required this.name, required this.color});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'color': color.value};
  }

  factory CustomEmotion.fromMap(Map<String, dynamic> map) {
    return CustomEmotion(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: Color(map['color'] as int),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomEmotion &&
        other.id == id &&
        other.name == name &&
        other.color.value == color.value;
  }

  @override
  int get hashCode => Object.hash(id, name, color.value);
}
