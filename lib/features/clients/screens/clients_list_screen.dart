import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../loans/loans_provider.dart';
import '../../bills/bills_provider.dart';
import '../../loans/models/client_model.dart';
import '../../loans/screens/client_detail_screen.dart';
import '../../../core/theme.dart';

class ClientsListScreen extends StatefulWidget {
  const ClientsListScreen({super.key});

  @override
  State<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends State<ClientsListScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Clients — إدارة الزبائن'),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildClientList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppTheme.darkGreen,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white),
        cursorColor: AppTheme.gold,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Rechercher un client...',
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: const Icon(Icons.search, color: AppTheme.gold),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildClientList() {
    return Consumer2<LoansProvider, BillsProvider>(
      builder: (ctx, loansP, billsP, _) {
        if (loansP.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
        }

        var clients = loansP.allClients;
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          clients = clients.where((c) => 
            c.firstName.toLowerCase().contains(q) ||
            c.lastName.toLowerCase().contains(q) ||
            c.phone.toLowerCase().contains(q)
          ).toList();
        }

        if (clients.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_outline, size: 64, color: AppTheme.lightGrey),
                const SizedBox(height: 16),
                const Text('Aucun client trouvé', style: TextStyle(color: AppTheme.textLight)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: clients.length,
          itemBuilder: (ctx, i) => _buildClientCard(clients[i], loansP, billsP),
        );
      },
    );
  }

  Widget _buildClientCard(ClientModel client, LoansProvider loansP, BillsProvider billsP) {
    final clientBills = billsP.searchBills(clientName: client.fullName);
    final totalSpent = clientBills.fold(0.0, (sum, b) => sum + b.total);
    final totalDebt = loansP.totalDebtForClient(client.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ClientDetailScreen(client: client)),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.darkGreen,
                child: Text(
                  client.firstName.isNotEmpty ? client.firstName[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w700, fontSize: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    if (client.phone.isNotEmpty) Text(client.phone, style: const TextStyle(color: AppTheme.textLight, fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _miniStat('Total Achats', '${totalSpent.toStringAsFixed(0)} MAD', AppTheme.success),
                        const SizedBox(width: 16),
                        _miniStat('Dettes', '${totalDebt.toStringAsFixed(0)} MAD', totalDebt > 0 ? AppTheme.error : AppTheme.textMedium),
                        const SizedBox(width: 16),
                        _miniStat('Factures', '${clientBills.length}', AppTheme.textMedium),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textLight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textLight)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
