import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'barchart.dart';

// void main() {
//   runApp(
//     const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: StatisticScreen(),
//     ),
//   );
// }

class StatisticScreen extends StatelessWidget {
  const StatisticScreen({super.key});

  static const _transactions = [
    _Transaction('BNI', Color(0xFFC7E212)),
    _Transaction('Gopay', Color(0xFF00AED6)),
    _Transaction('Shopeepay', Color(0xFFFF6135)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDDDDDD),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth =
              (constraints.maxWidth - 50).clamp(0.0, 355.0).toDouble();
          final contentLeft = (constraints.maxWidth - contentWidth) / 2;
          final pageHeight =
              constraints.maxHeight < 900 ? 900.0 : constraints.maxHeight;

          return SingleChildScrollView(
            child: SizedBox(
              width: constraints.maxWidth,
              height: pageHeight,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // Gradien Kuning[cite: 3]
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
                  // Gradien Oranye[cite: 3]
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
                  // Gradien Ungu[cite: 3]
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
                    height: pageHeight,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0x55F8F8F8), 
                      ),
                    ),
                  ),

                  Positioned(
                    top: -63,
                    left: (constraints.maxWidth - 578) / 2,
                    child: SvgPicture.asset(
                      'assets/8cb8f.svg',
                      width: 578,
                      height: 966,
                      fit: BoxFit.fill,
                    ),
                  ),

                  // --- KONTEN UTAMA DISUSUN MENGGUNAKAN COLUMN AGAR RESPONSIF ---
                  Positioned.fill(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(contentLeft, 40, contentLeft, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Header(
                            onBack: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(height: 10),
                          
                          // Kotak Expense (ResponsiveBarChart)[cite: 3]
                          const _StatisticCard(),
                          
                          const SizedBox(height: 25), // Jarak fleksibel dan seragam
                          
                          // Kotak Tanggal Pertama[cite: 3]
                          const _DayCard(
                            transactions: _transactions,
                          ),
                          
                          const SizedBox(height: 25), // Jarak fleksibel dan seragam
                          
                          // Kotak Tanggal Kedua[cite: 3]
                          const _DayCard(
                            transactions: _transactions,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
            'Your statistic',
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

// Widget Pembungkus yang Menggunakan ResponsiveBarChart[cite: 3]
class _StatisticCard extends StatelessWidget {
  const _StatisticCard();

  static const List<BarChartDataData> _weeklyData = [
    BarChartDataData(label: '14-20', value: 165000, isThisMonth: false),
    BarChartDataData(label: '21-27', value: 220000, isThisMonth: false),
    BarChartDataData(label: '28-4',  value: 330000, isThisMonth: true),
    BarChartDataData(label: '5-11',  value: 150000, isThisMonth: true),
    BarChartDataData(label: '12-18', value: 375000, isThisMonth: true),
    BarChartDataData(label: '19-25', value: 300000, isThisMonth: true, isSelected: true),
  ];

  @override
  Widget build(BuildContext context) {
    return const ResponsiveBarChart(
      items: _weeklyData,
      title: 'This week expense',
      totalExpense: 'Rp231.000',
      maxValue: 440000,
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.transactions});

  final List<_Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const SizedBox(
            height: 40,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 10),
                child: Text(
                  'Tuesday, 20 Oct 2026',
                  style: TextStyle(
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
            width: 355,
            height: 1,
            fit: BoxFit.fill,
          ),
          for (var index = 0; index < transactions.length; index++)
            _TransactionRow(
              transaction: transactions[index],
              showDivider: index != transactions.length - 1,
              dividerAsset:
                  index == 0 ? 'assets/e2b93.svg' : 'assets/8947c.svg',
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
  });

  final _Transaction transaction;
  final bool showDivider;
  final String dividerAsset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 69.6666666667,
      child: Stack(
        children: [
          Positioned(
            left: 10,
            top: 12,
            child: SvgPicture.asset(
              'assets/3a2fc.svg',
              width: 43.205,
              height: 43.205,
            ),
          ),
          const Positioned(
            left: 60,
            top: 14,
            width: 180,
            child: Text(
              'KANTIN GEDUNG BIRU\nPPBS',
              style: TextStyle(
                color: Color(0xFF1E1E1E),
                fontFamily: 'Bricolage Grotesque',
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.2,
              ),
            ),
          ),
          Positioned(
            right: 11,
            top: 10,
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Rp9.972.000',
                  maxLines: 1,
                  style: TextStyle(
                    color: Color(0xFF1E1E1E),
                    fontFamily: 'Bricolage Grotesque',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 14.042,
                      height: 14.042,
                      color: transaction.color,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      transaction.source,
                      style: const TextStyle(
                        color: Color(0xFF1E1E1E),
                        fontFamily: 'Bricolage Grotesque',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showDivider)
            Positioned(
              left: 57,
              right: 13,
              bottom: 0,
              child: SvgPicture.asset(
                dividerAsset,
                width: 285,
                height: 1,
                fit: BoxFit.fill,
              ),
            ),
        ],
      ),
    );
  }
}

class _Transaction {
  const _Transaction(this.source, this.color);

  final String source;
  final Color color;
}