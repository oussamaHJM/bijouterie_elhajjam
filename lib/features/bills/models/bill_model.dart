import 'package:cloud_firestore/cloud_firestore.dart';

class BillItemModel {
  int quantity;
  String jewelryType;
  String karat;
  double weight;
  double pricePerGram;

  BillItemModel({
    this.quantity = 1,
    this.jewelryType = '',
    this.karat = '18',
    this.weight = 0.0,
    this.pricePerGram = 0.0,
  });

  double get total => weight * pricePerGram;

  Map<String, dynamic> toMap() => {
    'quantity': quantity,
    'jewelryType': jewelryType,
    'karat': karat,
    'weight': weight,
    'pricePerGram': pricePerGram,
  };

  factory BillItemModel.fromMap(Map<String, dynamic> map) => BillItemModel(
    quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    jewelryType: map['jewelryType'] ?? '',
    karat: map['karat'] ?? '18',
    weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
    pricePerGram: (map['pricePerGram'] as num?)?.toDouble() ?? 0.0,
  );

  BillItemModel copyWith({
    int? quantity,
    String? jewelryType,
    String? karat,
    double? weight,
    double? pricePerGram,
  }) => BillItemModel(
    quantity: quantity ?? this.quantity,
    jewelryType: jewelryType ?? this.jewelryType,
    karat: karat ?? this.karat,
    weight: weight ?? this.weight,
    pricePerGram: pricePerGram ?? this.pricePerGram,
  );
}

class BillModel {
  final String id;
  final String clientName;
  final String city;
  final DateTime date;
  final List<BillItemModel> items;
  final double total;
  bool isDirty;

  BillModel({
    required this.id,
    required this.clientName,
    this.city = 'Boujaad',
    DateTime? date,
    required this.items,
    required this.total,
    this.isDirty = false,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'clientName': clientName,
    'city': city,
    'date': date.toIso8601String(),
    'items': items.map((i) => i.toMap()).toList(),
    'total': total,
  };

  factory BillModel.fromMap(Map<String, dynamic> map) => BillModel(
    id: map['id'] ?? '',
    clientName: map['clientName'] ?? '',
    city: map['city'] ?? 'Boujaad',
    date: map['date'] != null
        ? (map['date'] is Timestamp
            ? (map['date'] as Timestamp).toDate()
            : DateTime.parse(map['date'].toString()))
        : DateTime.now(),
    items: (map['items'] as List<dynamic>?)
            ?.map((i) => BillItemModel.fromMap(i as Map<String, dynamic>))
            .toList() ??
        [],
    total: (map['total'] as num?)?.toDouble() ?? 0.0,
  );

  BillModel copyWith({
    String? id,
    String? clientName,
    String? city,
    DateTime? date,
    List<BillItemModel>? items,
    double? total,
    bool? isDirty,
  }) {
    return BillModel(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      city: city ?? this.city,
      date: date ?? this.date,
      items: items ?? this.items,
      total: total ?? this.total,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}
