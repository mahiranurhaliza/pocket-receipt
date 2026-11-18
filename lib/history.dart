import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'historyDetailed.dart';
import 'models/receipt_model.dart';
import 'services/database_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  int _selectedMonthIndex = DateTime.now().month - 1;
  List<ReceiptModel> _allReceipts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    final data = await DatabaseService.instance.getAllReceipts();
    if (!mounted) return;
    setState(() {
      _allReceipts = data;
      _isLoading = false;
    });
  }

  Future<void> _deleteTransaction(_HistoryTransaction tx) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Hapus Riwayat?',
          style: TextStyle(fontFamily: 'Bricolage Grotesque'),
        ),
        content: Text(
          'Transaksi "${tx.merchant}" (${tx.amount}) akan dihapus dari riwayat.',
          style: const TextStyle(fontFamily: 'Bricolage Grotesque'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (tx.id != null) {
        await DatabaseService.instance.deleteReceipt(tx.id!);
      }
      if (tx.imagePath != null && tx.imagePath!.isNotEmpty) {
        final file = File(tx.imagePath!);
        if (file.existsSync()) {
          try {
            await file.delete();
          } catch (_) {}
        }
      }
      await _loadReceipts();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Transaksi "${tx.merchant}" dihapus')),
        );
    }
  }

  String _formatRupiah(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(amount);
  }

  List<_HistoryDay> _buildGroupedDays() {
    final filtered = _allReceipts
        .where((r) => r.date.month - 1 == _selectedMonthIndex)
        .toList();

    final Map<String, List<ReceiptModel>> grouped = {};
    for (final receipt in filtered) {
      final dayKey = DateFormat('EEEE, d MMM yyyy').format(receipt.date);
      grouped.putIfAbsent(dayKey, () => []).add(receipt);
    }

    return grouped.entries.map((entry) {
      final firstDate = entry.value.first.date;
      final formattedDateTime =
          '${DateFormat('d MMM yyyy HH:mm:ss').format(firstDate)} WIB';

      final transactions = entry.value.map((r) {
        final mappedProducts = r.items.isNotEmpty
         ? r.items
             .map((item) => HistoryProduct(
                   name: item.name,
                   quantity: item.quantity,
                   rawPrice: item.price,
                   price: _formatRupiah(item.price),
                 ))
             .toList()
         : [
             HistoryProduct(
               name: r.storeName,
               quantity: 1,
               rawPrice: r.totalAmount,
               price: _formatRupiah(r.totalAmount),
             ),
           ];

     return _HistoryTransaction(
       id: r.id,
       merchant: r.storeName,
       amount: _formatRupiah(r.totalAmount),
       products: mappedProducts,
       detailTotal: _formatRupiah(r.totalAmount),
       sourceOfFunds: r.sourceOfFunds,
       category: r.category,
       note: r.note,
       imagePath: r.imagePath,
     );
      }).toList();

      return _HistoryDay(
        dateLabel: entry.key,
        dateTime: formattedDateTime,
        transactions: transactions,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visibleDays = _buildGroupedDays();

    return Scaffold(
      backgroundColor: const Color(0xFFDDDDDD),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth =
              (constraints.maxWidth - 50).clamp(0.0, 355.0).toDouble();
          final contentLeft = (constraints.maxWidth - contentWidth) / 2;

          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  left: constraints.maxWidth * 0.45,
                  top: -34,
                  child: Container(
                    width: constraints.maxWidth * 0.7,
                    height: constraints.maxWidth * 0.7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.5,
                        colors: [Color(0xFFFFEC5C), Color(0x00FFEC5C)],
                        stops: [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: constraints.maxWidth * 0.05,
                  top: -9,
                  child: Container(
                    width: constraints.maxWidth * 0.7,
                    height: constraints.maxWidth * 0.7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.5,
                        colors: [Color(0xFFFFB357), Color(0x00FFB357)],
                        stops: [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: -constraints.maxWidth * 0.2,
                  top: -63,
                  child: Container(
                    width: constraints.maxWidth * 0.7,
                    height: constraints.maxWidth * 0.7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.5,
                        colors: [Color(0xFFB696E3), Color(0x00B696E3)],
                        stops: [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0x55F8F8F8),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: contentLeft,
                  width: contentWidth,
                  child: SizedBox(
                    height: 40,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 22,
                          height: 40,
                          child: InkWell(
                            onTap: () => Navigator.of(context).maybePop(),
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/icons/back.svg',
                                width: 22,
                                height: 17,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'Your history',
                          style: TextStyle(
                            color: Color(0xFF1E1E1E),
                            fontFamily: 'Bricolage Grotesque',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            height: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 90,
                  left: contentLeft,
                  width: contentWidth,
                  child: SizedBox(
                    height: 30,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _months.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 7),
                      itemBuilder: (context, index) {
                        final selected = index == _selectedMonthIndex;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedMonthIndex = index),
                          child: Container(
                            width: 53,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xD9FFFFFF),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: selected
                                  ? const [
                                      BoxShadow(
                                        color: Color(0x14000000),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              _months[index],
                              style: TextStyle(
                                color: const Color(0xFF1E1E1E),
                                fontFamily: 'Bricolage Grotesque',
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                height: 1.5384615385,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 140,
                  bottom: 24,
                  left: contentLeft,
                  width: contentWidth,
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFF05A5A),
                          ),
                        )
                      : visibleDays.isEmpty
                          ? Center(
                              child: Text(
                                'Belum ada struk tersimpan di bulan ${_months[_selectedMonthIndex]}.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF1E1E1E),
                                  fontFamily: 'Bricolage Grotesque',
                                  fontSize: 15,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: visibleDays.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 15),
                              itemBuilder: (context, index) {
                                return _DayCard(
                                  day: visibleDays[index],
                                  onUpdated: _loadReceipts,
                                  onDelete: _deleteTransaction,
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.onUpdated,
    required this.onDelete,
  });

  final _HistoryDay day;
  final VoidCallback onUpdated;
  final Future<void> Function(_HistoryTransaction tx) onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xD9FFFFFF),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 20,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                day.dateLabel,
                style: const TextStyle(
                  color: Color(0xFF1E1E1E),
                  fontFamily: 'Bricolage Grotesque',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.3333333333,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < day.transactions.length; index++) ...[
            if (index > 0) const SizedBox(height: 10),
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => HistoryDetailedScreen(
                      receiptId: day.transactions[index].id,
                      merchant: day.transactions[index].merchant,
                      dateTime: day.dateTime,
                      products: day.transactions[index].products,
                      total: day.transactions[index].detailTotal,
                      sourceOfFunds: day.transactions[index].sourceOfFunds,
                      category: day.transactions[index].category,
                      note: day.transactions[index].note,
                      receiptAsset: day.transactions[index].imagePath,
                    ),
                  ),
                ).then((_) => onUpdated());
              },
              child: SizedBox(
                height: 40,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        day.transactions[index].merchant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1E1E1E),
                          fontFamily: 'Bricolage Grotesque',
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.3333333333,
                        ),
                      ),
                    ),
                    Text(
                      day.transactions[index].amount,
                      style: const TextStyle(
                        color: Color(0xFF1E1E1E),
                        fontFamily: 'Bricolage Grotesque',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3333333333,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => onDelete(day.transactions[index]),
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Color(0xFFE42525),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryDay {
  const _HistoryDay({
    required this.dateLabel,
    required this.dateTime,
    required this.transactions,
  });

  final String dateLabel;
  final String dateTime;
  final List<_HistoryTransaction> transactions;
}

class _HistoryTransaction {
  const _HistoryTransaction({
    this.id,
    required this.merchant,
    required this.amount,
    required this.products,
    required this.detailTotal,
    required this.sourceOfFunds,
    required this.category,
    required this.note,
    this.imagePath,
  });

  final int? id;
  final String merchant;
  final String amount;
  final List<HistoryProduct> products;
  final String detailTotal;
  final String sourceOfFunds;
  final String category;
  final String note;
  final String? imagePath;
}