import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../bills_provider.dart';
import '../models/bill_model.dart';
import '../models/jewelry_type_model.dart';
import '../../loans/loans_provider.dart';
import '../../loans/widgets/client_typeahead.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../pdf_generator.dart';
import 'package:printing/printing.dart';

class CreateBillScreen extends StatefulWidget {
  final bool defaultToLoan;
  const CreateBillScreen({super.key, this.defaultToLoan = false});

  @override
  State<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends State<CreateBillScreen> {
  final _clientCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();

  late bool _isLoanMode;
  final _avanceCtrl = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _isLoanMode = widget.defaultToLoan;
    Future.microtask(() {
      if (mounted) context.read<BillsProvider>().resetDraft();
    });
  }

  @override
  void dispose() {
    _clientCtrl.dispose();
    _phoneCtrl.dispose();
    _avanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Facture — فاتورة جديدة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Already accessible via main shell tab
            },
          ),
        ],
      ),
      body: Consumer<BillsProvider>(
        builder: (ctx, billsP, _) {
          final loansP = context.read<LoansProvider>();
          return Form(
            key: _formKey,
            child: Column(
              children: [
                _buildHeader(billsP, loansP),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildItemsTable(billsP),
                  ),
                ),
                _buildFooter(billsP),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BillsProvider billsP, LoansProvider loansP) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.lightGrey)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ClientTypeahead(
                  controller: _clientCtrl,
                  clients: loansP.allClients,
                  labelText: 'Nom du client / اسم الزبون',
                  onClientSelected: (c) {
                    _clientCtrl.text = c.fullName;
                    _phoneCtrl.text = c.phone;
                    billsP.setDraftClientName(c.fullName);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone (interne)',
                    prefixIcon: Icon(Icons.phone, color: AppTheme.gold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      prefixIcon: Icon(Icons.calendar_today, color: AppTheme.gold),
                    ),
                    child: Text(
                        DateFormat('dd/MM/yyyy').format(_selectedDate)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ville',
                    prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.gold),
                  ),
                  child:
                      const Text('Boujaad', style: TextStyle(color: AppTheme.textMedium)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable(BillsProvider billsP) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Lignes d\'articles — أصناف البضاعة',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppTheme.darkGreen),
            ),
            TextButton.icon(
              onPressed: billsP.draftItems.length < AppConstants.maxBillRows
                  ? billsP.addDraftItem
                  : null,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Ajouter ligne'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Column headers
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.darkGreen,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: const [
              _ColHeader('العدد', flex: 1),
              _ColHeader('نوع المجوهرات', flex: 3),
              _ColHeader('العيار', flex: 1),
              _ColHeader('الميزان (g)', flex: 2),
              _ColHeader('السعر/g', flex: 2),
              _ColHeader('الثمن', flex: 2),
              SizedBox(width: 32),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ...billsP.draftItems.asMap().entries.map(
          (entry) => _BillItemRow(
            key: ValueKey('${billsP.draftId}-item-${entry.key}'),
            index: entry.key,
            item: entry.value,
            jewelryTypes: billsP.jewelryTypes,
            onChanged: (updated) => billsP.updateDraftItem(entry.key, updated),
            onDelete: billsP.draftItems.length > 1
                ? () => billsP.removeDraftItem(entry.key)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BillsProvider billsP) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.lightGrey)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Total box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.darkGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'المجموع الإجمالي — Total',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                Text(
                  '${billsP.draftTotal.toStringAsFixed(2)} MAD',
                  style: const TextStyle(
                    color: AppTheme.gold,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Facture Comptant'), icon: Icon(Icons.receipt)),
              ButtonSegment(value: true, label: Text('Paiement à Crédit (Prêt)'), icon: Icon(Icons.credit_card)),
            ],
            selected: <bool>{_isLoanMode},
            onSelectionChanged: (Set<bool> newSelection) {
              setState(() => _isLoanMode = newSelection.first);
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppTheme.gold.withOpacity(0.2);
                }
                return Colors.transparent;
              }),
            ),
          ),
          if (_isLoanMode) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _avanceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Avance payée aujourd\'hui (MAD)',
                prefixIcon: Icon(Icons.payment, color: AppTheme.gold),
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: (billsP.draftTotal <= 0)
                ? null
                : () => _finalizeTransaction(billsP),
            icon: Icon(_isLoanMode ? Icons.save : Icons.check_circle),
            label: Text(_isLoanMode ? 'Créer le Prêt' : 'Valider & Imprimer', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.darkGreen,
              foregroundColor: AppTheme.gold,
              padding: const EdgeInsets.symmetric(vertical: 16),
              disabledBackgroundColor: AppTheme.lightGrey.withOpacity(0.5),
              disabledForegroundColor: AppTheme.textMedium,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finalizeTransaction(BillsProvider billsP) async {
    if (_clientCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer le nom du client.')),
      );
      return;
    }
    
    if (billsP.draftItems.every((i) => i.jewelryType.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter au moins un article.')),
      );
      return;
    }

    final clientName = _clientCtrl.text.trim();
    billsP.setDraftClientName(clientName);
    billsP.setDraftDate(_selectedDate);
    
    // 1. Create client inline if new
    final loansP = context.read<LoansProvider>();
    final parts = clientName.split(' ');
    final firstName = parts.isNotEmpty ? parts.first : 'Client';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final client = await loansP.findOrCreateClient(
      firstName: firstName, 
      lastName: lastName,
      phone: _phoneCtrl.text.trim(),
    );

    if (_isLoanMode) {
      final avance = double.tryParse(_avanceCtrl.text.replaceAll(',', '.')) ?? 0.0;
      final newDebt = await loansP.addDebt(
        clientId: client.id,
        amount: billsP.draftTotal,
        date: _selectedDate,
        items: billsP.draftItems,
      );
      
      if (avance > 0) {
        await loansP.addPayment(
          debtId: newDebt.id,
          clientId: client.id,
          amount: avance,
          date: _selectedDate,
          notes: 'Avance initiale',
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nouveau Prêt enregistré avec succès ✅')),
      );
      billsP.resetDraft(); // explicit clearance of form data
    } else {
      // Core Bill sequence
      final bill = await billsP.saveBill();
      if (!mounted) return;
      
      final shortId = bill.id.length >= 8 ? bill.id.substring(0, 8) : bill.id;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Facture sauvegardée ✅ (N° $shortId)')),
      );

      final pdfData = await BillPdfGenerator.generate(bill);
      await Printing.layoutPdf(
        onLayout: (_) async => pdfData,
        name: 'Facture_${clientName}_${DateFormat('ddMMyyyy').format(_selectedDate)}',
      );
    }

    _clientCtrl.clear();
    _phoneCtrl.clear();
    _avanceCtrl.text = '0';
  }
}

// ─── Helper widgets ──────────────────────────────────────────────────────────

class _ColHeader extends StatelessWidget {
  final String text;
  final int flex;

  const _ColHeader(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.gold,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BillItemRow extends StatefulWidget {
  final int index;
  final BillItemModel item;
  final List<JewelryTypeModel> jewelryTypes;
  final ValueChanged<BillItemModel> onChanged;
  final VoidCallback? onDelete;

  const _BillItemRow({
    super.key,
    required this.index,
    required this.item,
    required this.jewelryTypes,
    required this.onChanged,
    this.onDelete,
  });

  @override
  State<_BillItemRow> createState() => _BillItemRowState();
}

class _BillItemRowState extends State<_BillItemRow> {
  late TextEditingController _qtyCtrl;
  late TextEditingController _typeCtrl;
  late TextEditingController _karatCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(
        text: widget.item.quantity > 0 ? '${widget.item.quantity}' : '');
    _typeCtrl = TextEditingController(text: widget.item.jewelryType);
    _karatCtrl = TextEditingController(text: widget.item.karat);
    _weightCtrl = TextEditingController(
        text: widget.item.weight > 0 ? '${widget.item.weight}' : '');
    _priceCtrl = TextEditingController(
        text: widget.item.pricePerGram > 0 ? '${widget.item.pricePerGram}' : '');
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _typeCtrl.dispose();
    _karatCtrl.dispose();
    _weightCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged(BillItemModel(
      quantity: int.tryParse(_qtyCtrl.text) ?? 1,
      jewelryType: _typeCtrl.text,
      karat: _karatCtrl.text,
      weight: double.tryParse(_weightCtrl.text) ?? 0.0,
      pricePerGram: double.tryParse(_priceCtrl.text) ?? 0.0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final total = (double.tryParse(_weightCtrl.text) ?? 0.0) *
        (double.tryParse(_priceCtrl.text) ?? 0.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: widget.index.isEven ? AppTheme.offWhite : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.lightGrey),
      ),
      child: Row(
        children: [
          // Qty
          Expanded(
            flex: 1,
            child: TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                isDense: true, border: InputBorder.none, hintText: '1',
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (_) => _notify(),
            ),
          ),
          // Jewelry type typeahead (v4 API)
          Expanded(
            flex: 3,
            child: TypeAheadFormField<JewelryTypeModel>(
              textFieldConfiguration: TextFieldConfiguration(
                controller: _typeCtrl,
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Type de bijou…',
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (_) => _notify(),
              ),
              suggestionsCallback: (pattern) {
                if (pattern.isEmpty) return widget.jewelryTypes.take(8).toList();
                final q = pattern.toLowerCase();
                return widget.jewelryTypes
                    .where((jt) =>
                        jt.name.toLowerCase().contains(q) ||
                        jt.nameAr.contains(pattern))
                    .take(6)
                    .toList();
              },
              itemBuilder: (ctx, jt) => ListTile(
                dense: true,
                title: Text('${jt.name} — ${jt.nameAr}',
                    style: const TextStyle(fontSize: 13)),
                subtitle: Text('${jt.defaultWeight}g',
                    style: const TextStyle(fontSize: 11)),
              ),
              onSuggestionSelected: (jt) {
                _typeCtrl.text = '${jt.name} - ${jt.nameAr}';
                if (_weightCtrl.text.isEmpty || _weightCtrl.text == '0') {
                  _weightCtrl.text = '${jt.defaultWeight}';
                }
                if (_karatCtrl.text.isEmpty || _karatCtrl.text == '18') {
                  _karatCtrl.text = jt.defaultKarat;
                }
                if (_priceCtrl.text.isEmpty || _priceCtrl.text == '0') {
                  if (jt.defaultPrice > 0) {
                    final w = double.tryParse(_weightCtrl.text) ?? 0.0;
                    if (w > 0) {
                      _priceCtrl.text = (jt.defaultPrice / w).toStringAsFixed(2);
                    } else {
                      _priceCtrl.text = '${jt.defaultPrice}';
                    }
                  }
                }
                _notify();
              },
              hideOnEmpty: true,
              suggestionsBoxDecoration: SuggestionsBoxDecoration(
                elevation: 2,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // Karat
          Expanded(
            flex: 1,
            child: TextField(
              controller: _karatCtrl,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                isDense: true, border: InputBorder.none, hintText: '18',
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (_) => _notify(),
            ),
          ),
          // Weight
          Expanded(
            flex: 2,
            child: TextField(
              controller: _weightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                isDense: true, border: InputBorder.none, hintText: '0.00',
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (_) {
                _notify();
                setState(() {});
              },
            ),
          ),
          // Price/g
          Expanded(
            flex: 2,
            child: TextField(
              controller: _priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                isDense: true, border: InputBorder.none, hintText: '0.00',
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (_) {
                _notify();
                setState(() {});
              },
            ),
          ),
          // Total (auto)
          Expanded(
            flex: 2,
            child: Text(
              total.toStringAsFixed(2),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkGreen,
                  fontSize: 13),
            ),
          ),
          // Delete
          SizedBox(
            width: 32,
            child: widget.onDelete != null
                ? IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        size: 18, color: AppTheme.error),
                    onPressed: widget.onDelete,
                    padding: EdgeInsets.zero,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
