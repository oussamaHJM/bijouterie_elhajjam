class AppConstants {
  // Shop info
  static const String shopNameFr = 'Bijouterie El-Hajjam';
  static const String shopNameAr = 'مجوهرات الحجام';
  static const String city = 'Boujaad';
  static const String cityAr = 'بوجعد';
  static const String currency = 'MAD';
  static const String currencySymbol = 'د.م.';

  // Footer info (legal identifiers)
  static const String ice = 'ICE : 001143477000057';
  static const String ifNumber = 'IF : 59802119';
  static const String rc = 'N° DU REGISTRE DE COMMERCE : 1042/BOUJAAD';
  static const String patente = 'PATENTE : 41218012';

  // Note at bottom of invoice
  static const String invoiceNote =
      'جميع المجوهرات لا تبدل ولا ترد بعد إتمام البيع وشكراً';

  // Date format
  static const String dateFormat = 'dd/MM/yyyy';

  // Firestore collection names
  static const String colClients = 'clients';
  static const String colDebts = 'debts';
  static const String colPayments = 'payments';
  static const String colBills = 'bills';
  static const String colBillItems = 'billItems';
  static const String colJewelryTypes = 'jewelryTypes';

  // SharedPreferences keys
  static const String spClients = 'sp_clients';
  static const String spDebts = 'sp_debts';
  static const String spPayments = 'sp_payments';
  static const String spBills = 'sp_bills';
  static const String spJewelryTypes = 'sp_jewelry_types';
  static const String spDirtyClients = 'sp_dirty_clients';
  static const String spDirtyDebts = 'sp_dirty_debts';
  static const String spDirtyPayments = 'sp_dirty_payments';
  static const String spDirtyBills = 'sp_dirty_bills';

  // Max bill rows
  static const int maxBillRows = 15;

  // Default jewelry types with default weights (grams) and prices (MAD)
  static const List<Map<String, dynamic>> defaultJewelryTypes = [
    {'name': 'Bracelet', 'nameAr': 'سوار', 'defaultWeight': 10.0, 'defaultPrice': 0.0, 'defaultKarat': '18'},
    {'name': 'Collier', 'nameAr': 'قلادة', 'defaultWeight': 12.0, 'defaultPrice': 0.0, 'defaultKarat': '18'},
    {'name': 'Bague', 'nameAr': 'خاتم', 'defaultWeight': 5.0, 'defaultPrice': 0.0, 'defaultKarat': '18'},
    {'name': 'Boucles d\'oreilles', 'nameAr': 'أقراط', 'defaultWeight': 4.0, 'defaultPrice': 0.0, 'defaultKarat': '18'},
    {'name': 'Jonc', 'nameAr': 'جنك', 'defaultWeight': 15.0, 'defaultPrice': 0.0, 'defaultKarat': '18'},
    {'name': 'Chaîne', 'nameAr': 'سلسلة', 'defaultWeight': 8.0, 'defaultPrice': 0.0, 'defaultKarat': '18'},
    {'name': 'Pendentif', 'nameAr': 'مدلاة', 'defaultWeight': 3.0, 'defaultPrice': 0.0, 'defaultKarat': '18'},
    {'name': 'Alliance', 'nameAr': 'خاتم الزواج', 'defaultWeight': 6.0, 'defaultPrice': 0.0, 'defaultKarat': '18'},
    {'name': 'Chevalière', 'nameAr': 'خاتم فضي', 'defaultWeight': 7.0, 'defaultPrice': 0.0, 'defaultKarat': '18'},
    {'name': 'Parure', 'nameAr': 'طقم', 'defaultWeight': 25.0, 'defaultPrice': 0.0, 'defaultKarat': '18'},
    {'name': 'Louis (Pièce)', 'nameAr': 'لويز', 'defaultWeight': 4.0, 'defaultPrice': 1500.0, 'defaultKarat': '21'},
    {'name': 'Napoléon (10f)', 'nameAr': 'نابليون 10 فرنك', 'defaultWeight': 3.2, 'defaultPrice': 1200.0, 'defaultKarat': '21'},
  ];

  // Karats
  static const List<String> karats = ['18', '21', '22', '24'];
}
