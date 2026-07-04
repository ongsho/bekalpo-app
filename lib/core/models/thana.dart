class Thana {
  final int? id;
  final String? nameEn;
  final String? nameBn;
  final int? districtId;

  Thana({this.id, this.nameEn, this.nameBn, this.districtId});

  factory Thana.fromJson(Map<String, dynamic> json) {
    return Thana(
      id: json['id'] as int?,
      nameEn: json['name_en'] as String?,
      nameBn: json['name_bn'] as String?,
      districtId: json['district_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_bn': nameBn,
      'district_id': districtId,
    };
  }
}
