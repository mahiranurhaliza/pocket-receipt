import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../database/receipt_model.dart';
import '../UI/scanDetailed.dart';
import 'ocr_service.dart';
import 'scan_controller.dart';

class ScanDetailFeaturePage extends StatelessWidget {
  ScanDetailFeaturePage({
    super.key,
    required this.imagePath,
    required this.imageBytes,
    required this.ocrResult,
    ScanController? controller,
  }) : _controller = controller ?? ScanController();

  final String imagePath;
  final Uint8List imageBytes;
  final OcrResult ocrResult;
  final ScanController _controller;

  Future<int> saveScannedReceipt({
    required String storeName,
    required String category,
    required String sourceOfFunds,
    required List<ReceiptItem> items,
    String note = '',
  }) {
    return _controller.saveReceipt(
      storeName: storeName,
      category: category,
      sourceOfFunds: sourceOfFunds,
      items: items,
      imagePath: imagePath,
      note: note,
      receiptDateText: ocrResult.receiptDateText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _controller.normalizeItems(ocrResult.items);

    return ScanDetailedScreen(
      receiptBytes: imageBytes,
      initialMerchant: ocrResult.storeName,
      initialItems: filteredItems,
      onSave: ({
        required merchant,
        required items,
        required sourceOfFunds,
        required category,
      }) async {
        await saveScannedReceipt(
          storeName: merchant,
          category: category,
          sourceOfFunds: sourceOfFunds,
          items: items,
        );
        if (context.mounted) {
          Navigator.of(context).pop(true);
        }
      },
    );
  }
}