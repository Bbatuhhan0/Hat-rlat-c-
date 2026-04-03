import 'dart:convert';

class SavedLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  SavedLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  SavedLocation copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
  }) {
    return SavedLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory SavedLocation.fromMap(Map<String, dynamic> map) {
    return SavedLocation(
      id: map['id'],
      name: map['name'],
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory SavedLocation.fromJson(String source) =>
      SavedLocation.fromMap(json.decode(source));
}
