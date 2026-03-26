import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../bills_provider.dart';
import '../models/jewelry_type_model.dart';
import '../../../core/theme.dart';

class ManageJewelryTypesScreen extends StatefulWidget {
  const ManageJewelryTypesScreen({super.key});

  @override
  State<ManageJewelryTypesScreen> createState() => _ManageJewelryTypesScreenState();
}

class _ManageJewelryTypesScreenState extends State<ManageJewelryTypesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock / Articles — السلع', style: TextStyle(color: AppTheme.gold)),
        iconTheme: const IconThemeData(color: AppTheme.gold),
        backgroundColor: AppTheme.darkGreen,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un article...',
                prefixIcon: const Icon(Icons.search),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.lightGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.gold),
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: Consumer<BillsProvider>(
              builder: (ctx, p, _) {
                final items = p.searchJewelryTypes(_searchQuery);
                if (items.isEmpty) {
                  return const Center(child: Text('Aucun article trouvé.'));
                }
                return ListView.builder(
                  itemCount: items.length,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemBuilder: (ctx, i) {
                    final jt = items[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.darkGreen.withOpacity(0.1),
                          child: const Icon(Icons.inventory_2, color: AppTheme.gold),
                        ),
                        title: Text('${jt.name} — ${jt.nameAr}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: Text(
                          'Poids par défaut: ${jt.defaultWeight}g  |  Karat: ${jt.defaultKarat}k\n'
                          'Prix fixe (Optionnel): ${jt.defaultPrice > 0 ? jt.defaultPrice : '-'} MAD',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: AppTheme.darkGreen),
                              onPressed: () => _showEditDialog(context, p, jt: jt),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppTheme.error),
                              onPressed: () => _promptDelete(context, p, jt),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(context, context.read<BillsProvider>()),
        icon: const Icon(Icons.add),
        label: const Text('Nouvel Article'),
      ),
    );
  }

  void _promptDelete(BuildContext context, BillsProvider p, JewelryTypeModel jt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'article ?'),
        content: Text('Voulez-vous vraiment supprimer "${jt.name}" du catalogue ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            onPressed: () async {
              await p.deleteJewelryType(jt.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, BillsProvider p, {JewelryTypeModel? jt}) {
    final nameCtrl = TextEditingController(text: jt?.name ?? '');
    final nameArCtrl = TextEditingController(text: jt?.nameAr ?? '');
    final weightCtrl = TextEditingController(text: jt != null ? jt.defaultWeight.toString() : '0');
    final priceCtrl = TextEditingController(text: jt != null ? jt.defaultPrice.toString() : '0');
    String selectedKarat = jt?.defaultKarat ?? '18';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(jt == null ? 'Ajouter un Article' : 'Modifier l\'Article'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom (Français)'),
                  validator: (v) => v!.trim().isEmpty ? 'Nom requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameArCtrl,
                  decoration: const InputDecoration(labelText: 'Nom (Arabe)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Poids (g)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: ['18', '21', '22', '24'].contains(selectedKarat) ? selectedKarat : '18',
                        decoration: const InputDecoration(labelText: 'Karat'),
                        items: ['18', '21', '22', '24']
                            .map((k) => DropdownMenuItem(value: k, child: Text('${k}k')))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) selectedKarat = v;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Prix total fixe (MAD)',
                    helperText: 'Laissez à 0 si le calcul est au gramme',
                    helperMaxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final weight = double.tryParse(weightCtrl.text.replaceAll(',', '.')) ?? 0.0;
              final price = double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0.0;
              
              if (jt == null) {
                await p.addJewelryType(nameCtrl.text.trim(), nameArCtrl.text.trim(), weight, price, selectedKarat);
              } else {
                await p.updateJewelryType(jt.id, nameCtrl.text.trim(), nameArCtrl.text.trim(), weight, price, selectedKarat);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
