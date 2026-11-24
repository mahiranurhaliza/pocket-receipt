import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'historyDetailed.dart';

// void main() {
//   runApp(
//     const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: HistoryScreen(),
//     ),
//   );
// }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const _months = ['May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct'];
  static const _days = [
    _HistoryDay(
      'Tuesday, 20 Oct 2026',
      '20 Oct 2026 11:46:18 WIB',
    ),
    _HistoryDay(
      'Monday, 19 Oct 2026',
      '19 Oct 2026 11:46:18 WIB',
    ),
    _HistoryDay(
      'Sunday, 18 Oct 2026',
      '18 Oct 2026 11:46:18 WIB',
    ),
  ];

  int _selectedMonth = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDDDDDD),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final pageHeight = constraints.maxHeight < 900
              ? 900.0
              : constraints.maxHeight;
          final contentWidth =
              (constraints.maxWidth - 50).clamp(0.0, 440.0).toDouble();
          final contentLeft = (constraints.maxWidth - contentWidth) / 2;

          return Stack(
            children: [
              SingleChildScrollView(
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: pageHeight < 1000 ? 1000.0 : pageHeight + 200,
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // --- BACKGROUND RADIAL GRADIENT RESPONSIF ---
                      // Gradien Kuning
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
                              colors: [
                                Color(0xFFFFEC5C),
                                Color(0x00FFEC5C),
                              ],
                              stops: [0.0, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Gradien Oranye
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
                              colors: [
                                Color(0xFFFFB357),
                                Color(0x00FFB357),
                              ],
                              stops: [0.0, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Gradien Ungu
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
                              colors: [
                                Color(0xFFB696E3),
                                Color(0x00B696E3),
                              ],
                              stops: [0.0, 1.0],
                            ),
                          ),
                        ),
                      ),
                      
                      Positioned(
                        width: constraints.maxWidth,
                        height: pageHeight < 1000 ? 1000.0 : pageHeight + 200,
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
                        child: _Header(
                          onBack: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      Positioned(
                        top: 95,
                        left: contentLeft,
                        width: contentWidth,
                        height: 30,
                        child: _MonthSelector(
                          months: _months,
                          selectedIndex: _selectedMonth,
                          onSelected: (index) {
                            setState(() => _selectedMonth = index);
                          },
                        ),
                      ),
                      for (var index = 0; index < _days.length; index++)
                        Positioned(
                          top: 150 + (index * 275),
                          left: contentLeft,
                          width: contentWidth,
                          child: _DayCard(day: _days[index]),
                        ),
                    ],
                  ),
                ),
              ),
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
    return Row(
      children: [
        for (var index = 0; index < months.length; index++) ...[
          Expanded(
            child: _MonthPill(
              label: months[index],
              selected: index == selectedIndex,
              onPressed: () => onSelected(index),
            ),
          ),
          if (index != months.length - 1) const SizedBox(width: 5),
        ],
      ],
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
  const _DayCard({required this.day});

  final _HistoryDay day;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(248, 248, 248, 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
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
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => HistoryDetailedScreen(
                      merchant: day.transactions[index].merchant,
                      dateTime: day.dateTime,
                      products: day.transactions[index].products,
                      total: day.transactions[index].detailTotal,
                      sourceOfFunds:
                          day.transactions[index].sourceOfFunds,
                      category: day.transactions[index].category,
                    ),
                  ),
                );
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

  final _HistoryTransaction transaction;
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

class _HistoryDay {
  const _HistoryDay(this.date, this.dateTime);

  final String date;
  final String dateTime;
  final List<_HistoryTransaction> transactions = const [
    _HistoryTransaction(
      merchant: 'Alfamart',
      amount: 'Rp300.000',
      products: [
        HistoryProduct(name: 'Mineral', price: 'Rp5.000'),
        HistoryProduct(name: 'Ice Cream', price: 'Rp8.000'),
      ],
      detailTotal: 'Rp13.000',
      sourceOfFunds: 'Gopay',
      category: 'Food & Beverages',
    ),
    _HistoryTransaction(
      merchant: 'Indomart',
      amount: 'Rp300.000',
      products: [
        HistoryProduct(name: 'Bread', price: 'Rp12.000'),
        HistoryProduct(name: 'Milk', price: 'Rp18.000'),
      ],
      detailTotal: 'Rp30.000',
      sourceOfFunds: 'BNI',
      category: 'Food & Beverages',
    ),
    _HistoryTransaction(
      merchant: 'Lawson',
      amount: 'Rp300.000',
      products: [
        HistoryProduct(name: 'Coffee', price: 'Rp20.000'),
        HistoryProduct(name: 'Snack', price: 'Rp10.000'),
      ],
      detailTotal: 'Rp30.000',
      sourceOfFunds: 'Shopeepay',
      category: 'Food & Beverages',
    ),
  ];
}

class _HistoryTransaction {
  const _HistoryTransaction({
    required this.merchant,
    required this.amount,
    required this.products,
    required this.detailTotal,
    required this.sourceOfFunds,
    required this.category,
  });

  final String merchant;
  final String amount;
  final List<HistoryProduct> products;
  final String detailTotal;
  final String sourceOfFunds;
  final String category;
}