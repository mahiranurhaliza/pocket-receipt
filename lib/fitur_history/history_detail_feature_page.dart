import 'package:flutter/material.dart';

import '../database/receipt_model.dart';
import '../UI/historyDetailed.dart';
import 'history_controller.dart';

class HistoryDetailFeaturePage extends StatelessWidget {
  HistoryDetailFeaturePage({
    super.key,
    required this.receipt,
    required this.dateTimeLabel,
    HistoryController? controller,
  }) : _controller = controller ?? HistoryController();

  final ReceiptModel receipt;
  final String dateTimeLabel;
  final HistoryController _controller;

  @override
  Widget build(BuildContext context) {
    return HistoryDetailedScreen(
      merchant: receipt.storeName,
      dateTime: dateTimeLabel,
      products: _controller.mapToHistoryProducts(receipt),
      total: _controller.formatRupiah(receipt.totalAmount),
      sourceOfFunds: receipt.sourceOfFunds,
      category: receipt.category,
      receiptAsset: receipt.imagePath,
    );
  }
}