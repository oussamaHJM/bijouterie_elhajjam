import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../bills_provider.dart';
import '../models/bill_model.dart';
import '../../../core/theme.dart';
import '../pdf_generator.dart';
import 'package:printing/printing.dart';
import 'create_bill_screen.dart';
import 'edit_bill_screen.dart';

class BillsHistoryScreen extends StatefulWidget {
  final DateTimeRange? initialDateRange;
  const BillsHistoryScreen({super.key, this.initialDateRange});

  @override
  State<BillsHistoryScreen> createState() => _BillsHistoryScreenState();
}

class _BillsHistoryScreenState extends State<BillsHistoryScreen> {
  final _searchCtrl = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _fromDate = widget.initialDateRange?.start;
    _toDate = widget.initialDateRange?.end;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      Future.microtask(() {
        if (mounted) context.read<BillsProvider>().initialize();
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(fit: BoxFit.scaleDown, child: Text('Factures — الفواتير')),
        actions: [
          Consumer<BillsProvider>(
            builder: (ctx, p, _) => IconButton(
              icon: p.isSyncing
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: AppTheme.gold, strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              tooltip: 'Synchroniser',
              onPressed: () async {
                await p.syncWithFirestore();
                if (!mounted) return;
                if (p.syncMessage != null) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(p.syncMessage!)));
                }
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(child: _buildBillsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateBillScreen()));
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle Facture'),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      color: AppTheme.darkGreen,
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            cursorColor: AppTheme.gold,
            decoration: InputDecoration(
              hintText: 'Rechercher par client ou référence...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: AppTheme.gold),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.date_range, color: Colors.white54),
                onPressed: _pickDateRange,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_fromDate != null || _toDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Chip(
                    backgroundColor: AppTheme.gold.withOpacity(0.2),
                    label: Text(
                      '${_fromDate != null ? DateFormat('dd/MM/yy').format(_fromDate!) : '…'}'
                      ' → ${_toDate != null ? DateFormat('dd/MM/yy').format(_toDate!) : '…'}',
                      style: const TextStyle(color: AppTheme.gold, fontSize: 12),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 14, color: AppTheme.gold),
                    onDeleted: () => setState(() { _fromDate = null; _toDate = null; }),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBillsList() {
    return Consumer<BillsProvider>(
      builder: (ctx, p, _) {
        if (p.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
        }
        final bills = p.searchBills(
          clientName: _searchCtrl.text,
          from: _fromDate,
          to: _toDate,
        );
        if (bills.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.lightGrey),
                SizedBox(height: 16),
                Text('Aucune facture trouvée.', style: TextStyle(color: AppTheme.textLight)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: bills.length,
          itemBuilder: (ctx, i) => _buildBillCard(bills[i]),
        );
      },
    );
  }

  Widget _buildBillCard(BillModel bill) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => EditBillScreen(initialBill: bill)));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.darkGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt, color: AppTheme.gold, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.clientName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    Text(
                      '${DateFormat('dd/MM/yyyy').format(bill.date)}  •  ${bill.city}',
                      style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
                    ),
                    Text(
                      '${bill.items.length} article(s)',
                      style: const TextStyle(color: AppTheme.textMedium, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${bill.total.toStringAsFixed(2)} MAD',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppTheme.darkGreen,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.print_outlined, color: AppTheme.gold),
                    onPressed: () => _printBill(bill),
                    tooltip: 'Réimprimer',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _printBill(BillModel bill) async {
    final pdfData = await BillPdfGenerator.generate(bill);
    await Printing.layoutPdf(
      onLayout: (_) async => pdfData,
      name: 'Facture_${bill.clientName}_${DateFormat('ddMMyyyy').format(bill.date)}',
    );
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.darkGreen,
            secondary: AppTheme.gold,
          ),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() {
        _fromDate = range.start;
        _toDate = range.end;
      });
    }
  }
}
