import 'package:cloud_firestore/cloud_firestore.dart';
import '../../bills/models/bill_model.dart';

class DebtModel {
  final String id;
  final String clientId;
  final double amount;
  final DateTime date;
  final String? notes;
  final List<BillItemModel> items;
  bool settled;
  bool isDirty;

  DebtModel({
    required this.id,
    required this.clientId,
    required this.amount,
    DateTime? date,
    this.notes,
    this.settled = false,
    this.isDirty = false,
    this.items = const [],
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'clientId': clientId,
    'amount': amount,
    'date': date.toIso8601String(),
    'notes': notes ?? '',
    'settled': settled,
    'items': items.map((i) => i.toMap()).toList(),
  };

  factory DebtModel.fromMap(Map<String, dynamic> map) => DebtModel(
    id: map['id'] ?? '',
    clientId: map['clientId'] ?? '',
    amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    date: map['date'] != null
        ? (map['date'] is Timestamp
            ? (map['date'] as Timestamp).toDate()
            : DateTime.parse(map['date'].toString()))
        : DateTime.now(),
    notes: map['notes'] as String?,
    settled: map['settled'] as bool? ?? false,
    items: (map['items'] as List<dynamic>?)
            ?.map((e) => BillItemModel.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [],
  );

  DebtModel copyWith({
    String? id,
    String? clientId,
    double? amount,
    DateTime? date,
    String? notes,
    bool? settled,
    bool? isDirty,
    List<BillItemModel>? items,
  }) => DebtModel(
    id: id ?? this.id,
    clientId: clientId ?? this.clientId,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    notes: notes ?? this.notes,
    settled: settled ?? this.settled,
    isDirty: isDirty ?? this.isDirty,
    items: items ?? this.items,
  );
}
