import '../features/loans/models/client_model.dart';
import '../features/loans/models/debt_model.dart';
import '../features/loans/models/payment_model.dart';
import '../features/bills/models/bill_model.dart';
import 'firebase_service.dart';
import 'local_storage_service.dart';

class SyncService {
  final FirebaseService _firebase;
  final LocalStorageService _local;

  SyncService(this._firebase, this._local);

  Future<SyncResult> syncAll({
    required List<ClientModel> localClients,
    required List<DebtModel> localDebts,
    required List<PaymentModel> localPayments,
    required List<BillModel> localBills,
  }) async {
    int synced = 0;
    final errors = <String>[];

    try {
      // Sync dirty clients
      final dirtyClientIds = await _local.getDirtyClientIds();
      for (final id in dirtyClientIds) {
        final client = localClients.firstWhere(
          (c) => c.id == id,
          orElse: () => ClientModel(id: '', firstName: '', lastName: ''),
        );
        if (client.id.isNotEmpty) {
          await _firebase.upsertClient(client);
          synced++;
        }
      }
      await _local.clearDirtyClients();

      // Sync dirty debts
      final dirtyDebtIds = await _local.getDirtyDebtIds();
      for (final id in dirtyDebtIds) {
        final debt = localDebts.firstWhere(
          (d) => d.id == id,
          orElse: () => DebtModel(id: '', clientId: '', amount: 0),
        );
        if (debt.id.isNotEmpty) {
          await _firebase.upsertDebt(debt);
          synced++;
        }
      }
      await _local.clearDirtyDebts();

      // Sync dirty payments
      final dirtyPaymentIds = await _local.getDirtyPaymentIds();
      for (final id in dirtyPaymentIds) {
        final payment = localPayments.firstWhere(
          (p) => p.id == id,
          orElse: () => PaymentModel(id: '', debtId: '', clientId: '', amount: 0),
        );
        if (payment.id.isNotEmpty) {
          await _firebase.upsertPayment(payment);
          synced++;
        }
      }
      await _local.clearDirtyPayments();

      // Sync dirty bills
      final dirtyBillIds = await _local.getDirtyBillIds();
      for (final id in dirtyBillIds) {
        final bill = localBills.firstWhere(
          (b) => b.id == id,
          orElse: () => BillModel(id: '', clientName: '', items: [], total: 0),
        );
        if (bill.id.isNotEmpty) {
          await _firebase.upsertBill(bill);
          synced++;
        }
      }
      await _local.clearDirtyBills();
    } catch (e) {
      errors.add(e.toString());
    }

    return SyncResult(syncedCount: synced, errors: errors);
  }
}

class SyncResult {
  final int syncedCount;
  final List<String> errors;

  SyncResult({required this.syncedCount, required this.errors});

  bool get hasErrors => errors.isNotEmpty;
}
