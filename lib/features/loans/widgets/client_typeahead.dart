import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../../../features/loans/models/client_model.dart';
import '../../../core/theme.dart';

/// Shared typeahead widget for client name — used in both loan creation
/// and bill creation. Shows existing clients as suggestions; typing a
/// new name creates a new client on form submit.
class ClientTypeahead extends StatelessWidget {
  final TextEditingController controller;
  final List<ClientModel> clients;
  final ValueChanged<ClientModel>? onClientSelected;
  final String? labelText;
  final bool showPhone;

  const ClientTypeahead({
    super.key,
    required this.controller,
    required this.clients,
    this.onClientSelected,
    this.labelText,
    this.showPhone = false,
  });

  @override
  Widget build(BuildContext context) {
    return TypeAheadFormField<ClientModel>(
      textFieldConfiguration: TextFieldConfiguration(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText ?? 'Nom du client',
          prefixIcon: const Icon(Icons.person_outline, color: AppTheme.gold),
          suffixIcon: const Icon(Icons.arrow_drop_down, color: AppTheme.textLight),
        ),
      ),
      suggestionsCallback: (pattern) {
        if (pattern.isEmpty) return clients.take(10).toList();
        final q = pattern.toLowerCase();
        return clients
            .where((c) =>
                c.firstName.toLowerCase().contains(q) ||
                c.lastName.toLowerCase().contains(q) ||
                c.fullName.toLowerCase().contains(q))
            .take(8)
            .toList();
      },
      itemBuilder: (context, client) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.darkGreen,
            foregroundColor: AppTheme.gold,
            radius: 18,
            child: Text(
              client.firstName.isNotEmpty
                  ? client.firstName[0].toUpperCase()
                  : '?',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          title: Text(client.fullName),
          subtitle: showPhone && client.phone.isNotEmpty
              ? Text(client.phone,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textLight))
              : null,
          dense: true,
        );
      },
      onSuggestionSelected: (client) {
        controller.text = client.fullName;
        onClientSelected?.call(client);
      },
      noItemsFoundBuilder: (context) => const ListTile(
        leading: Icon(Icons.add_circle_outline, color: AppTheme.gold),
        title: Text(
          'Nouveau client (créé automatiquement)',
          style: TextStyle(color: AppTheme.textMedium, fontSize: 13),
        ),
      ),
      suggestionsBoxDecoration: SuggestionsBoxDecoration(
        elevation: 4,
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      hideOnEmpty: false,
      suggestionsBoxVerticalOffset: 4,
    );
  }
}
