import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String debtId;
  final String clientId;
  final double amount;
  final DateTime date;
  final String? notes;
  bool isDirty;

  PaymentModel({
    required this.id,
    required this.debtId,
    required this.clientId,
    required this.amount,
    DateTime? date,
    this.notes,
    this.isDirty = false,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'debtId': debtId,
    'clientId': clientId,
    'amount': amount,
    'date': date.toIso8601String(),
    'notes': notes,
  };

  factory PaymentModel.fromMap(Map<String, dynamic> map) => PaymentModel(
    id: map['id'] ?? '',
    debtId: map['debtId'] ?? '',
    clientId: map['clientId'] ?? '',
    amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    notes: map['notes'] as String?,
    date: map['date'] != null
        ? (map['date'] is Timestamp
            ? (map['date'] as Timestamp).toDate()
            : DateTime.parse(map['date'].toString()))
        : DateTime.now(),
  );
}
