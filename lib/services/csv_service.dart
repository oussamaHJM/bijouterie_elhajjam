import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import '../features/loans/models/client_model.dart';
import '../features/loans/models/debt_model.dart';
import '../features/loans/models/payment_model.dart';
import '../features/bills/models/bill_model.dart';

class CsvService {
  static final DateFormat _fmt = DateFormat('dd/MM/yyyy');

  // ─── EXPORT ────────────────────────────────────────────────────────────────

  /// Returns ZIP bytes containing 5 CSV files for the full database.
  Uint8List exportAll({
    required List<ClientModel> clients,
    required List<DebtModel> debts,
    required List<PaymentModel> payments,
    required List<BillModel> bills,
  }) {
    final archive = Archive();

    _addFile(archive, 'clients.csv', _buildClientsCsv(clients));
    _addFile(archive, 'dettes.csv', _buildDebtsCsv(debts));
    _addFile(archive, 'paiements.csv', _buildPaymentsCsv(payments));
    _addFile(archive, 'factures.csv', _buildBillsCsv(bills));
    _addFile(archive, 'articles_factures.csv', _buildBillItemsCsv(bills));

    return Uint8List.fromList(ZipEncoder().encode(archive)!);
  }

  void _addFile(Archive archive, String name, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  String _buildClientsCsv(List<ClientModel> clients) {
    final rows = <List<dynamic>>[
      ['id', 'prenom', 'nom', 'telephone', 'date_creation'],
      ...clients.map((c) => [
        c.id,
        c.firstName,
        c.lastName,
        c.phone,
        _fmt.format(c.createdAt),
      ]),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  String _buildDebtsCsv(List<DebtModel> debts) {
    final rows = <List<dynamic>>[
      ['id', 'client_id', 'montant', 'date', 'solde', 'notes'],
      ...debts.map((d) => [
        d.id,
        d.clientId,
        d.amount,
        _fmt.format(d.date),
        d.settled ? 'Oui' : 'Non',
        d.notes ?? '',
      ]),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  String _buildPaymentsCsv(List<PaymentModel> payments) {
    final rows = <List<dynamic>>[
      ['id', 'dette_id', 'client_id', 'montant', 'date'],
      ...payments.map((p) => [
        p.id,
        p.debtId,
        p.clientId,
        p.amount,
        _fmt.format(p.date),
      ]),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  String _buildBillsCsv(List<BillModel> bills) {
    final rows = <List<dynamic>>[
      ['id', 'client', 'ville', 'date', 'total_mad'],
      ...bills.map((b) => [
        b.id,
        b.clientName,
        b.city,
        _fmt.format(b.date),
        b.total,
      ]),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  String _buildBillItemsCsv(List<BillModel> bills) {
    final rows = <List<dynamic>>[
      ['facture_id', 'quantite', 'type_bijoux', 'eiar', 'poids_g', 'prix_par_g', 'total_mad'],
    ];
    for (final bill in bills) {
      for (final item in bill.items) {
        rows.add([
          bill.id,
          item.quantity,
          item.jewelryType,
          item.karat,
          item.weight,
          item.pricePerGram,
          item.total,
        ]);
      }
    }
    return const ListToCsvConverter().convert(rows);
  }

  // ─── IMPORT ────────────────────────────────────────────────────────────────

  /// Parse a clients CSV string into ClientModel list.
  List<ClientModel> importClients(String csvContent) {
    final rows = const CsvToListConverter(eol: '\n').convert(csvContent);
    if (rows.isEmpty) return [];
    return rows.skip(1).map((row) {
      return ClientModel(
        id: row[0].toString(),
        firstName: row[1].toString(),
        lastName: row[2].toString(),
        phone: row[3].toString(),
        createdAt: _parseDate(row[4].toString()),
      );
    }).toList();
  }

  List<DebtModel> importDebts(String csvContent) {
    final rows = const CsvToListConverter(eol: '\n').convert(csvContent);
    if (rows.isEmpty) return [];
    return rows.skip(1).map((row) {
      return DebtModel(
        id: row[0].toString(),
        clientId: row[1].toString(),
        amount: double.tryParse(row[2].toString()) ?? 0.0,
        date: _parseDate(row[3].toString()),
        settled: row[4].toString() == 'Oui',
        notes: row.length > 5 ? row[5].toString() : null,
      );
    }).toList();
  }

  List<PaymentModel> importPayments(String csvContent) {
    final rows = const CsvToListConverter(eol: '\n').convert(csvContent);
    if (rows.isEmpty) return [];
    return rows.skip(1).map((row) {
      return PaymentModel(
        id: row[0].toString(),
        debtId: row[1].toString(),
        clientId: row[2].toString(),
        amount: double.tryParse(row[3].toString()) ?? 0.0,
        date: _parseDate(row[4].toString()),
      );
    }).toList();
  }

  List<BillModel> importBillsFromCsv(String billsCsv, String itemsCsv) {
    final billRows = const CsvToListConverter(eol: '\n').convert(billsCsv);
    final itemRows = const CsvToListConverter(eol: '\n').convert(itemsCsv);

    // Map billId → items
    final itemsByBill = <String, List<BillItemModel>>{};
    for (final row in itemRows.skip(1)) {
      final billId = row[0].toString();
      itemsByBill.putIfAbsent(billId, () => []);
      itemsByBill[billId]!.add(BillItemModel(
        quantity: int.tryParse(row[1].toString()) ?? 1,
        jewelryType: row[2].toString(),
        karat: row[3].toString(),
        weight: double.tryParse(row[4].toString()) ?? 0.0,
        pricePerGram: double.tryParse(row[5].toString()) ?? 0.0,
      ));
    }

    return billRows.skip(1).map((row) {
      final id = row[0].toString();
      return BillModel(
        id: id,
        clientName: row[1].toString(),
        city: row[2].toString(),
        date: _parseDate(row[3].toString()),
        items: itemsByBill[id] ?? [],
        total: double.tryParse(row[4].toString()) ?? 0.0,
      );
    }).toList();
  }

  DateTime _parseDate(String s) {
    try {
      return DateFormat('dd/MM/yyyy').parse(s);
    } catch (_) {
      try {
        return DateTime.parse(s);
      } catch (_) {
        return DateTime.now();
      }
    }
  }
}
