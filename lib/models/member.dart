import 'package:isar/isar.dart';

part 'member.g.dart';

@collection
class Member {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String phone;
  
  final String name;
  final String? address;
  int points;
  final DateTime createdAt;

  Member({
    this.id = Isar.autoIncrement,
    required this.phone,
    required this.name,
    this.address,
    this.points = 0,
    required this.createdAt,
  });

  Member copyWith({
    Id? id,
    String? phone,
    String? name,
    String? address,
    int? points,
    DateTime? createdAt,
  }) {
    return Member(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      address: address ?? this.address,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
