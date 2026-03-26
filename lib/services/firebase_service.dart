import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/loans/models/client_model.dart';
import '../features/loans/models/debt_model.dart';
import '../features/loans/models/payment_model.dart';
import '../features/bills/models/bill_model.dart';
import '../features/bills/models/jewelry_type_model.dart';
import '../core/constants.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── CLIENTS ───────────────────────────────────────────────────────────────

  Stream<List<ClientModel>> watchClients() => _db
      .collection(AppConstants.colClients)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => ClientModel.fromMap(d.data())).toList());

  Future<List<ClientModel>> getClients() async {
    final snap = await _db.collection(AppConstants.colClients).get();
    return snap.docs.map((d) => ClientModel.fromMap(d.data())).toList();
  }

  Future<void> upsertClient(ClientModel c) async {
    await _db.collection(AppConstants.colClients).doc(c.id).set(c.toMap());
  }

  Future<void> deleteClient(String clientId) async {
    await _db.collection(AppConstants.colClients).doc(clientId).delete();
  }

  // ─── DEBTS ─────────────────────────────────────────────────────────────────

  Stream<List<DebtModel>> watchDebtsForClient(String clientId) => _db
      .collection(AppConstants.colDebts)
      .where('clientId', isEqualTo: clientId)
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => DebtModel.fromMap(d.data())).toList());

  Future<List<DebtModel>> getDebts() async {
    final snap = await _db.collection(AppConstants.colDebts).get();
    return snap.docs.map((d) => DebtModel.fromMap(d.data())).toList();
  }

  Future<List<DebtModel>> getDebtsForClient(String clientId) async {
    final snap = await _db
        .collection(AppConstants.colDebts)
        .where('clientId', isEqualTo: clientId)
        .get();
    return snap.docs.map((d) => DebtModel.fromMap(d.data())).toList();
  }

  Future<void> upsertDebt(DebtModel d) async {
    await _db.collection(AppConstants.colDebts).doc(d.id).set(d.toMap());
  }

  Future<void> markDebtSettled(String debtId, bool settled) async {
    await _db.collection(AppConstants.colDebts).doc(debtId).update({'settled': settled});
  }

  // ─── PAYMENTS ──────────────────────────────────────────────────────────────

  Stream<List<PaymentModel>> watchPaymentsForDebt(String debtId) => _db
      .collection(AppConstants.colPayments)
      .where('debtId', isEqualTo: debtId)
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => PaymentModel.fromMap(d.data())).toList());

  Future<List<PaymentModel>> getPayments() async {
    final snap = await _db.collection(AppConstants.colPayments).get();
    return snap.docs.map((d) => PaymentModel.fromMap(d.data())).toList();
  }

  Future<List<PaymentModel>> getPaymentsForClient(String clientId) async {
    final snap = await _db
        .collection(AppConstants.colPayments)
        .where('clientId', isEqualTo: clientId)
        .get();
    return snap.docs.map((d) => PaymentModel.fromMap(d.data())).toList();
  }

  Future<void> upsertPayment(PaymentModel p) async {
    await _db.collection(AppConstants.colPayments).doc(p.id).set(p.toMap());
  }

  // ─── BILLS ─────────────────────────────────────────────────────────────────

  Stream<List<BillModel>> watchBills() => _db
      .collection(AppConstants.colBills)
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => BillModel.fromMap(d.data())).toList());

  Future<List<BillModel>> getBills() async {
    final snap = await _db
        .collection(AppConstants.colBills)
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map((d) => BillModel.fromMap(d.data())).toList();
  }

  Future<BillModel?> getBillById(String id) async {
    final doc = await _db.collection(AppConstants.colBills).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return BillModel.fromMap(doc.data()!);
  }

  Future<void> upsertBill(BillModel b) async {
    await _db.collection(AppConstants.colBills).doc(b.id).set(b.toMap());
  }

  Future<void> deleteBill(String id) async {
    await _db.collection(AppConstants.colBills).doc(id).delete();
  }

  // ─── JEWELRY TYPES ─────────────────────────────────────────────────────────

  Future<List<JewelryTypeModel>> getJewelryTypes() async {
    final snap = await _db.collection(AppConstants.colJewelryTypes).get();
    return snap.docs.map((d) => JewelryTypeModel.fromMap(d.data())).toList();
  }

  Future<void> upsertJewelryType(JewelryTypeModel jt) async {
    await _db.collection(AppConstants.colJewelryTypes).doc(jt.id).set(jt.toMap());
  }

  Future<void> deleteJewelryType(String id) async {
    await _db.collection(AppConstants.colJewelryTypes).doc(id).delete();
  }
}
