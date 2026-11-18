import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'services/database_service.dart';

class HistoryDetailedScreen extends StatefulWidget {
  const HistoryDetailedScreen({
    super.key,
    this.receiptId,
    this.merchant = 'Alfamart',
    this.dateTime = '20 Oct 2026 11:46:18 WIB',
    this.products = const [
      HistoryProduct(name: 'Mineral', price: 'Rp5.000'),
      HistoryProduct(name: 'Ice Cream', price: 'Rp8.000'),
    ],
    this.total = 'Rp13.000',
    this.sourceOfFunds = 'Cash',
    this.category = 'Food & Beverages',
    this.receiptAsset,
  });

  final int? receiptId;
  final String merchant;
  final String dateTime;
  final List<HistoryProduct> products;
  final String total;
  final String sourceOfFunds;
  final String category;
  final String? receiptAsset;

  @override
  State<HistoryDetailedScreen> createState() => _HistoryDetailedScreenState();
}

class _HistoryDetailedScreenState extends State<HistoryDetailedScreen> {
  late String _currentSourceOfFunds;

  static const List<String> _fundSources = [
    'Cash',
    'GoPay',
    'OVO',
    'DANA',
    'ShopeePay',
    'BCA',
    'BNI',
    'Mandiri',
  ];

  @override
  void initState() {
    super.initState();
    _currentSourceOfFunds = widget.sourceOfFunds;
  }

  void _openFullScreenImage() {
    final path = widget.receiptAsset;
    if (path == null || path.isEmpty) return;

    final file = File(path);
    final isLocalFile = file.existsSync();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              widget.merchant,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Bricolage Grotesque',
                fontSize: 18,
              ),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: isLocalFile
                  ? Image.file(file, fit: BoxFit.contain)
                  : Image.asset(path, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditSourceDialog() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFFF8F8F8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Sumber Dana (Source of funds)',
                  style: TextStyle(
                    color: Color(0xFF1E1E1E),
                    fontFamily: 'Bricolage Grotesque',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _fundSources.map((source) {
                    final isSelected = source == _currentSourceOfFunds;
                    return ChoiceChip(
                      label: Text(
                        source,
                        style: TextStyle(
                          fontFamily: 'Bricolage Grotesque',
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF1E1E1E),
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFFF05A5A),
                      backgroundColor: Colors.white,
                      onSelected: (_) => Navigator.of(ctx).pop(source),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && selected != _currentSourceOfFunds) {
      if (widget.receiptId != null) {
        await DatabaseService.instance.updateReceiptSourceOfFunds(
          widget.receiptId!,
          selected,
        );
      }
      if (!mounted) return;
      setState(() => _currentSourceOfFunds = selected);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Sumber dana diubah menjadi $selected')),
        );
    }
  }

  Widget _buildReceiptPreview() {
    final path = widget.receiptAsset;
    if (path == null || path.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada foto struk',
          style: TextStyle(
            color: Color(0xFF888888),
            fontFamily: 'Bricolage Grotesque',
            fontSize: 14,
          ),
        ),
      );
    }

    final file = File(path);
    final imageWidget = file.existsSync()
        ? Image.file(file, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
        : Image.asset(
            path,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => const Center(
              child: Text(
                'Gambar struk tidak ditemukan',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontFamily: 'Bricolage Grotesque',
                  fontSize: 14,
                ),
              ),
            ),
          );

    return GestureDetector(
      onTap: _openFullScreenImage,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageWidget,
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.zoom_in, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Perbesar',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Bricolage Grotesque',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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

          return SingleChildScrollView(
            child: SizedBox(
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
                      widget.merchant,
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
                      child: _buildReceiptPreview(),
                    ),
                  ),
                  Positioned(
                    top: 325,
                    left: contentLeft,
                    width: contentWidth,
                    child: Text(
                      widget.dateTime,
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
                        _ProductsSection(
                          products: widget.products,
                          total: widget.total,
                        ),
                        const SizedBox(height: 10),
                        _DetailSection(
                          title: 'Source of funds',
                          value: _currentSourceOfFunds,
                          onEdit: _showEditSourceDialog,
                        ),
                        const SizedBox(height: 10),
                        _DetailSection(
                          title: 'Category',
                          value: widget.category,
                        ),
                      ],
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
  const _DetailSection({
    required this.title,
    required this.value,
    this.onEdit,
  });

  final String title;
  final String value;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Column(
        children: [
          _SectionHeader(title: title),
          InkWell(
            onTap: onEdit,
            child: SizedBox(
              height: 30,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _regularStyle,
                      ),
                    ),
                    if (onEdit != null)
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 15, color: Color(0xFFF05A5A)),
                          SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: TextStyle(
                              color: Color(0xFFF05A5A),
                              fontFamily: 'Bricolage Grotesque',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
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