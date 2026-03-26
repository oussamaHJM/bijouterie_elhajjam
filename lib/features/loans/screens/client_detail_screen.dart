import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../loans_provider.dart';
import '../models/client_model.dart';
import '../models/debt_model.dart';
import '../models/payment_model.dart';
import '../../bills/bills_provider.dart';
import '../../bills/models/bill_model.dart';
import '../../bills/screens/edit_bill_screen.dart';
import '../../bills/screens/create_bill_screen.dart';
import '../../bills/pdf_generator.dart';
import 'package:printing/printing.dart';
import '../../../core/constants.dart';
import '../../../core/theme.dart';

class ClientDetailScreen extends StatelessWidget {
  final ClientModel client;

  const ClientDetailScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LoansProvider, BillsProvider>(
      builder: (ctx, p, billsP, _) {
        final debts = p.debtsForClient(client.id);
        final clientBills = billsP.searchBills(clientName: client.fullName);
        final totalDebt = p.totalDebtForClient(client.id);
        final totalPaid = p.totalPaidForClient(client.id);
        final remaining = p.remainingForClient(client.id);
        final isSolde = remaining <= 0 && totalDebt > 0;

        return Scaffold(
          appBar: AppBar(
            title: Text(client.fullName),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Modifier',
                onPressed: () => _promptEditClient(context, client, p),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Supprimer',
                onPressed: () => _promptDeleteClient(context, client, p),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context, client, totalDebt, totalPaid, remaining,
                    isSolde, p),
                const SizedBox(height: 12),
                if (debts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Aucun prêt enregistré.',
                        style: TextStyle(color: AppTheme.textLight),
                      ),
                    ),
                  )
                else
                  ...debts.map((d) => _buildDebtCard(context, d, p)),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Achats / Factures',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppTheme.darkGreen)),
                  ),
                ),
                const SizedBox(height: 12),
                if (clientBills.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('Aucune facture trouvée.',
                          style: TextStyle(color: AppTheme.textLight)),
                    ),
                  )
                else
                  ...clientBills.map((b) => _buildBillCard(context, b)),
                const SizedBox(height: 80),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'client_detail_fab',
            onPressed: () => _showAddDebtOrPaymentMenu(context, p, debts),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ClientModel client,
    double total,
    double paid,
    double remaining,
    bool isSolde,
    LoansProvider p,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.greenGradientDecoration,
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 36,
            backgroundColor: AppTheme.gold,
            child: Text(
              client.firstName.isNotEmpty
                  ? client.firstName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: AppTheme.darkGreen,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            client.fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (client.phone.isNotEmpty)
            Text(
              client.phone,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          const SizedBox(height: 20),
          // Summary cards
          Row(
            children: [
              _summaryCard('Total Prêt', total, AppTheme.gold),
              const SizedBox(width: 8),
              _summaryCard('Payé', paid, AppTheme.success),
              const SizedBox(width: 8),
              _summaryCard(
                'Reste',
                remaining > 0 ? remaining : 0,
                remaining > 0 ? const Color(0xFFFF7070) : AppTheme.success,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Sold status
          if (isSolde)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppTheme.success.withOpacity(0.5)),
              ),
              child: const Text(
                '✅ Compte Soldé — الحساب مسدد',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              '${amount.toStringAsFixed(0)} MAD',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtCard(BuildContext context, DebtModel debt, LoansProvider p) {
    final payments = p.paymentsForDebt(debt.id);
    final remaining = p.remainingForDebt(debt.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(
            debt.settled ? Icons.check_circle : Icons.pending_outlined,
            color: debt.settled ? AppTheme.success : AppTheme.warning,
          ),
          title: Text(
            '${debt.amount.toStringAsFixed(0)} MAD',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          subtitle: Text(
            DateFormat('dd/MM/yyyy').format(debt.date),
            style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
          ),
          trailing: debt.settled
              ? const Text(
                  'Soldé ✅',
                  style: TextStyle(
                      color: AppTheme.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                )
              : Text(
                  'Reste: ${remaining.toStringAsFixed(0)} MAD',
                  style: const TextStyle(
                      color: AppTheme.error,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (debt.notes != null && debt.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Notes: ${debt.notes}',
                        style: const TextStyle(
                            color: AppTheme.textMedium, fontSize: 13),
                      ),
                    ),
                  if (payments.isEmpty)
                    const Text('Aucun paiement.',
                        style: TextStyle(color: AppTheme.textLight))
                  else
                    ...payments.map((py) => _paymentRow(py)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (remaining > 0)
                        OutlinedButton.icon(
                          onPressed: () =>
                              _showAddPaymentDialog(context, debt, p),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Paiement'),
                        ),
                      const SizedBox(width: 8),
                      if (!debt.settled && remaining <= 0)
                        ElevatedButton.icon(
                          onPressed: () async {
                            await p.markDebtSettled(debt.id, true);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Marqué comme soldé ✅')),
                              );
                            }
                          },
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Marquer Soldé'),
                        ),
                      if (debt.settled && debt.items.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () async {
                            final transientBill = BillModel(
                              id: debt.id,
                              clientName: client.fullName,
                              city: AppConstants.city,
                              date: debt.date,
                              items: debt.items,
                              total: debt.amount,
                              isDirty: false,
                            );
                            final pdfData = await BillPdfGenerator.generate(transientBill);
                            await Printing.layoutPdf(
                              onLayout: (_) async => pdfData,
                              name: 'Facture_Pret_${client.fullName}_${DateFormat('ddMMyyyy').format(debt.date)}',
                            );
                          },
                          icon: const Icon(Icons.print, size: 16),
                          label: const Text('Imprimer', style: TextStyle(fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.darkGreen,
                            foregroundColor: AppTheme.gold,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentRow(PaymentModel p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.arrow_upward, size: 14, color: AppTheme.success),
          const SizedBox(width: 6),
          Text(
            '${p.amount.toStringAsFixed(0)} MAD',
            style: const TextStyle(
                color: AppTheme.success, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('dd/MM/yyyy').format(p.date),
                style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
              ),
              if (p.notes != null && p.notes!.isNotEmpty)
                Text(
                  p.notes!,
                  style: const TextStyle(
                      color: AppTheme.textMedium,
                      fontSize: 11,
                      fontStyle: FontStyle.italic),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddDebtOrPaymentMenu(
      BuildContext context, LoansProvider p, List<DebtModel> debts) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.add_card, color: AppTheme.gold),
            title: const Text('Nouveau Prêt'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateBillScreen(defaultToLoan: true)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment, color: AppTheme.success),
            title: const Text('Ajouter un Paiement'),
            enabled: debts.any((d) => p.remainingForDebt(d.id) > 0),
            onTap: !debts.any((d) => p.remainingForDebt(d.id) > 0)
                ? null
                : () {
                    Navigator.pop(context);
                    final activeList = debts.where((d) => p.remainingForDebt(d.id) > 0).toList();
                    _showAddPaymentDialog(context, activeList.first, p);
                  },
          ),
        ],
      ),
    );
  }

  void _showAddDebtDialog(BuildContext context, LoansProvider p) {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Nouveau Prêt'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Montant (MAD)',
                    prefixIcon: Icon(Icons.attach_money, color: AppTheme.gold),
                    suffixText: 'MAD',
                  ),
                  validator: (v) => (v == null || double.tryParse(v) == null)
                      ? 'Montant invalide'
                      : null,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) setState(() => selectedDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date'),
                    child: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await p.addDebt(
                  clientId: client.id,
                  amount: double.parse(amountCtrl.text),
                  date: selectedDate,
                  notes: notesCtrl.text.trim().isEmpty
                      ? null
                      : notesCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPaymentDialog(
      BuildContext context, DebtModel debt, LoansProvider p) {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Ajouter un Paiement'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Prêt: ${debt.amount.toStringAsFixed(0)} MAD\n'
                  'Reste: ${p.remainingForDebt(debt.id).toStringAsFixed(0)} MAD',
                  style: const TextStyle(color: AppTheme.textMedium),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Montant payé (MAD)',
                    prefixIcon: Icon(Icons.payment, color: AppTheme.success),
                    suffixText: 'MAD',
                  ),
                  validator: (v) {
                    if (v == null || double.tryParse(v) == null) {
                      return 'Montant invalide';
                    }
                    final val = double.parse(v);
                    if (val <= 0) return 'Montant > 0';
                    final remaining = p.remainingForDebt(debt.id);
                    if (val > remaining) {
                      return 'Maximum: ${remaining.toStringAsFixed(0)} MAD';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) setState(() => selectedDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date'),
                    child: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Note (optionnelle)',
                      prefixIcon: Icon(Icons.note, color: AppTheme.gold)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await p.addPayment(
                  debtId: debt.id,
                  clientId: client.id,
                  amount: double.parse(amountCtrl.text),
                  date: selectedDate,
                  notes: notesCtrl.text.trim().isEmpty
                      ? null
                      : notesCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillCard(BuildContext context, BillModel bill) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppTheme.offWhite,
          child: Icon(Icons.receipt_long, color: AppTheme.gold),
        ),
        title: Text('${bill.total.toStringAsFixed(2)} MAD',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(DateFormat('dd/MM/yyyy • HH:mm').format(bill.date),
            style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => EditBillScreen(initialBill: bill)));
        },
      ),
    );
  }

  void _promptEditClient(
      BuildContext context, ClientModel client, LoansProvider p) {
    final firstCtrl = TextEditingController(text: client.firstName);
    final lastCtrl = TextEditingController(text: client.lastName);
    final phoneCtrl = TextEditingController(text: client.phone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier le client'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: firstCtrl,
                decoration: const InputDecoration(labelText: 'Prénom')),
            const SizedBox(height: 8),
            TextField(
                controller: lastCtrl,
                decoration: const InputDecoration(labelText: 'Nom')),
            const SizedBox(height: 8),
            TextField(
                controller: phoneCtrl,
                decoration:
                    const InputDecoration(labelText: 'Téléphone (Optionnel)')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (firstCtrl.text.trim().isNotEmpty &&
                  lastCtrl.text.trim().isNotEmpty) {
                p.updateClient(client.id, firstCtrl.text.trim(),
                    lastCtrl.text.trim(), phoneCtrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _promptDeleteClient(
      BuildContext context, ClientModel client, LoansProvider p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le client',
            style: TextStyle(color: AppTheme.error)),
        content: Text(
            'Voulez-vous vraiment supprimer ${client.fullName} ?\n\nAttention : Cela supprimera son profil de l\'annuaire général.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () {
              p.deleteClient(client.id);
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close detail screen
            },
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
