import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'piechart.dart';

// void main() {
//   runApp(
//     const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: PortfolioScreen(),
//     ),
//   );
// }

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({
    super.key,
    this.period = '1 Sep-30 Sep 2026',
    this.expenses = 'Rp1.000.000',
    this.onPreviousPeriod,
    this.onNextPeriod,
    this.onSeeAll,
  });

  final String period;
  final String expenses;
  final VoidCallback? onPreviousPeriod;
  final VoidCallback? onNextPeriod;
  final ValueChanged<String>? onSeeAll;

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final _pageController = PageController();
  int _selectedIndex = 0;

  // Sampel Data Kategori (Warna & Proporsi Nilai Mengikuti referensi)
  static const _categoryItems = [
    _PortfolioItem(
      name: 'BNI',
      amount: 'Rp575.000',
      numericValue: 575000,
      transactions: 'From 23 transactions',
      color: Color(0xFFC7E212),
    ),
    _PortfolioItem(
      name: 'OVO',
      amount: 'Rp120.000',
      numericValue: 120000,
      transactions: 'From 9 transactions',
      color: Color(0xFF793ECC),
    ),
    _PortfolioItem(
      name: 'Cash',
      amount: 'Rp78.000',
      numericValue: 78000,
      transactions: 'From 3 transactions',
      color: Color(0xFF5C5C5C),
    ),
    _PortfolioItem(
      name: 'Gopay',
      amount: 'Rp172.000',
      numericValue: 172000,
      transactions: 'From 4 transactions',
      color: Color(0xFF00AED6),
    ),
    _PortfolioItem(
      name: 'Shopeepay',
      amount: 'Rp55.000',
      numericValue: 55000,
      transactions: 'From 2 transactions',
      color: Color(0xFFFF6135),
    ),
  ];

  static const _pocketItems = [
    _PortfolioItem(
      name: 'Bills',
      amount: 'Rp575.000',
      numericValue: 575000,
      transactions: 'From 23 transactions',
      color: Color(0xFFFFED7E),
    ),
    _PortfolioItem(
      name: 'Top-ups',
      amount: 'Rp78.000',
      numericValue: 78000,
      transactions: 'From 3 transactions',
      color: Color(0xFFD2BFEE),
    ),
    _PortfolioItem(
      name: 'Food & Beverages',
      amount: 'Rp172.000',
      numericValue: 172000,
      transactions: 'From 4 transactions',
      color: Color(0xFFFF9FC6),
    ),
    _PortfolioItem(
      name: 'Transportation',
      amount: 'Rp55.000',
      numericValue: 55000,
      transactions: 'From 2 transactions',
      color: Color(0xFFFFB870),
    ),
    _PortfolioItem(
      name: 'Shopping',
      amount: 'Rp120.000',
      numericValue: 120000,
      transactions: 'From 9 transactions',
      color: Color(0xFF70E5F2),
    ),
  ];

  void _selectTab(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
          final bodyWidth = contentWidth.clamp(0.0, 350.0).toDouble();

          return SingleChildScrollView(
            child: SizedBox(
              width: constraints.maxWidth,
              height: pageHeight,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // --- BACKGROUND RADIAL GRADIENT RESPONSIF (Sesuai home.dart) ---
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
                  // -------------------------------------------------------------

                  Positioned(
                    width: constraints.maxWidth,
                    height: pageHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0x55F8F8F8), 
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
                    top: 90,
                    left: contentLeft,
                    width: contentWidth,
                    child: _PeriodCard(
                      period: widget.period,
                      expenses: widget.expenses,
                      onPrevious: widget.onPreviousPeriod,
                      onNext: widget.onNextPeriod,
                    ),
                  ),
                  Positioned(
                    top: 200,
                    left: contentLeft,
                    width: contentWidth,
                    child: _SlidingTabs(
                      selectedIndex: _selectedIndex,
                      onSelected: _selectTab,
                    ),
                  ),
                  Positioned(
                    top: 270,
                    left: contentLeft + (contentWidth - bodyWidth) / 2,
                    width: bodyWidth,
                    height: 630,
                    child: ClipRect(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          if (_selectedIndex != index) {
                            setState(() => _selectedIndex = index);
                          }
                        },
                        children: [
                          _PortfolioContent(
                            items: _categoryItems,
                            onSeeAll: widget.onSeeAll,
                          ),
                          _PortfolioContent(
                            items: _pocketItems,
                            onSeeAll: widget.onSeeAll,
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
            'Your portfolio',
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

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    required this.period,
    required this.expenses,
    this.onPrevious,
    this.onNext,
  });

  final String period;
  final String expenses;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.fromLTRB(5, 4, 5, 5),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(248, 248, 248, 0.87),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 45,
            child: Row(
              children: [
                _PeriodArrow(
                  asset: 'assets/0da99.svg',
                  onPressed: onPrevious,
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Period',
                        style: TextStyle(
                          color: Color(0xFF1E1E1E),
                          fontFamily: 'Bricolage Grotesque',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.05,
                        ),
                      ),
                      Text(
                        period,
                        style: const TextStyle(
                          color: Color(0xFF1E1E1E),
                          fontFamily: 'Bricolage Grotesque',
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.05,
                        ),
                      ),
                    ],
                  ),
                ),
                _PeriodArrow(
                  asset: 'assets/d88c0.svg',
                  onPressed: onNext,
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFBDBDB),
              border: Border.all(color: const Color(0xFFE42525)),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Text(
              expenses,
              style: const TextStyle(
                color: Color(0xFFE42525),
                fontFamily: 'Bricolage Grotesque',
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodArrow extends StatelessWidget {
  const _PeriodArrow({required this.asset, this.onPressed});

  final String asset;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Center(
          child: SvgPicture.asset(asset, width: 12, height: 9),
        ),
      ),
    );
  }
}

class _SlidingTabs extends StatelessWidget {
  const _SlidingTabs({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(248, 248, 248, 0.87),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pillWidth = (constraints.maxWidth - 10) / 2;
          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                alignment: selectedIndex == 0
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  width: pillWidth,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 179, 87, 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              Row(
                children: [
                  _TabButton(
                    label: 'Category',
                    onPressed: () => onSelected(0),
                  ),
                  _TabButton(
                    label: 'Pocket',
                    onPressed: () => onSelected(1),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1E1E1E),
              fontFamily: 'Bricolage Grotesque',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _PortfolioContent extends StatelessWidget {
  const _PortfolioContent({
    super.key,
    required this.items,
    this.onSeeAll,
  });

  final List<_PortfolioItem> items;
  final ValueChanged<String>? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final pieData = items
        .map((item) => PieCategoryData(
              label: item.name,
              value: item.numericValue,
              color: item.color,
            ))
        .toList();

    return Column(
      children: [
        ResponsivePieChart(
          categories: pieData,
          chartSize: 200,
        ),
        const SizedBox(height: 30),
        ...List.generate(
          items.length,
          (index) => _PortfolioRow(
            item: items[index],
            showTopBorder: index != 0,
            onSeeAll: onSeeAll == null
                ? null
                : () => onSeeAll!(items[index].name),
          ),
        ),
      ],
    );
  }
}

class _PortfolioRow extends StatelessWidget {
  const _PortfolioRow({
    required this.item,
    required this.showTopBorder,
    this.onSeeAll,
  });

  final _PortfolioItem item;
  final bool showTopBorder;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        border: showTopBorder
            ? const Border(top: BorderSide(color: Color(0xFF1E1E1E)))
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(12, 6, 9, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 15,
            height: 15,
            margin: const EdgeInsets.only(top: 5),
            color: item.color,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Color(0xFF1E1E1E),
                    fontFamily: 'Bricolage Grotesque',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
                Text(
                  item.amount,
                  style: _detailStyle,
                ),
                Text(
                  item.transactions,
                  style: _detailStyle,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1E1E1E),
              padding: const EdgeInsets.fromLTRB(8, 18, 0, 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'See all',
              style: TextStyle(
                fontFamily: 'Bricolage Grotesque',
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _detailStyle = TextStyle(
    color: Color(0xFF1E1E1E),
    fontFamily: 'Bricolage Grotesque',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
}

class _PortfolioItem {
  const _PortfolioItem({
    required this.name,
    required this.amount,
    required this.numericValue,
    required this.transactions,
    required this.color,
  });

  final String name;
  final String amount;
  final double numericValue;
  final String transactions;
  final Color color;
}