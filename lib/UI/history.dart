import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'historyDetailed.dart';

class HistoryTransactionItem {
  const HistoryTransactionItem({
    required this.merchant,
    required this.amount,
    required this.products,
    required this.detailTotal,
    required this.sourceOfFunds,
    required this.category,
    this.note = '',
    this.receiptAsset,
    this.onTap,
  });

  final String merchant;
  final String amount;
  final List<HistoryProduct> products;
  final String detailTotal;
  final String sourceOfFunds;
  final String category;
  final String note;
  final String? receiptAsset;
  final VoidCallback? onTap;
}

class HistoryDayItem {
  const HistoryDayItem({
    required this.date,
    required this.dateTime,
    required this.transactions,
  });

  final String date;
  final String dateTime;
  final List<HistoryTransactionItem> transactions;
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    this.months = const ['May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct'],
    this.selectedMonthIndex = 5,
    this.onMonthSelected,
    this.days,
    this.onTransactionChanged,
  });

  final List<String> months;
  final int selectedMonthIndex;
  final ValueChanged<int>? onMonthSelected;
  final List<HistoryDayItem>? days;
  final VoidCallback? onTransactionChanged;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const _fallbackDays = [
    HistoryDayItem(
      date: 'Tuesday, 20 Oct 2026',
      dateTime: '20 Oct 2026 11:46:18 WIB',
      transactions: [
        HistoryTransactionItem(
          merchant: 'Alfamart',
          amount: 'Rp13.000',
          products: [
            HistoryProduct(name: 'Mineral', price: 'Rp5.000', quantity: 1),
            HistoryProduct(name: 'Ice Cream', price: 'Rp8.000', quantity: 1),
          ],
          detailTotal: 'Rp13.000',
          sourceOfFunds: 'GoPay',
          category: 'Food & Beverages',
        ),
        HistoryTransactionItem(
          merchant: 'Indomart',
          amount: 'Rp30.000',
          products: [
            HistoryProduct(name: 'Bread', price: 'Rp12.000', quantity: 1),
            HistoryProduct(name: 'Milk', price: 'Rp18.000', quantity: 1),
          ],
          detailTotal: 'Rp30.000',
          sourceOfFunds: 'BNI',
          category: 'Food & Beverages',
        ),
        HistoryTransactionItem(
          merchant: 'Lawson',
          amount: 'Rp30.000',
          products: [
            HistoryProduct(name: 'Coffee', price: 'Rp20.000', quantity: 1),
            HistoryProduct(name: 'Snack', price: 'Rp10.000', quantity: 1),
          ],
          detailTotal: 'Rp30.000',
          sourceOfFunds: 'ShopeePay',
          category: 'Food & Beverages',
        ),
      ],
    ),
    HistoryDayItem(
      date: 'Monday, 19 Oct 2026',
      dateTime: '19 Oct 2026 11:46:18 WIB',
      transactions: [
        HistoryTransactionItem(
          merchant: 'Alfamart',
          amount: 'Rp13.000',
          products: [
            HistoryProduct(name: 'Mineral', price: 'Rp5.000', quantity: 1),
            HistoryProduct(name: 'Ice Cream', price: 'Rp8.000', quantity: 1),
          ],
          detailTotal: 'Rp13.000',
          sourceOfFunds: 'GoPay',
          category: 'Food & Beverages',
        ),
      ],
    ),
    HistoryDayItem(
      date: 'Sunday, 18 Oct 2026',
      dateTime: '18 Oct 2026 11:46:18 WIB',
      transactions: [
        HistoryTransactionItem(
          merchant: 'Indomart',
          amount: 'Rp30.000',
          products: [
            HistoryProduct(name: 'Bread', price: 'Rp12.000', quantity: 1),
            HistoryProduct(name: 'Milk', price: 'Rp18.000', quantity: 1),
          ],
          detailTotal: 'Rp30.000',
          sourceOfFunds: 'BNI',
          category: 'Food & Beverages',
        ),
      ],
    ),
  ];

  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.selectedMonthIndex;
  }

  @override
  void didUpdateWidget(covariant HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMonthIndex != widget.selectedMonthIndex) {
      _selectedMonth = widget.selectedMonthIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeDays = widget.days ?? _fallbackDays;

    return Scaffold(
      backgroundColor: const Color(0xFFDDDDDD),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth =
              (constraints.maxWidth - 50).clamp(0.0, 440.0).toDouble();
          final contentLeft = (constraints.maxWidth - contentWidth) / 2;

          return Stack(
            children: [
              // Ambient gradient orbs
              Positioned(
                left: constraints.maxWidth * 0.45,
                top: -34,
                child: IgnorePointer(
                  child: Container(
                    width: constraints.maxWidth * 0.7,
                    height: constraints.maxWidth * 0.7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.5,
                        colors: [
                          Color(0xFFFFEC5C),
                          Color(0x00FFEC5C),
                        ],
                        stops: [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: constraints.maxWidth * 0.05,
                top: -9,
                child: IgnorePointer(
                  child: Container(
                    width: constraints.maxWidth * 0.7,
                    height: constraints.maxWidth * 0.7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.5,
                        colors: [
                          Color(0xFFFFB357),
                          Color(0x00FFB357),
                        ],
                        stops: [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -constraints.maxWidth * 0.2,
                top: -63,
                child: IgnorePointer(
                  child: Container(
                    width: constraints.maxWidth * 0.7,
                    height: constraints.maxWidth * 0.7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.5,
                        colors: [
                          Color(0xFFB696E3),
                          Color(0x00B696E3),
                        ],
                        stops: [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(color: Color(0x55F8F8F8)),
                ),
              ),
              SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: 40,
                  bottom: 32 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Center(
                  child: SizedBox(
                    width: contentWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Header(
                          onBack: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          height: 30,
                          child: _MonthSelector(
                            months: widget.months,
                            selectedIndex: _selectedMonth,
                            onSelected: (index) {
                              setState(() => _selectedMonth = index);
                              widget.onMonthSelected?.call(index);
                            },
                          ),
                        ),
                        const SizedBox(height: 25),
                        if (activeDays.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(248, 248, 248, 0.85),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'No transactions found for this month.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF1E1E1E),
                                fontFamily: 'Bricolage Grotesque',
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          )
                        else
                          for (var index = 0;
                              index < activeDays.length;
                              index++) ...[
                            _DayCard(
                              day: activeDays[index],
                              onTransactionChanged: widget.onTransactionChanged,
                            ),
                            if (index != activeDays.length - 1)
                              const SizedBox(height: 25),
                          ],
                      ],
                    ),
                  ),
                ),
              ),
              // Keep contentLeft referenced cleanly for any external consumers
              if (contentLeft < 0) const SizedBox.shrink(),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 40,
            child: InkWell(
              onTap: onBack,
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/back.svg',
                  width: 22,
                  height: 17,
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          const Text(
            'Your history',
            style: TextStyle(
              color: Color(0xFF1E1E1E),
              fontFamily: 'Bricolage Grotesque',
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.months,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> months;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < months.length; index++) ...[
            SizedBox(
              width: 58,
              child: _MonthPill(
                label: months[index],
                selected: index == selectedIndex,
                onPressed: () => onSelected(index),
              ),
            ),
            if (index != months.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _MonthPill extends StatelessWidget {
  const _MonthPill({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFD2BFEE) : const Color(0xFFF8F8F8),
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(100),
        child: SizedBox(
          height: 30,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1E1E1E),
                fontFamily: 'Bricolage Grotesque',
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    this.onTransactionChanged,
  });

  final HistoryDayItem day;
  final VoidCallback? onTransactionChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(248, 248, 248, 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 15),
                child: Text(
                  day.date,
                  style: const TextStyle(
                    color: Color(0xFF1E1E1E),
                    fontFamily: 'Bricolage Grotesque',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          SvgPicture.asset(
            'assets/0029e.svg',
            width: double.infinity,
            height: 1,
            fit: BoxFit.fill,
          ),
          for (var index = 0; index < day.transactions.length; index++)
            _TransactionRow(
              transaction: day.transactions[index],
              showDivider: index != day.transactions.length - 1,
              dividerAsset:
                  index == 0 ? 'assets/e2b93.svg' : 'assets/8947c.svg',
              onPressed: day.transactions[index].onTap ??
                  () async {
                    final result =
                        await Navigator.of(context).push<HistoryDetailedResult>(
                      MaterialPageRoute<HistoryDetailedResult>(
                        builder: (_) => HistoryDetailedScreen(
                          merchant: day.transactions[index].merchant,
                          dateTime: day.dateTime,
                          products: day.transactions[index].products,
                          total: day.transactions[index].detailTotal,
                          sourceOfFunds: day.transactions[index].sourceOfFunds,
                          category: day.transactions[index].category,
                          note: day.transactions[index].note,
                          receiptAsset: day.transactions[index].receiptAsset,
                        ),
                      ),
                    );
                    if (result != null) {
                      onTransactionChanged?.call();
                    }
                  },
            ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.transaction,
    required this.showDivider,
    required this.dividerAsset,
    required this.onPressed,
  });

  final HistoryTransactionItem transaction;
  final bool showDivider;
  final String dividerAsset;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: 69.6666666667,
          child: Stack(
            children: [
              Positioned(
                left: 15,
                top: 12,
                bottom: 12,
                child: Center(
                  child: Text(
                    transaction.merchant,
                    style: const TextStyle(
                      color: Color(0xFF1E1E1E),
                      fontFamily: 'Bricolage Grotesque',
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 15,
                top: 12,
                bottom: 12,
                child: Center(
                  child: Text(
                    transaction.amount,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFF1E1E1E),
                      fontFamily: 'Bricolage Grotesque',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              if (showDivider)
                Positioned(
                  left: 15,
                  right: 15,
                  bottom: 0,
                  child: SvgPicture.asset(
                    dividerAsset,
                    height: 1,
                    fit: BoxFit.fill,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}