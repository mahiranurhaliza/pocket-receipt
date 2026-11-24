import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'historyDetailed.dart';

class ScanDetailedScreen extends StatefulWidget {
  const ScanDetailedScreen({
    super.key,
    this.receiptBytes,
  });

  final Uint8List? receiptBytes;

  @override
  State<ScanDetailedScreen> createState() => _ScanDetailedScreenState();
}

class _ScanDetailedScreenState extends State<ScanDetailedScreen> {
  late final TextEditingController _merchantController;
  late List<_ScanProductDraft> _products;
  String _sourceOfFunds = 'Gopay';
  String _category = 'Food & Beverages';

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(text: 'Alfamart');
    _products = [
      _ScanProductDraft(name: 'Mineral', price: '5000'),
      _ScanProductDraft(name: 'Ice cream', price: '8000'),
    ];
  }

  void _addProduct() {
    setState(() {
      _products.add(_ScanProductDraft(name: '', price: '0'));
    });
  }

  void _removeProduct(int index) {
    if (_products.length == 1) return;
    final removed = _products.removeAt(index);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  Future<void> _cancelReceipt() async {
    final discard = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Discard receipt',
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                child: const ColoredBox(
                  color: Color.fromRGBO(30, 30, 30, 0.25),
                ),
              ),
            ),
            Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 300,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    border: Border.all(color: const Color(0xFFCCCCCC)),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.08),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 45),
                      const SizedBox(
                        width: 250,
                        child: Text.rich(
                          TextSpan(
                            style: TextStyle(
                              color: Color(0xFF1E1E1E),
                              fontFamily: 'Bricolage Grotesque',
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                            ),
                            children: [
                              TextSpan(text: 'Are you sure want to '),
                              TextSpan(
                                text: 'discard',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              TextSpan(text: ' this receipt?'),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ReceiptButton(
                            label: 'Discard',
                            fill: const Color.fromRGBO(235, 93, 93, 0.5),
                            border: const Color(0xFFE42525),
                            onPressed: () => Navigator.of(context).pop(true),
                          ),
                          const SizedBox(width: 10),
                          _ReceiptButton(
                            label: 'Cancel',
                            fill: const Color(0xFFCCCCCC),
                            border: const Color(0xFFAAAAAA),
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (discard == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _saveReceipt() {
    final products = _products
        .where((product) => product.name.text.trim().isNotEmpty)
        .map(
          (product) => HistoryProduct(
            name: product.name.text.trim(),
            price: _formatReceiptPrice(_parseReceiptPrice(product.price.text)),
            quantity: int.tryParse(product.quantity.text) ?? 1,
          ),
        )
        .toList();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => HistoryDetailedScreen(
          merchant: _merchantController.text.trim().isEmpty
              ? 'Alfamart'
              : _merchantController.text.trim(),
          products: products.isEmpty
              ? const [
                  HistoryProduct(name: 'Mineral', price: 'Rp5.000'),
                  HistoryProduct(name: 'Ice cream', price: 'Rp8.000'),
                ]
              : products,
          sourceOfFunds: _sourceOfFunds,
          category: _category,
          receiptBytes: widget.receiptBytes,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _merchantController.dispose();
    for (final product in _products) {
      product.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final pageHeight = constraints.maxHeight < 900
              ? 900.0
              : constraints.maxHeight;
          final contentWidth =
              (constraints.maxWidth - 50).clamp(0.0, 440.0).toDouble();
          final contentLeft = (constraints.maxWidth - contentWidth) / 2;
          final tileGap = contentWidth >= 355 ? 25.0 : 16.0;
          final tileWidth = (contentWidth - tileGap) / 2;

          return SingleChildScrollView(
            child: SizedBox(
              width: constraints.maxWidth,
              height: pageHeight,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  if (widget.receiptBytes != null)
                    Positioned(
                      width: constraints.maxWidth,
                      height: pageHeight,
                      child: Image.memory(widget.receiptBytes!, fit: BoxFit.cover),
                    ),
                  Positioned(
                    top: 0,
                    width: constraints.maxWidth,
                    child: SvgPicture.asset(
                      'assets/cover/header.svg',
                      width: contentWidth,
                      height: 150,
                      fit: BoxFit.fill,
                      placeholderBuilder: (_) => _HeaderGradientFallback(
                        width: contentWidth,
                        height: 150,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    left: contentLeft + 5,
                    child: SizedBox(
                      width: 30,
                      height: 40,
                      child: InkWell(
                        onTap: _cancelReceipt,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SvgPicture.asset(
                            'assets/icons/back.svg',
                            width: 22,
                            height: 17,
                            placeholderBuilder: (_) => const Icon(
                              Icons.arrow_back,
                              size: 20,
                              color: Color(0xFF1E1E1E),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 250,
                    width: constraints.maxWidth,
                    height: pageHeight - 250,
                    child: SvgPicture.asset(
                      'assets/cover/bg-2.svg',
                      width: contentWidth,
                      height: pageHeight - 250,
                      fit: BoxFit.fill,
                      placeholderBuilder: (_) => Container(
                        width: contentWidth,
                        height: pageHeight - 250,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF4F4F4),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(48),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 300,
                    left: contentLeft,
                    width: contentWidth,
                    child: Column(
                      children: [
                        SizedBox(
                          width: tileWidth,
                          height: 30,
                          child: _ReceiptTextField(
                            controller: _merchantController,
                            textAlign: TextAlign.center,
                            style: _receiptTitleStyle,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const _ReceiptSectionHeader(title: 'Products'),
                        const SizedBox(height: 5),
                        for (var index = 0; index < _products.length; index++)
                          _ScanProductRow(
                            product: _products[index],
                            tileGap: tileGap,
                            tileWidth: tileWidth,
                            onRemove: () => _removeProduct(index),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 3, bottom: 5),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _ReceiptAssetButton(
                              asset: 'assets/icons/add.svg',
                              fallbackIcon: Icons.add_circle,
                              iconColor: const Color(0xFF3BB273),
                              onPressed: _addProduct,
                            ),
                          ),
                        ),
                        _ReceiptTotal(products: _products),
                        const SizedBox(height: 10),
                        const _ReceiptSectionHeader(title: 'Source of funds'),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(5, 5, 5, 10),
                          child: _ReceiptDropdown(
                            value: _sourceOfFunds,
                            options: const [
                              'Gopay',
                              'BNI',
                              'Shopeepay',
                              'Cash',
                            ],
                            onChanged: (value) {
                              setState(() => _sourceOfFunds = value);
                            },
                          ),
                        ),
                        const _ReceiptSectionHeader(title: 'Category'),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
                          child: _ReceiptDropdown(
                            value: _category,
                            options: const [
                              'Food & Beverages',
                              'Shopping',
                              'Transport',
                              'Bills',
                            ],
                            onChanged: (value) {
                              setState(() => _category = value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: pageHeight - 100,
                    left: contentLeft,
                    width: contentWidth,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ReceiptButton(
                          label: 'Cancel',
                          fill: const Color.fromRGBO(235, 93, 93, 0.5),
                          border: const Color(0xFFE42525),
                          onPressed: _cancelReceipt,
                        ),
                        SizedBox(width: tileGap),
                        _ReceiptButton(
                          label: 'Save',
                          fill: const Color.fromRGBO(59, 178, 115, 0.5),
                          border: const Color(0xFF05922B),
                          onPressed: _saveReceipt,
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

class _HeaderGradientFallback extends StatelessWidget {
  const _HeaderGradientFallback({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned(
            left: -width * 0.15,
            top: -height * 0.4,
            child: Container(
              width: width * 0.72,
              height: width * 0.72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x66C7A4E8), Color(0x00C7A4E8)],
                ),
              ),
            ),
          ),
          Positioned(
            right: -width * 0.12,
            top: -height * 0.25,
            child: Container(
              width: width * 0.78,
              height: width * 0.78,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x88FFE66D), Color(0x00FFE66D)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanProductRow extends StatelessWidget {
  const _ScanProductRow({
    required this.product,
    required this.tileGap,
    required this.tileWidth,
    required this.onRemove,
  });

  final _ScanProductDraft product;
  final double tileGap;
  final double tileWidth;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Stack(
        children: [
          Positioned(
            left: 5,
            width: tileWidth,
            top: 0,
            height: 25,
            child: _ReceiptTextField(controller: product.name),
          ),
          Positioned(
            left: 5,
            width: tileWidth * 0.5,
            top: 27,
            height: 25,
            child: _ReceiptTextField(
              controller: product.price,
              keyboardType: TextInputType.number,
            ),
          ),
          Positioned(
            left: tileWidth + tileGap,
            width: tileWidth * 0.35,
            top: 27,
            height: 25,
            child: _ReceiptTextField(
              controller: product.quantity,
              textAlign: TextAlign.center,
              prefixText: 'x',
              keyboardType: TextInputType.number,
            ),
          ),
          Positioned(
            right: 30,
            top: 27,
            width: tileWidth * 0.45,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: product.price,
              builder: (context, value, child) {
                return Text(
                  _formatReceiptPrice(_parseReceiptPrice(value.text)),
                  textAlign: TextAlign.right,
                  style: _receiptRegularStyle,
                );
              },
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: _ReceiptAssetButton(
              asset: 'assets/icons/remove.svg',
              fallbackIcon: Icons.remove_circle,
              iconColor: const Color(0xFFEB5D5D),
              onPressed: onRemove,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptTotal extends StatelessWidget {
  const _ReceiptTotal({required this.products});

  final List<_ScanProductDraft> products;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        for (final product in products) ...[
          product.price,
          product.quantity,
        ],
      ]),
      builder: (context, child) {
        final total = products.fold<int>(
          0,
          (sum, product) =>
              sum +
              (_parseReceiptPrice(product.price.text) *
                  (int.tryParse(product.quantity.text) ?? 1)),
        );
        return SizedBox(
          height: 30,
          child: Stack(
            children: [
              const Positioned.fill(
                child: CustomPaint(painter: _ReceiptDashedPainter()),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Total', style: _receiptRegularStyle),
                    ),
                    Text(
                      _formatReceiptPrice(total),
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
        );
      },
    );
  }
}

class _ReceiptSectionHeader extends StatelessWidget {
  const _ReceiptSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 5),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFAAAAAA))),
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

class _ReceiptTextField extends StatelessWidget {
  const _ReceiptTextField({
    required this.controller,
    this.textAlign = TextAlign.left,
    this.style = _receiptRegularStyle,
    this.prefixText,
    this.keyboardType,
  });

  final TextEditingController controller;
  final TextAlign textAlign;
  final TextStyle style;
  final String? prefixText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: textAlign,
      keyboardType: keyboardType,
      style: style,
      decoration: InputDecoration(
        prefixText: prefixText,
        prefixStyle: style,
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        enabledBorder: _receiptInputBorder,
        focusedBorder: _receiptInputBorder.copyWith(
          borderSide: const BorderSide(color: Color(0xFF999999)),
        ),
      ),
    );
  }
}

class _ReceiptDropdown extends StatelessWidget {
  const _ReceiptDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 25,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        iconSize: 10,
        icon: SvgPicture.asset(
          'assets/icons/dropdown.svg',
          width: 10,
          height: 8,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => const Icon(
            Icons.arrow_drop_down,
            size: 10,
            color: Color(0xFF1E1E1E),
          ),
        ),
        style: _receiptRegularStyle,
        decoration: const InputDecoration(
          filled: true,
          fillColor: Color(0xFFF8F8F8),
          contentPadding: EdgeInsets.symmetric(horizontal: 5),
          enabledBorder: _receiptInputBorder,
          focusedBorder: _receiptInputBorder,
        ),
        items: [
          for (final option in options)
            DropdownMenuItem(value: option, child: Text(option)),
        ],
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class _ReceiptButton extends StatelessWidget {
  const _ReceiptButton({
    required this.label,
    required this.fill,
    required this.border,
    required this.onPressed,
  });

  final String label;
  final Color fill;
  final Color border;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fill,
      shape: StadiumBorder(side: BorderSide(color: border)),
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: SizedBox(
          width: 100,
          height: 40,
          child: Center(
            child: Text(label, style: _receiptRegularStyle),
          ),
        ),
      ),
    );
  }
}

class _ReceiptAssetButton extends StatelessWidget {
  const _ReceiptAssetButton({
    required this.asset,
    required this.fallbackIcon,
    required this.iconColor,
    required this.onPressed,
  });

  final String asset;
  final IconData fallbackIcon;
  final Color iconColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 25,
        height: 25,
        child: Center(
          child: SvgPicture.asset(
            asset,
            placeholderBuilder: (_) => Icon(
              fallbackIcon,
              size: 22,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptDashedPainter extends CustomPainter {
  const _ReceiptDashedPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFAAAAAA)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 14) {
      canvas.drawLine(
        Offset(x, 0.5),
        Offset((x + 8).clamp(0.0, size.width).toDouble(), 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ReceiptDashedPainter oldDelegate) => false;
}

class _ScanProductDraft {
  _ScanProductDraft({required String name, required String price})
      : name = TextEditingController(text: name),
        price = TextEditingController(text: price),
        quantity = TextEditingController(text: '1');

  final TextEditingController name;
  final TextEditingController price;
  final TextEditingController quantity;

  void dispose() {
    name.dispose();
    price.dispose();
    quantity.dispose();
  }
}

int _parseReceiptPrice(String value) {
  return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
}

String _formatReceiptPrice(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
    buffer.write(digits[index]);
  }
  return 'Rp$buffer';
}

const _receiptInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(5)),
  borderSide: BorderSide(color: Color(0xFFCCCCCC)),
);

const _receiptTitleStyle = TextStyle(
  color: Colors.black,
  fontFamily: 'Bricolage Grotesque',
  fontSize: 25,
  fontWeight: FontWeight.w600,
  height: 0.8,
);

const _receiptRegularStyle = TextStyle(
  color: Color(0xFF1E1E1E),
  fontFamily: 'Bricolage Grotesque',
  fontSize: 15,
  fontWeight: FontWeight.w400,
  height: 1.3333333333,
);