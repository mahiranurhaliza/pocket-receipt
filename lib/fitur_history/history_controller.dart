import 'dart:io';

import 'package:intl/intl.dart';

import '../database/database_service.dart';
import '../database/receipt_model.dart';
import '../UI/historyDetailed.dart';

class HistoryDayGroup {
  const HistoryDayGroup({
    required this.dateLabel,
    required this.dateTimeLabel,
    required this.receipts,
  });

  final String dateLabel;
  final String dateTimeLabel;
  final List<ReceiptModel> receipts;
}

class HistoryController {
  HistoryController({DatabaseService? databaseService})
      : _db = databaseService ?? DatabaseService.instance;

  final DatabaseService _db;

  static const List<String> monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<int> monthNumbers = [
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
  ];

  final NumberFormat _rupiahFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  String formatRupiah(double amount) => _rupiahFormatter.format(amount);

  String formatReceiptDateTime(DateTime date) =>
      '${DateFormat('d MMM yyyy HH:mm:ss').format(date)} WIB';

  int parseRupiah(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    final isNegative = trimmed.startsWith('-') ||
        (trimmed.startsWith('(') && trimmed.endsWith(')'));
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = int.tryParse(digits) ?? 0;
    return isNegative ? -parsed : parsed;
  }

  Future<List<ReceiptModel>> loadReceiptsForMonthIndex(int monthIndex) async {
    final safeIndex = monthIndex.clamp(0, monthNumbers.length - 1);
    final targetMonth = monthNumbers[safeIndex];
    final allReceipts = await _db.getAllReceipts();

    return allReceipts
        .where((receipt) => receipt.date.month == targetMonth)
        .toList();
  }

  List<HistoryDayGroup> groupByDay(List<ReceiptModel> receipts) {
    final Map<String, List<ReceiptModel>> grouped = {};

    for (final receipt in receipts) {
      final key = DateFormat('EEEE, d MMM yyyy').format(receipt.date);
      grouped.putIfAbsent(key, () => []).add(receipt);
    }

    return grouped.entries.map((entry) {
      final firstDate = entry.value.first.date;

      return HistoryDayGroup(
        dateLabel: entry.key,
        dateTimeLabel: formatReceiptDateTime(firstDate),
        receipts: entry.value,
      );
    }).toList();
  }

  List<HistoryProduct> mapToHistoryProducts(ReceiptModel receipt) {
    if (receipt.items.isEmpty) {
      return [
        HistoryProduct(
          name: receipt.storeName,
          price: formatRupiah(receipt.totalAmount),
          rawPrice: receipt.totalAmount,
          quantity: 1,
        ),
      ];
    }

    return receipt.items
        .map(
          (item) => HistoryProduct(
            name: item.name,
            price: formatRupiah(item.price),
            rawPrice: item.price,
            quantity: item.quantity > 0 ? item.quantity : 1,
          ),
        )
        .toList();
  }

  Future<void> updateFromDetailResult({
    required ReceiptModel original,
    required HistoryDetailedResult result,
  }) async {
    if (original.id == null) return;

    // Menggabungkan item dengan nama yang sama berdasarkan harga satuan (`price`)
    final Map<String, ReceiptItem> mergedMap = {};
    for (var i = 0; i < result.products.length; i++) {
      final prod = result.products[i];
      final cleanName =
          prod.name.replaceAll(RegExp(r'\s*\(\d+x\)$'), '').trim();
      final name = cleanName.isEmpty ? 'Produk ${i + 1}' : cleanName;
      final qty = prod.quantity > 0 ? prod.quantity : 1;
      final unitPrice = prod.rawPrice != 0
          ? prod.rawPrice
          : parseRupiah(prod.price).toDouble();

      final key = '${name.toLowerCase()}_${unitPrice.toStringAsFixed(0)}';
      if (mergedMap.containsKey(key)) {
        final existing = mergedMap[key]!;
        mergedMap[key] = existing.copyWith(
          quantity: existing.quantity + qty,
        );
      } else {
        mergedMap[key] = ReceiptItem(
          name: name,
          quantity: qty,
          price: unitPrice,
        );
      }
    }

    final updatedItems = mergedMap.values.toList();
    final calculatedTotal = updatedItems.fold<double>(
      0.0,
      (sum, item) => sum + item.subtotal,
    );

    await _db.updateReceipt(
      id: original.id!,
      storeName: result.merchant.trim().isEmpty
          ? original.storeName
          : result.merchant.trim(),
      totalAmount: calculatedTotal,
      category: result.category,
      sourceOfFunds: result.sourceOfFunds,
      note: result.note.trim(),
      items: updatedItems,
    );
  }

  Future<void> deleteReceiptWithImage(ReceiptModel receipt) async {
    if (receipt.id != null) {
      await _db.deleteReceipt(receipt.id!);
    }

    final imagePath = receipt.imagePath;
    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (file.existsSync()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
  }
}