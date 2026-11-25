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
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
  ];

  static const List<int> monthNumbers = [5, 6, 7, 8, 9, 10];

  final NumberFormat _rupiahFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  String formatRupiah(double amount) => _rupiahFormatter.format(amount);

  int parseRupiah(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
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
      final dateTimeText =
          '${DateFormat('d MMM yyyy HH:mm:ss').format(firstDate)} WIB';

      return HistoryDayGroup(
        dateLabel: entry.key,
        dateTimeLabel: dateTimeText,
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
          quantity: 1,
        ),
      ];
    }

    return receipt.items
        .map(
          (item) => HistoryProduct(
            name: item.name,
            price: formatRupiah(item.price),
            quantity: item.quantity,
          ),
        )
        .toList();
  }

  Future<void> updateFromDetailResult({
    required ReceiptModel original,
    required HistoryDetailedResult result,
  }) async {
    if (original.id == null) return;

    final updatedItems = result.products
        .map(
          (prod) => ReceiptItem(
            name: prod.name,
            quantity: prod.quantity > 0 ? prod.quantity : 1,
            price: parseRupiah(prod.price).toDouble(),
          ),
        )
        .toList();

    final calculatedTotal = updatedItems.fold<double>(
      0.0,
      (sum, item) => sum + item.subtotal,
    );

    final updatedModel = original.copyWith(
      storeName: result.merchant.trim().isEmpty
          ? original.storeName
          : result.merchant.trim(),
      totalAmount: calculatedTotal,
      category: result.category,
      sourceOfFunds: result.sourceOfFunds,
      items: updatedItems,
    );

    await _db.updateReceipt(updatedModel);
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