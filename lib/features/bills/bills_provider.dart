import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'models/bill_model.dart';
import 'models/jewelry_type_model.dart';
import '../../services/firebase_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/sync_service.dart';
import '../../core/constants.dart';

class BillsProvider extends ChangeNotifier {
  final FirebaseService _firebase;
  final LocalStorageService _local;
  final SyncService _sync;
  final _uuid = const Uuid();

  List<BillModel> _bills = [];
  List<JewelryTypeModel> _jewelryTypes = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _syncMessage;

  // Draft bill state
  List<BillItemModel> _draftItems = [BillItemModel()];
  String _draftClientName = '';
  DateTime _draftDate = DateTime.now();
  String _draftId = const Uuid().v4();

  BillsProvider(this._firebase, this._local, this._sync);

  // ─── Getters ───────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get syncMessage => _syncMessage;
  List<BillModel> get bills => _bills;
  List<JewelryTypeModel> get jewelryTypes => _jewelryTypes;
  List<BillItemModel> get draftItems => _draftItems;
  String get draftClientName => _draftClientName;
  DateTime get draftDate => _draftDate;
  String get draftId => _draftId;

  double get draftTotal =>
      _draftItems.fold(0.0, (sum, item) => sum + item.total);

  // ─── Initialization ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      _bills = await _local.loadBills();
      _jewelryTypes = await _local.loadJewelryTypes();
      notifyListeners();

      final remoteBills = await _firebase.getBills().timeout(const Duration(seconds: 5));
      final remoteTypes = await _firebase.getJewelryTypes().timeout(const Duration(seconds: 5));

      if (remoteBills.isNotEmpty) {
        _bills = remoteBills;
        await _local.saveBills(_bills);
      }

      if (remoteTypes.isNotEmpty) {
        _jewelryTypes = remoteTypes;
        await _local.saveJewelryTypes(_jewelryTypes);
      } else if (_jewelryTypes.isEmpty) {
        // Seed with defaults
        _jewelryTypes = AppConstants.defaultJewelryTypes
            .map((m) => JewelryTypeModel(
                  id: _uuid.v4(),
                  name: m['name'] as String,
                  nameAr: m['nameAr'] as String,
                  defaultWeight: m['defaultWeight'] as double,
                  defaultPrice: m['defaultPrice'] as double,
                  defaultKarat: m['defaultKarat'] as String? ?? '18',
                ))
            .toList();
        for (final jt in _jewelryTypes) {
          await _firebase.upsertJewelryType(jt);
        }
        await _local.saveJewelryTypes(_jewelryTypes);
      }
    } catch (_) {
      // Offline — use cached
      if (_jewelryTypes.isEmpty) {
        _jewelryTypes = AppConstants.defaultJewelryTypes
            .map((m) => JewelryTypeModel(
                  id: _uuid.v4(),
                  name: m['name'] as String,
                  nameAr: m['nameAr'] as String,
                  defaultWeight: m['defaultWeight'] as double,
                  defaultPrice: m['defaultPrice'] as double,
                  defaultKarat: m['defaultKarat'] as String? ?? '18',
                ))
            .toList();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Draft bill editing ────────────────────────────────────────────────────

  void setDraftClientName(String name) {
    _draftClientName = name;
    notifyListeners();
  }

  void setDraftDate(DateTime d) {
    _draftDate = d;
    notifyListeners();
  }

  void addDraftItem() {
    if (_draftItems.length < AppConstants.maxBillRows) {
      _draftItems.add(BillItemModel());
      notifyListeners();
    }
  }

  void removeDraftItem(int index) {
    if (_draftItems.length > 1) {
      _draftItems.removeAt(index);
      notifyListeners();
    }
  }

  void updateDraftItem(int index, BillItemModel item) {
    if (index >= 0 && index < _draftItems.length) {
      _draftItems[index] = item;
      notifyListeners();
    }
  }

  void loadBillForEditing(BillModel bill) {
    _draftId = bill.id;
    _draftClientName = bill.clientName;
    _draftDate = bill.date;
    _draftItems = bill.items.map((i) => i.copyWith()).toList();
    if (_draftItems.isEmpty) _draftItems.add(BillItemModel());
    notifyListeners();
  }


  void resetDraft() {
    _draftItems = [BillItemModel()];
    _draftClientName = '';
    _draftDate = DateTime.now();
    _draftId = _uuid.v4();
    notifyListeners();
  }

  // ─── Save bill ─────────────────────────────────────────────────────────────

  Future<BillModel> saveBill() async {
    final bill = BillModel(
      id: _uuid.v4(),
      clientName: _draftClientName,
      city: AppConstants.city,
      date: _draftDate,
      items: List.from(_draftItems.where((i) => i.jewelryType.isNotEmpty)),
      total: draftTotal,
      isDirty: true,
    );
    _bills.insert(0, bill);
    await _local.saveBills(_bills);
    await _local.markBillDirty(bill.id);
    _tryFirestore(() => _firebase.upsertBill(bill));
    resetDraft();
    notifyListeners();
    return bill;
  }

  Future<void> deleteBill(String id) async {
    _bills.removeWhere((b) => b.id == id);
    await _local.saveBills(_bills);
    _tryFirestore(() => _firebase.deleteBill(id));
    notifyListeners();
  }

  Future<BillModel> updateExistingBill(String id) async {
    final idx = _bills.indexWhere((b) => b.id == id);
    if (idx == -1) throw Exception('Bill not found');
    
    final updated = _bills[idx].copyWith(
      clientName: _draftClientName,
      date: _draftDate,
      items: List.from(_draftItems.where((i) => i.jewelryType.isNotEmpty)),
      total: draftTotal,
      isDirty: true,
    );
    _bills[idx] = updated;
    await _local.saveBills(_bills);
    await _local.markBillDirty(id);
    _tryFirestore(() => _firebase.upsertBill(updated));
    resetDraft();
    notifyListeners();
    return updated;
  }


  Future<void> updateBillClientName(String id, String newName) async {
    final idx = _bills.indexWhere((b) => b.id == id);
    if (idx != -1) {
      _bills[idx] = _bills[idx].copyWith(clientName: newName, isDirty: true);
      await _local.saveBills(_bills);
      await _local.markBillDirty(id);
      _tryFirestore(() => _firebase.upsertBill(_bills[idx]));
      notifyListeners();
    }
  }

  // ─── Jewelry types management ──────────────────────────────────────────────

  Future<void> addJewelryType(String name, String nameAr, double defaultWeight, double defaultPrice, String defaultKarat) async {
    final jt = JewelryTypeModel(
      id: _uuid.v4(),
      name: name,
      nameAr: nameAr,
      defaultWeight: defaultWeight,
      defaultPrice: defaultPrice,
      defaultKarat: defaultKarat,
    );
    _jewelryTypes.add(jt);
    await _local.saveJewelryTypes(_jewelryTypes);
    _tryFirestore(() => _firebase.upsertJewelryType(jt));
    notifyListeners();
  }

  Future<void> updateJewelryType(String id, String name, String nameAr, double defaultWeight, double defaultPrice, String defaultKarat) async {
    final idx = _jewelryTypes.indexWhere((jt) => jt.id == id);
    if (idx != -1) {
      final updated = _jewelryTypes[idx].copyWith(
        name: name,
        nameAr: nameAr,
        defaultWeight: defaultWeight,
        defaultPrice: defaultPrice,
        defaultKarat: defaultKarat,
      );
      _jewelryTypes[idx] = updated;
      await _local.saveJewelryTypes(_jewelryTypes);
      _tryFirestore(() => _firebase.upsertJewelryType(updated));
      notifyListeners();
    }
  }

  Future<void> deleteJewelryType(String id) async {
    _jewelryTypes.removeWhere((jt) => jt.id == id);
    await _local.saveJewelryTypes(_jewelryTypes);
    _tryFirestore(() => _firebase.deleteJewelryType(id));
    notifyListeners();
  }

  List<JewelryTypeModel> searchJewelryTypes(String query) {
    if (query.isEmpty) return _jewelryTypes;
    final q = query.toLowerCase();
    return _jewelryTypes
        .where((jt) =>
            jt.name.toLowerCase().contains(q) ||
            jt.nameAr.contains(query))
        .toList();
  }

  // ─── Bills history search ──────────────────────────────────────────────────

  List<BillModel> searchBills({
    String? clientName,
    DateTime? from,
    DateTime? to,
  }) {
    return _bills.where((b) {
      if (clientName != null && clientName.isNotEmpty) {
        final query = clientName.toLowerCase();
        final matchesName = b.clientName.toLowerCase().contains(query);
        final matchesRef = b.id.toLowerCase().contains(query);
        if (!matchesName && !matchesRef) {
          return false;
        }
      }
      if (from != null && b.date.isBefore(from)) return false;
      if (to != null && b.date.isAfter(to.add(const Duration(days: 1)))) return false;
      return true;
    }).toList();
  }

  // ─── Sync ──────────────────────────────────────────────────────────────────

  Future<void> syncWithFirestore() async {
    _isSyncing = true;
    _syncMessage = null;
    notifyListeners();
    final result = await _sync.syncAll(
      localClients: [],
      localDebts: [],
      localPayments: [],
      localBills: _bills,
    );
    _isSyncing = false;
    _syncMessage = result.hasErrors
        ? 'Erreur de synchronisation.'
        : '${result.syncedCount} facture(s) synchronisée(s) ✅';
    notifyListeners();
  }

  Future<void> importBillsFromList(List<BillModel> imported) async {
    for (final b in imported) {
      final exists = _bills.any((e) => e.id == b.id);
      if (!exists) {
        _bills.add(b);
        _tryFirestore(() => _firebase.upsertBill(b));
      }
    }
    await _local.saveBills(_bills);
    notifyListeners();
  }

  void _tryFirestore(Future<void> Function() fn) {
    fn().catchError((e) {
      debugPrint('🔥 FIREBASE SYNC ERROR: $e');
    });
  }
}
