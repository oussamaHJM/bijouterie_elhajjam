import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'models/client_model.dart';
import 'models/debt_model.dart';
import 'models/payment_model.dart';
import '../bills/models/bill_model.dart';

import '../../services/firebase_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/sync_service.dart';

class LoansProvider extends ChangeNotifier {
  final FirebaseService _firebase;
  final LocalStorageService _local;
  final SyncService _sync;
  final _uuid = const Uuid();

  List<ClientModel> _clients = [];
  List<DebtModel> _debts = [];
  List<PaymentModel> _payments = [];

  String _searchQuery = '';
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _syncMessage;

  LoansProvider(this._firebase, this._local, this._sync);

  // ─── Getters ───────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get syncMessage => _syncMessage;
  List<ClientModel> get allClients => _clients;

  List<ClientModel> get filteredClients {
    final activeClients = _clients.where((c) => debtsForClient(c.id).isNotEmpty).toList();
    if (_searchQuery.isEmpty) return activeClients;
    final q = _searchQuery.toLowerCase();
    return activeClients.where((c) =>
      c.firstName.toLowerCase().contains(q) ||
      c.lastName.toLowerCase().contains(q) ||
      c.phone.toLowerCase().contains(q),
    ).toList();
  }

  List<DebtModel> debtsForClient(String clientId) =>
      _debts.where((d) => d.clientId == clientId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  List<PaymentModel> paymentsForDebt(String debtId) =>
      _payments.where((p) => p.debtId == debtId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  double totalDebtForClient(String clientId) =>
      _debts.where((d) => d.clientId == clientId).fold(0.0, (s, d) => s + d.amount);

  double totalPaidForClient(String clientId) =>
      _payments.where((p) => p.clientId == clientId).fold(0.0, (s, p) => s + p.amount);

  double remainingForClient(String clientId) =>
      totalDebtForClient(clientId) - totalPaidForClient(clientId);

  double totalPaidForDebt(String debtId) =>
      _payments.where((p) => p.debtId == debtId).fold(0.0, (s, p) => s + p.amount);

  double remainingForDebt(String debtId) {
    final debt = _debts.firstWhere((d) => d.id == debtId, orElse: () => DebtModel(id: '', clientId: '', amount: 0));
    return debt.amount - totalPaidForDebt(debtId);
  }

  // ─── Initialization ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Load from local storage first (fast)
      _clients = await _local.loadClients();
      _debts = await _local.loadDebts();
      _payments = await _local.loadPayments();
      notifyListeners();

      // Then pull from Firestore
      final remoteClients = await _firebase.getClients().timeout(const Duration(seconds: 5));
      final remoteDebts = await _firebase.getDebts().timeout(const Duration(seconds: 5));
      final remotePayments = await _firebase.getPayments().timeout(const Duration(seconds: 5));
      _clients = remoteClients;
      _debts = remoteDebts;
      _payments = remotePayments;

      await _local.saveClients(_clients);
      await _local.saveDebts(_debts);
      await _local.savePayments(_payments);
    } catch (_) {
      // Offline — use cached data
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Search ────────────────────────────────────────────────────────────────

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  // ─── Clients ───────────────────────────────────────────────────────────────

  Future<void> deleteClient(String id) async {
    _clients.removeWhere((c) => c.id == id);
    await _local.saveClients(_clients);
    _tryFirestore(() => _firebase.deleteClient(id));
    notifyListeners();
  }

  Future<void> updateClient(String id, String firstName, String lastName, String phone) async {
    final idx = _clients.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _clients[idx] = _clients[idx].copyWith(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        isDirty: true,
      );
      await _local.saveClients(_clients);
      await _local.markClientDirty(id);
      _tryFirestore(() => _firebase.upsertClient(_clients[idx]));
      notifyListeners();
    }
  }

  /// Returns an existing client matching name, or creates a new one (inline).
  Future<ClientModel> findOrCreateClient({
    required String firstName,
    required String lastName,
    String phone = '',
  }) async {
    final existing = _clients.firstWhere(
      (c) =>
          c.firstName.toLowerCase() == firstName.toLowerCase() &&
          c.lastName.toLowerCase() == lastName.toLowerCase(),
      orElse: () => ClientModel(id: '', firstName: '', lastName: ''),
    );
    if (existing.id.isNotEmpty) return existing;

    final client = ClientModel(
      id: _uuid.v4(),
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      isDirty: true,
    );
    _clients.add(client);
    await _local.saveClients(_clients);
    await _local.markClientDirty(client.id);
    _tryFirestore(() => _firebase.upsertClient(client));
    notifyListeners();
    return client;
  }

  List<ClientModel> searchClients(String query) {
    if (query.isEmpty) return _clients;
    final q = query.toLowerCase();
    return _clients
        .where((c) =>
            c.firstName.toLowerCase().contains(q) ||
            c.lastName.toLowerCase().contains(q))
        .toList();
  }

  // ─── Debts ────────────────────────────────────────────────────────────────

  Future<DebtModel> addDebt({
    required String clientId,
    required double amount,
    required DateTime date,
    String? notes,
    List<BillItemModel> items = const [],
  }) async {
    final debt = DebtModel(
      id: _uuid.v4(),
      clientId: clientId,
      amount: amount,
      date: date,
      notes: notes,
      items: items,
      isDirty: true,
    );
    _debts.add(debt);
    await _local.saveDebts(_debts);
    await _local.markDebtDirty(debt.id);
    _tryFirestore(() => _firebase.upsertDebt(debt));
    notifyListeners();
    return debt;
  }

  Future<void> addPayment({
    required String debtId,
    required String clientId,
    required double amount,
    required DateTime date,
    String? notes,
  }) async {
    final payment = PaymentModel(
      id: _uuid.v4(),
      debtId: debtId,
      clientId: clientId,
      amount: amount,
      date: date,
      notes: notes,
      isDirty: true,
    );
    _payments.add(payment);
    await _local.savePayments(_payments);
    await _local.markPaymentDirty(payment.id);
    _tryFirestore(() => _firebase.upsertPayment(payment));
    notifyListeners();
  }

  Future<void> markDebtSettled(String debtId, bool settled) async {
    final idx = _debts.indexWhere((d) => d.id == debtId);
    if (idx >= 0) {
      _debts[idx] = _debts[idx].copyWith(settled: settled);
      await _local.saveDebts(_debts);
      await _local.markDebtDirty(debtId);
      _tryFirestore(() => _firebase.markDebtSettled(debtId, settled));
      notifyListeners();
    }
  }

  // ─── Sync & CSV ────────────────────────────────────────────────────────────

  Future<void> syncWithFirestore() async {
    _isSyncing = true;
    _syncMessage = null;
    notifyListeners();
    final result = await _sync.syncAll(
      localClients: _clients,
      localDebts: _debts,
      localPayments: _payments,
      localBills: [],
    );
    _isSyncing = false;
    _syncMessage = result.hasErrors
        ? 'Erreur de synchronisation.'
        : '${result.syncedCount} enregistrement(s) synchronisé(s) ✅';
    notifyListeners();
  }

  // Import clients from CSV
  Future<void> importClientsFromList(List<ClientModel> imported) async {
    for (final c in imported) {
      final exists = _clients.any((e) => e.id == c.id);
      if (!exists) {
        _clients.add(c);
        _tryFirestore(() => _firebase.upsertClient(c));
      }
    }
    await _local.saveClients(_clients);
    notifyListeners();
  }

  Future<void> importDebtsFromList(List<DebtModel> imported) async {
    for (final d in imported) {
      final exists = _debts.any((e) => e.id == d.id);
      if (!exists) {
        _debts.add(d);
        _tryFirestore(() => _firebase.upsertDebt(d));
      }
    }
    await _local.saveDebts(_debts);
    notifyListeners();
  }

  Future<void> importPaymentsFromList(List<PaymentModel> imported) async {
    for (final p in imported) {
      final exists = _payments.any((e) => e.id == p.id);
      if (!exists) {
        _payments.add(p);
        _tryFirestore(() => _firebase.upsertPayment(p));
      }
    }
    await _local.savePayments(_payments);
    notifyListeners();
  }

  // All getters needed for CSV export
  List<DebtModel> get allDebts => _debts;
  List<PaymentModel> get allPayments => _payments;

  // ─── Helper ────────────────────────────────────────────────────────────────

  void _tryFirestore(Future<void> Function() fn) {
    fn().catchError((e) {
      debugPrint('🔥 FIREBASE SYNC ERROR: $e');
    }); // Silently fail if offline
  }
}
