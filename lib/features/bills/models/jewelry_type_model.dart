class JewelryTypeModel {
  final String id;
  final String name;
  final String nameAr;
  final double defaultWeight;
  final double defaultPrice;
  final String defaultKarat;
  bool isDirty;

  JewelryTypeModel({
    required this.id,
    required this.name,
    this.nameAr = '',
    this.defaultWeight = 0.0,
    this.defaultPrice = 0.0,
    this.defaultKarat = '18',
    this.isDirty = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'nameAr': nameAr,
    'defaultWeight': defaultWeight,
    'defaultPrice': defaultPrice,
    'defaultKarat': defaultKarat,
  };

  factory JewelryTypeModel.fromMap(Map<String, dynamic> map) => JewelryTypeModel(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    nameAr: map['nameAr'] ?? '',
    defaultWeight: (map['defaultWeight'] as num?)?.toDouble() ?? 0.0,
    defaultPrice: (map['defaultPrice'] as num?)?.toDouble() ?? 0.0,
    defaultKarat: map['defaultKarat'] ?? '18',
  );

  JewelryTypeModel copyWith({
    String? id,
    String? name,
    String? nameAr,
    double? defaultWeight,
    double? defaultPrice,
    String? defaultKarat,
    bool? isDirty,
  }) => JewelryTypeModel(
    id: id ?? this.id,
    name: name ?? this.name,
    nameAr: nameAr ?? this.nameAr,
    defaultWeight: defaultWeight ?? this.defaultWeight,
    defaultPrice: defaultPrice ?? this.defaultPrice,
    defaultKarat: defaultKarat ?? this.defaultKarat,
    isDirty: isDirty ?? this.isDirty,
  );
}
