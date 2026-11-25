import 'package:flutter/material.dart';

import '../database/receipt_model.dart';
import '../UI/history.dart';
import '../UI/historyDetailed.dart';
import 'history_controller.dart';

class HistoryFeaturePage extends StatefulWidget {
  const HistoryFeaturePage({super.key});

  @override
  State<HistoryFeaturePage> createState() => _HistoryFeaturePageState();
}

class _HistoryFeaturePageState extends State<HistoryFeaturePage> {
  final HistoryController _controller = HistoryController();
  int _selectedMonthIndex = 5; // Default 'Oct' sesuai HistoryScreen
  List<HistoryDayGroup> _dayGroups = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refreshHistory();
  }

  Future<void> _refreshHistory() async {
    setState(() => _loading = true);
    final receipts =
        await _controller.loadReceiptsForMonthIndex(_selectedMonthIndex);
    if (!mounted) return;
    setState(() {
      _dayGroups = _controller.groupByDay(receipts);
      _loading = false;
    });
  }

  Future<void> openReceiptDetail(
    BuildContext context, {
    required ReceiptModel receipt,
    required String dateTimeLabel,
  }) async {
    final result = await Navigator.of(context).push<HistoryDetailedResult>(
      MaterialPageRoute<HistoryDetailedResult>(
        builder: (_) => HistoryDetailedScreen(
          merchant: receipt.storeName,
          dateTime: dateTimeLabel,
          products: _controller.mapToHistoryProducts(receipt),
          total: _controller.formatRupiah(receipt.totalAmount),
          sourceOfFunds: receipt.sourceOfFunds,
          category: receipt.category,
          receiptAsset: receipt.imagePath,
        ),
      ),
    );

    if (result == null || !mounted) return;

    if (result.deleted) {
      await _controller.deleteReceiptWithImage(receipt);
    } else {
      await _controller.updateFromDetailResult(
        original: receipt,
        result: result,
      );
    }

    if (mounted) {
      await _refreshHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _dayGroups.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFFDDDDDD),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF05A5A)),
        ),
      );
    }

    return const HistoryScreen();
  }
}