import 'package:bekalpo/core/models/district.dart';

class Division {
  final int? id;
  final String? nameEn;
  final String? nameBn;
  final int? districtsCount;
  final int? subDistrictsCount;
  final List<District>? districts;

  Division({
    this.id,
    this.nameEn,
    this.nameBn,
    this.districtsCount,
    this.subDistrictsCount,
    this.districts,
  });

  factory Division.fromJson(Map<String, dynamic> json) {
    return Division(
      id: json['id'] as int?,
      nameEn: json['name_en'] as String?,
      nameBn: json['name_bn'] as String?,
      districtsCount: json['districts_count'] as int?,
      subDistrictsCount: json['sub_districts_count'] as int?,
      districts: json['districts'] != null
          ? (json['districts'] as List)
                .map((e) => District.fromJson(e))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_bn': nameBn,
      'districts_count': districtsCount,
      'sub_districts_count': subDistrictsCount,
      'districts': districts?.map((e) => e.toJson()).toList(),
    };
  }
}
