import 'package:bekalpo/core/models/thana.dart';

class District {
  final int? id;
  final String? nameEn;
  final String? nameBn;
  final int? divisionId;
  final List<Thana>? thanas;

  District({this.id, this.nameEn, this.nameBn, this.divisionId, this.thanas});

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'] as int?,
      nameEn: json['name_en'] as String?,
      nameBn: json['name_bn'] as String?,
      divisionId: json['division_id'] as int?,
      thanas: json['thanas'] != null
          ? (json['thanas'] as List).map((e) => Thana.fromJson(e)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_bn': nameBn,
      'division_id': divisionId,
      'thanas': thanas?.map((e) => e.toJson()).toList(),
    };
  }
}
