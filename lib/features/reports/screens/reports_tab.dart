import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';
import '../../../core/theme.dart';
import '../../bills/bills_provider.dart';
import '../../bills/models/bill_model.dart';
import '../../loans/loans_provider.dart';
import '../../loans/models/debt_model.dart';
import '../../bills/screens/create_bill_screen.dart';
import '../../bills/screens/bills_history_screen.dart';
import '../../loans/screens/loans_list_screen.dart';

enum ReportPeriod { today, week, month, year, all }

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  ReportPeriod _period = ReportPeriod.month;

  bool _isDateInPeriod(DateTime date) {
    if (_period == ReportPeriod.all) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    switch (_period) {
      case ReportPeriod.today:
        return target == today;
      case ReportPeriod.week:
        return now.difference(date).inDays <= 7;
      case ReportPeriod.month:
        return now.year == date.year && now.month == date.month;
      case ReportPeriod.year:
        return now.year == date.year;
      case ReportPeriod.all:
        return true;
    }
  }

  Future<void> _exportExcel(BuildContext context, BillsProvider billsP, LoansProvider loansP) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1'); // remove default

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    // Tab 1: Ventes Comptant
    final sheetVentes = excel['Ventes Comptant'];
    sheetVentes.appendRow([TextCellValue('Date'), TextCellValue('Client'), TextCellValue('Montant (MAD)')]);
    final bills = billsP.bills.where((b) => _isDateInPeriod(b.date)).toList();
    for (var b in bills) {
      sheetVentes.appendRow([
        TextCellValue(dateFormat.format(b.date)),
        TextCellValue(b.clientName),
        DoubleCellValue(b.total),
      ]);
    }

    // Tab 2: Prêts Soldés
    final sheetSoldes = excel['Prêts Soldés'];
    sheetSoldes.appendRow([TextCellValue('Date'), TextCellValue('Client ID'), TextCellValue('Montant (MAD)')]);
    final debtsSoldes = loansP.allDebts.where((d) => d.settled && _isDateInPeriod(d.date)).toList();
    for (var d in debtsSoldes) {
      final clientRow = loansP.allClients.where((c) => c.id == d.clientId).firstOrNull;
      sheetSoldes.appendRow([
        TextCellValue(dateFormat.format(d.date)),
        TextCellValue(clientRow?.fullName ?? 'Inconnu'),
        DoubleCellValue(d.amount),
      ]);
    }

    // Tab 3: Prêts en Cours (Overall, un-filtered by period because pending money doesn't expire)
    final sheetEncours = excel['Prêts en Cours'];
    sheetEncours.appendRow([TextCellValue('Date'), TextCellValue('Client ID'), TextCellValue('Montant Initial'), TextCellValue('Reste à Payer')]);
    final debtsEncours = loansP.allDebts.where((d) => !d.settled).toList();
    for (var d in debtsEncours) {
      final clientRow = loansP.allClients.where((c) => c.id == d.clientId).firstOrNull;
      final paid = loansP.paymentsForDebt(d.id).fold(0.0, (sum, p) => sum + p.amount);
      final remaining = d.amount - paid;
      sheetEncours.appendRow([
        TextCellValue(dateFormat.format(d.date)),
        TextCellValue(clientRow?.fullName ?? 'Inconnu'),
        DoubleCellValue(d.amount),
        DoubleCellValue(remaining),
      ]);
    }

    final bytes = excel.encode();
    if (bytes != null) {
      await FileSaver.instance.saveFile(
        name: 'Rapport_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx',
        bytes: Uint8List.fromList(bytes),
        mimeType: MimeType.microsoftExcel,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fichier Excel exporté ✅')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BillsProvider, LoansProvider>(
      builder: (ctx, billsP, loansP, _) {
        final filteredBills = billsP.bills.where((b) => _isDateInPeriod(b.date)).toList();
        final filteredSoldOutLoans = loansP.allDebts.where((d) => d.settled && _isDateInPeriod(d.date)).toList();

        final totalVentesComptant = filteredBills.fold(0.0, (sum, b) => sum + b.total);
        final totalPretsSoldes = filteredSoldOutLoans.fold(0.0, (sum, d) => sum + d.amount);
        
        final grandTotalVendu = totalVentesComptant + totalPretsSoldes;

        // Pending loans ALWAYS calculates overall total (all time) because it's current money out
        final pendingLoans = loansP.allDebts.where((d) => !d.settled).toList();
        double totalPendingAmount = 0.0;
        double totalPaidOnPending = 0.0;
        for (final pl in pendingLoans) {
          totalPendingAmount += pl.amount;
          final pd = loansP.paymentsForDebt(pl.id).fold(0.0, (sum, p) => sum + p.amount);
          totalPaidOnPending += pd;
        }
        final totalRemainingPending = totalPendingAmount - totalPaidOnPending;

        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tableau de Bord — الرئيسية', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.darkGreen)),
                    ElevatedButton.icon(
                      onPressed: () => _exportExcel(context, billsP, loansP),
                      icon: const Icon(Icons.download),
                      label: const Text('Export Excel (Avec Onglets)', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.darkGreen, foregroundColor: AppTheme.gold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Filtre
                Row(
                  children: [
                    const Text('Période :', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 16),
                    DropdownButton<ReportPeriod>(
                      value: _period,
                      items: const [
                        DropdownMenuItem(value: ReportPeriod.today, child: Text("Aujourd'hui")),
                        DropdownMenuItem(value: ReportPeriod.week, child: Text("Cette Semaine")),
                        DropdownMenuItem(value: ReportPeriod.month, child: Text("Ce Mois")),
                        DropdownMenuItem(value: ReportPeriod.year, child: Text("Cette Année")),
                        DropdownMenuItem(value: ReportPeriod.all, child: Text("Tout le temps")),
                      ],
                      onChanged: (p) {
                        if (p != null) setState(() => _period = p);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                const Text('Ventes Finalisées (Sur la période)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkGreen)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(width: 300, child: _buildMetricCard(
                      'Ventes Comptant', totalVentesComptant, Icons.receipt, AppTheme.darkGreen,
                      onTap: () => _showBillsListDialog(context, filteredBills, 'Ventes Comptant'),
                    )),
                    SizedBox(width: 300, child: _buildMetricCard(
                      'Prêts Soldés', totalPretsSoldes, Icons.check_circle, Colors.teal,
                      onTap: () => _showDebtsListDialog(context, filteredSoldOutLoans, loansP, 'Prêts Soldés (Récupérés)'),
                    )),
                    SizedBox(width: 300, child: _buildMetricCard('TOTAL VENDU', grandTotalVendu, Icons.monetization_on, AppTheme.gold, isHuge: true)),
                  ],
                ),
                const SizedBox(height: 48),

                const Text('Surveillance des Prêts (Global / Tout le temps)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkGreen)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(width: 300, child: _buildMetricCard(
                      'Total Prêts en cours', totalPendingAmount, Icons.credit_card, Colors.orange.shade700,
                      onTap: () => _showDebtsListDialog(context, pendingLoans, loansP, 'Prêts en Cours'),
                    )),
                    SizedBox(width: 300, child: _buildMetricCard(
                      'Total Restant à Payer', totalRemainingPending, Icons.warning_amber_rounded, AppTheme.error,
                      onTap: () => _showDebtsListDialog(context, pendingLoans, loansP, 'Prêts en Cours'),
                    )),
                  ],
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateBillScreen(defaultToLoan: false)),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle Facture / Prêt'),
            backgroundColor: AppTheme.gold,
            foregroundColor: AppTheme.darkGreen,
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String title, double value, IconData icon, Color color, {bool isHuge = false, VoidCallback? onTap}) {
    final card = Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: isHuge ? AppTheme.darkGreen : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightGrey),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: isHuge ? AppTheme.gold : color, size: isHuge ? 40 : 28),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: TextStyle(color: isHuge ? Colors.white70 : Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('${value.toStringAsFixed(2)} MAD', style: TextStyle(color: isHuge ? AppTheme.gold : color, fontSize: isHuge ? 26 : 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: card,
    );
  }

  void _showBillsListDialog(BuildContext context, List<BillModel> bills, String title) {
    DateTimeRange? range;
    if (_period != ReportPeriod.all) {
      final now = DateTime.now();
      if (_period == ReportPeriod.today) {
        range = DateTimeRange(start: DateTime(now.year, now.month, now.day), end: now);
      } else if (_period == ReportPeriod.week) {
        range = DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
      } else if (_period == ReportPeriod.month) {
        range = DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
      } else if (_period == ReportPeriod.year) {
        range = DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
      }
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => BillsHistoryScreen(initialDateRange: range)));
  }

  void _showDebtsListDialog(BuildContext context, List<DebtModel> debts, LoansProvider loansP, String title) {
    DateTimeRange? range;
    String status = 'all';
    
    if (title.contains('Cours')) {
      status = 'pending';
    } else if (title.contains('Soldés')) {
      status = 'settled';
      if (_period != ReportPeriod.all) {
        final now = DateTime.now();
        if (_period == ReportPeriod.today) {
          range = DateTimeRange(start: DateTime(now.year, now.month, now.day), end: now);
        } else if (_period == ReportPeriod.week) {
          range = DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
        } else if (_period == ReportPeriod.month) {
          range = DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
        } else if (_period == ReportPeriod.year) {
          range = DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
        }
      }
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => LoansListScreen(
      initialStatusFilter: status,
      initialDateRange: range,
    )));
  }
}
