import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/loans/models/client_model.dart';
import '../features/loans/models/debt_model.dart';
import '../features/loans/models/payment_model.dart';
import '../features/bills/models/bill_model.dart';
import '../features/bills/models/jewelry_type_model.dart';
import '../core/constants.dart';

class LocalStorageService {
  // ─── CLIENTS ───────────────────────────────────────────────────────────────

  Future<void> saveClients(List<ClientModel> clients) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(clients.map((c) => c.toMap()).toList());
    await prefs.setString(AppConstants.spClients, json);
  }

  Future<List<ClientModel>> loadClients() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(AppConstants.spClients);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((m) => ClientModel.fromMap(m as Map<String, dynamic>)).toList();
  }

  Future<void> markClientDirty(String clientId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(AppConstants.spDirtyClients) ?? [];
    if (!raw.contains(clientId)) {
      raw.add(clientId);
      await prefs.setStringList(AppConstants.spDirtyClients, raw);
    }
  }

  Future<List<String>> getDirtyClientIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(AppConstants.spDirtyClients) ?? [];
  }

  Future<void> clearDirtyClients() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.spDirtyClients);
  }

  // ─── DEBTS ─────────────────────────────────────────────────────────────────

  Future<void> saveDebts(List<DebtModel> debts) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(debts.map((d) => d.toMap()).toList());
    await prefs.setString(AppConstants.spDebts, json);
  }

  Future<List<DebtModel>> loadDebts() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(AppConstants.spDebts);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((m) => DebtModel.fromMap(m as Map<String, dynamic>)).toList();
  }

  Future<void> markDebtDirty(String debtId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(AppConstants.spDirtyDebts) ?? [];
    if (!raw.contains(debtId)) {
      raw.add(debtId);
      await prefs.setStringList(AppConstants.spDirtyDebts, raw);
    }
  }

  Future<List<String>> getDirtyDebtIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(AppConstants.spDirtyDebts) ?? [];
  }

  Future<void> clearDirtyDebts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.spDirtyDebts);
  }

  // ─── PAYMENTS ──────────────────────────────────────────────────────────────

  Future<void> savePayments(List<PaymentModel> payments) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(payments.map((p) => p.toMap()).toList());
    await prefs.setString(AppConstants.spPayments, json);
  }

  Future<List<PaymentModel>> loadPayments() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(AppConstants.spPayments);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((m) => PaymentModel.fromMap(m as Map<String, dynamic>)).toList();
  }

  Future<void> markPaymentDirty(String paymentId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(AppConstants.spDirtyPayments) ?? [];
    if (!raw.contains(paymentId)) {
      raw.add(paymentId);
      await prefs.setStringList(AppConstants.spDirtyPayments, raw);
    }
  }

  Future<List<String>> getDirtyPaymentIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(AppConstants.spDirtyPayments) ?? [];
  }

  Future<void> clearDirtyPayments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.spDirtyPayments);
  }

  // ─── BILLS ─────────────────────────────────────────────────────────────────

  Future<void> saveBills(List<BillModel> bills) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(bills.map((b) => b.toMap()).toList());
    await prefs.setString(AppConstants.spBills, json);
  }

  Future<List<BillModel>> loadBills() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(AppConstants.spBills);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((m) => BillModel.fromMap(m as Map<String, dynamic>)).toList();
  }

  Future<void> markBillDirty(String billId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(AppConstants.spDirtyBills) ?? [];
    if (!raw.contains(billId)) {
      raw.add(billId);
      await prefs.setStringList(AppConstants.spDirtyBills, raw);
    }
  }

  Future<List<String>> getDirtyBillIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(AppConstants.spDirtyBills) ?? [];
  }

  Future<void> clearDirtyBills() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.spDirtyBills);
  }

  // ─── JEWELRY TYPES ─────────────────────────────────────────────────────────

  Future<void> saveJewelryTypes(List<JewelryTypeModel> types) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(types.map((t) => t.toMap()).toList());
    await prefs.setString(AppConstants.spJewelryTypes, json);
  }

  Future<List<JewelryTypeModel>> loadJewelryTypes() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(AppConstants.spJewelryTypes);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((m) => JewelryTypeModel.fromMap(m as Map<String, dynamic>)).toList();
  }
}
