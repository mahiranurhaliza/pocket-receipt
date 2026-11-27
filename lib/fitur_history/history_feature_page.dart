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

  int _selectedMonthIndex = DateTime.now().month - 1;
  bool _loading = true;
  List<HistoryDayItem> _days = const [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);

    final receipts =
        await _controller.loadReceiptsForMonthIndex(_selectedMonthIndex);
    final groups = _controller.groupByDay(receipts);

    final mappedDays = groups.map((group) {
      final txs = group.receipts.map((receipt) {
        final txDateTime = _controller.formatReceiptDateTime(receipt.date);
        return HistoryTransactionItem(
          merchant: receipt.storeName,
          amount: _controller.formatRupiah(receipt.totalAmount),
          products: _controller.mapToHistoryProducts(receipt),
          detailTotal: _controller.formatRupiah(receipt.totalAmount),
          sourceOfFunds: receipt.sourceOfFunds,
          category: receipt.category,
          note: receipt.note,
          receiptAsset: receipt.imagePath,
          onTap: () => _openDetail(
            receipt: receipt,
            dateTimeLabel: txDateTime,
          ),
        );
      }).toList();

      return HistoryDayItem(
        date: group.dateLabel,
        dateTime: group.dateTimeLabel,
        transactions: txs,
      );
    }).toList();

    if (!mounted) return;
    setState(() {
      _days = mappedDays;
      _loading = false;
    });
  }

  Future<void> _onMonthSelected(int index) async {
    setState(() => _selectedMonthIndex = index);
    await _loadHistory();
  }

  Future<void> _openDetail({
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
          note: receipt.note,
          receiptAsset: receipt.imagePath,
          onResult: (liveResult) async {
            if (liveResult.deleted) {
              await _controller.deleteReceiptWithImage(receipt);
            } else {
              await _controller.updateFromDetailResult(
                original: receipt,
                result: liveResult,
              );
            }
          },
        ),
      ),
    );

    if (result != null && mounted) {
      await _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _days.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFFDDDDDD),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF05A5A)),
        ),
      );
    }

    return HistoryScreen(
      months: HistoryController.monthNames,
      selectedMonthIndex: _selectedMonthIndex,
      onMonthSelected: _onMonthSelected,
      days: _days,
      onTransactionChanged: _loadHistory,
    );
  }
}