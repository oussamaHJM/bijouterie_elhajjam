import 'package:cloud_firestore/cloud_firestore.dart';

class ClientModel {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final DateTime createdAt;
  bool isDirty; // needs sync to Firestore

  ClientModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phone = '',
    DateTime? createdAt,
    this.isDirty = false,
  }) : createdAt = createdAt ?? DateTime.now();

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toMap() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ClientModel.fromMap(Map<String, dynamic> map) => ClientModel(
    id: map['id'] ?? '',
    firstName: map['firstName'] ?? '',
    lastName: map['lastName'] ?? '',
    phone: map['phone'] ?? '',
    createdAt: map['createdAt'] != null
        ? (map['createdAt'] is Timestamp
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.parse(map['createdAt'].toString()))
        : DateTime.now(),
  );

  ClientModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? phone,
    DateTime? createdAt,
    bool? isDirty,
  }) => ClientModel(
    id: id ?? this.id,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    phone: phone ?? this.phone,
    createdAt: createdAt ?? this.createdAt,
    isDirty: isDirty ?? this.isDirty,
  );
}
