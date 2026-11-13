import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HistoryDetailedScreen(),
    ),
  );
}

class HistoryDetailedScreen extends StatelessWidget {
  const HistoryDetailedScreen({
    super.key,
    this.merchant = 'Alfamart',
    this.dateTime = '20 Oct 2026 11:46:18 WIB',
    this.products = const [
      HistoryProduct(name: 'Mineral', price: 'Rp5.000'),
      HistoryProduct(name: 'Ice Cream', price: 'Rp8.000'),
    ],
    this.total = 'Rp13.000',
    this.sourceOfFunds = 'Gopay',
    this.category = 'Food & Beverages',
    this.receiptAsset,
  });

  final String merchant;
  final String dateTime;
  final List<HistoryProduct> products;
  final String total;
  final String sourceOfFunds;
  final String category;
  final String? receiptAsset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDDDDDD),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth =
              (constraints.maxWidth - 50).clamp(0.0, 355.0).toDouble();
          final contentLeft = (constraints.maxWidth - contentWidth) / 2;
          final receiptWidth = contentWidth.clamp(0.0, 300.0).toDouble();
          final pageHeight =
              constraints.maxHeight < 900 ? 900.0 : constraints.maxHeight;

          return SizedBox(
            width: constraints.maxWidth,
            height: pageHeight,
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
                    height: pageHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0x55F8F8F8), 
                      ),
                    ),
                  ),

                Positioned(
                  top: -63,
                  left: (constraints.maxWidth - 578) / 2,
                  child: SvgPicture.asset(
                    'assets/58487.svg',
                    width: 578,
                    height: 963,
                    fit: BoxFit.fill,
                  ),
                ),
                Positioned(
                  top: 40,
                  left: contentLeft,
                  child: SizedBox(
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
                ),
                Positioned(
                  top: 90,
                  left: contentLeft,
                  width: contentWidth,
                  child: Text(
                    merchant,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontFamily: 'Bricolage Grotesque',
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                      height: 0.8,
                    ),
                  ),
                ),
                Positioned(
                  top: 120,
                  left: (constraints.maxWidth - receiptWidth) / 2,
                  width: receiptWidth,
                  height: 200,
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: receiptAsset == null
                        ? null
                        : Image.asset(receiptAsset!, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  top: 325,
                  left: contentLeft,
                  width: contentWidth,
                  child: Text(
                    dateTime,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1E1E1E),
                      fontFamily: 'Bricolage Grotesque',
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Positioned(
                  top: 368,
                  left: contentLeft,
                  width: contentWidth,
                  child: Column(
                    children: [
                      _ProductsSection(products: products, total: total),
                      const SizedBox(height: 10),
                      _DetailSection(
                        title: 'Source of funds',
                        value: sourceOfFunds,
                      ),
                      const SizedBox(height: 10),
                      _DetailSection(title: 'Category', value: category),
                    ],
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

class _ProductsSection extends StatelessWidget {
  const _ProductsSection({required this.products, required this.total});

  final List<HistoryProduct> products;
  final String total;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: Column(
        children: [
          const _SectionHeader(title: 'Products'),
          SizedBox(
            height: 50,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      products.map((product) => product.name).join('\n'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _regularStyle,
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      products.map((product) => product.price).join('\n'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: _regularStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 30,
            child: Stack(
              children: [
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _DashedDivider(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('Total', style: _regularStyle),
                      ),
                      Text(
                        total,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Color(0xFF1E1E1E),
                          fontFamily: 'Bricolage Grotesque',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Column(
        children: [
          _SectionHeader(title: title),
          SizedBox(
            height: 30,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 5),
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _regularStyle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 5),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFAAAAAA)),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1E1E1E),
          fontFamily: 'Bricolage Grotesque',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: double.infinity,
      height: 1,
      child: CustomPaint(painter: _DashedDividerPainter()),
    );
  }
}

class _DashedDividerPainter extends CustomPainter {
  const _DashedDividerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFAAAAAA)
      ..strokeWidth = 1;
    const dashWidth = 8.0;
    const dashGap = 6.0;

    for (var x = 0.0; x < size.width; x += dashWidth + dashGap) {
      canvas.drawLine(
        Offset(x, 0.5),
        Offset((x + dashWidth).clamp(0.0, size.width).toDouble(), 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedDividerPainter oldDelegate) => false;
}

class HistoryProduct {
  const HistoryProduct({required this.name, required this.price});

  final String name;
  final String price;
}

const _regularStyle = TextStyle(
  color: Color(0xFF1E1E1E),
  fontFamily: 'Bricolage Grotesque',
  fontSize: 15,
  fontWeight: FontWeight.w400,
  height: 1.3333333333,
);
