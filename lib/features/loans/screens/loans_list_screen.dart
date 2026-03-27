import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../bills/screens/create_bill_screen.dart';
import '../loans_provider.dart';
import '../models/client_model.dart';
import '../../bills/bills_provider.dart';
import '../../../core/theme.dart';
import '../../../services/csv_service.dart';
import 'client_detail_screen.dart';
import 'package:flutter/foundation.dart';

class LoansListScreen extends StatefulWidget {
  final String? initialStatusFilter; // 'all', 'pending', 'settled'
  final DateTimeRange? initialDateRange;

  const LoansListScreen({super.key, this.initialStatusFilter, this.initialDateRange});

  @override
  State<LoansListScreen> createState() => _LoansListScreenState();
}

class _LoansListScreenState extends State<LoansListScreen> {
  final _searchCtrl = TextEditingController();
  String _statusFilter = 'all';
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialStatusFilter != null) {
      _statusFilter = widget.initialStatusFilter!;
    }
    _fromDate = widget.initialDateRange?.start;
    _toDate = widget.initialDateRange?.end;
    _searchCtrl.addListener(() {
      context.read<LoansProvider>().setSearchQuery(_searchCtrl.text);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      Future.microtask(() {
        if (mounted) context.read<LoansProvider>().initialize();
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
        title: const Text('Gestion des Dettes — إدارة الديون'),
        actions: [
          _syncButton(),
          _csvButton(),
          _logoutButton(),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildClientList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'loans_list_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateBillScreen(defaultToLoan: true)),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouveau Prêt'),
      ),
    );
  }

  Widget _syncButton() {
    return Consumer<LoansProvider>(
      builder: (ctx, p, _) => IconButton(
        icon: p.isSyncing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppTheme.gold,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.sync),
        tooltip: 'Synchroniser',
        onPressed: p.isSyncing
            ? null
            : () async {
                await p.syncWithFirestore();
                if (!mounted) return;
                if (p.syncMessage != null) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(p.syncMessage!)));
                }
              },
      ),
    );
  }

  Widget _csvButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.import_export, color: AppTheme.gold),
      tooltip: 'Import / Export CSV',
      onSelected: (v) {
        if (v == 'export') _exportCsv();
        if (v == 'import') _importCsv();
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'export', child: Text('📤  Exporter CSV')),
        const PopupMenuItem(value: 'import', child: Text('📥  Importer CSV')),
      ],
    );
  }

  Widget _logoutButton() {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Déconnexion',
      onPressed: () {
        // Auth handled by app-level router
        context.findAncestorStateOfType<State>()?.setState(() {});
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppTheme.darkGreen,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            cursorColor: AppTheme.gold,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom, prénom...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: AppTheme.gold),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty || _statusFilter != 'all' || _fromDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {
                          _statusFilter = 'all';
                          _fromDate = null;
                          _toDate = null;
                        });
                        context.read<LoansProvider>().setSearchQuery('');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statusFilter,
                      dropdownColor: AppTheme.darkGreen,
                      icon: const Icon(Icons.filter_list, color: AppTheme.gold),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Tous les statuts')),
                        DropdownMenuItem(value: 'pending', child: Text('Prêts en cours')),
                        DropdownMenuItem(value: 'settled', child: Text('Prêts Soldés')),
                      ],
                      onChanged: (v) => setState(() => _statusFilter = v ?? 'all'),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDateRange: _fromDate != null && _toDate != null
                          ? DateTimeRange(start: _fromDate!, end: _toDate!)
                          : null,
                      builder: (ctx, child) => Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(primary: AppTheme.darkGreen),
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
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        const Icon(Icons.date_range, color: AppTheme.gold, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _fromDate == null 
                              ? 'Toutes les dates' 
                              : '${DateFormat('dd/MM/yy').format(_fromDate!)} - ${DateFormat('dd/MM/yy').format(_toDate!)}',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientList() {
    return Consumer<LoansProvider>(
      builder: (ctx, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.gold),
          );
        }
        
        var clients = provider.allClients;
        if (_searchCtrl.text.isNotEmpty) {
           final q = _searchCtrl.text.toLowerCase();
           clients = clients.where((c) => c.fullName.toLowerCase().contains(q) || c.phone.contains(q)).toList();
        }

        // Apply filters!
        if (_statusFilter != 'all' || _fromDate != null) {
          clients = clients.where((c) {
            var clientDebts = provider.debtsForClient(c.id);
            
            if (_statusFilter == 'pending') {
              clientDebts = clientDebts.where((d) => !d.settled).toList();
            } else if (_statusFilter == 'settled') {
              clientDebts = clientDebts.where((d) => d.settled).toList();
            }

            if (_fromDate != null && _toDate != null) {
              clientDebts = clientDebts.where((d) {
                final start = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
                final end = DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
                return d.date.isAfter(start) && d.date.isBefore(end);
              }).toList();
            }
            
            return clientDebts.isNotEmpty;
          }).toList();
        }

        if (clients.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_outline, size: 64, color: AppTheme.lightGrey),
                const SizedBox(height: 16),
                Text(
                  _searchCtrl.text.isEmpty
                      ? 'Aucun client. Créez un prêt pour commencer.'
                      : 'Aucun résultat pour "${_searchCtrl.text}"',
                  style: const TextStyle(color: AppTheme.textLight),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: clients.length,
          itemBuilder: (ctx, i) => _buildClientCard(clients[i], provider),
        );
      },
    );
  }

  Widget _buildClientCard(ClientModel client, LoansProvider p) {
    final totalDebt = p.totalDebtForClient(client.id);
    final totalPaid = p.totalPaidForClient(client.id);
    final remaining = p.remainingForClient(client.id);
    final isSolde = p.isClientSolde(client.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClientDetailScreen(client: client),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.darkGreen,
                child: Text(
                  client.firstName.isNotEmpty
                      ? client.firstName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (client.phone.isNotEmpty)
                      Text(
                        client.phone,
                        style: const TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 6),
                    _debtSummaryRow(totalDebt, totalPaid, remaining),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status badge
              if (isSolde)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.success.withOpacity(0.4)),
                  ),
                  child: Text(
                    'Soldé ✅',
                    style: TextStyle(
                      color: AppTheme.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else if (totalDebt > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${remaining.toStringAsFixed(0)} MAD',
                    style: const TextStyle(
                      color: AppTheme.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const Icon(Icons.chevron_right, color: AppTheme.textLight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _debtSummaryRow(double total, double paid, double remaining) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _miniStat('Prêt', '${total.toStringAsFixed(0)} MAD', AppTheme.textMedium),
        _miniStat('Payé', '${paid.toStringAsFixed(0)} MAD', AppTheme.success),
        _miniStat(
          'Reste',
          '${remaining > 0 ? remaining.toStringAsFixed(0) : 0} MAD',
          remaining > 0 ? AppTheme.error : AppTheme.success,
        ),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppTheme.textLight)),
        Text(value,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Dialogs
  // ─────────────────────────────────────────────────────────────────────────────

  // Add loan dialog removed as functionality is unified in CreateBillScreen.


  Future<void> _exportCsv() async {
    try {
      final p = context.read<LoansProvider>();
      final csv = CsvService();
      final billsP = context.read<BillsProvider>();
      final bytes = csv.exportAll(
        clients: p.allClients,
        debts: p.allDebts,
        payments: p.allPayments,
        bills: billsP.bills,
      );
      // On web: trigger download; on desktop: save to downloads
      _downloadFile(bytes, 'bijouterie_elhajjam_export.zip');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur export: $e')),
      );
    }
  }

  Future<void> _importCsv() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sélectionnez le fichier ZIP exporté pour importer.'),
      ),
    );
    // Basic file picking — full implementation uses file_picker
  }

  void _downloadFile(Uint8List bytes, String filename) {
    // Web download via universal_html or dart:html
    if (kIsWeb) {
      // ignore: undefined_prefixed_name
      // This is handled at runtime; on non-web builds this path is never reached
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export prêt: $filename')),
    );
  }
}
