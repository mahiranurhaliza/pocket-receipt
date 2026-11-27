// ignore: duplicate_ignore
// ignore: file_names
// ignore_for_file: file_names

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../database/receipt_model.dart';
import 'historyDetailed.dart';

typedef ScanSaveCallback = Future<void> Function({
  required String merchant,
  required List<ReceiptItem> items,
  required String sourceOfFunds,
  required String category,
});

class ScanDetailedScreen extends StatefulWidget {
  const ScanDetailedScreen({
    super.key,
    this.receiptBytes,
    this.initialMerchant,
    this.initialItems,
    this.onSave,
  });

  final Uint8List? receiptBytes;
  final String? initialMerchant;
  final List<ReceiptItem>? initialItems;
  final ScanSaveCallback? onSave;

  @override
  State<ScanDetailedScreen> createState() => _ScanDetailedScreenState();
}

class _ScanDetailedScreenState extends State<ScanDetailedScreen> {
  static const List<String> _fundSourceOptions = [
    'Cash',
    'GoPay',
    'OVO',
    'DANA',
    'ShopeePay',
    'BCA',
    'BNI',
    'BRI',
    'Mandiri',
  ];

  static const List<String> _categoryOptions = [
    'Food & Beverages',
    'Shopping',
    'Transport',
    'Bills',
    'Others',
  ];

  late final TextEditingController _merchantController;
  late List<_ScanProductDraft> _products;
  late String _sourceOfFunds;
  late String _category;
  bool _saving = false;

  String _normalizeOption(String value, List<String> options) {
    if (options.contains(value)) return value;
    final lower = value.trim().toLowerCase();
    for (final option in options) {
      if (option.toLowerCase() == lower) return option;
    }
    return options.first;
  }

  @override
  void initState() {
    super.initState();
    final merchantText = (widget.initialMerchant != null &&
            widget.initialMerchant!.trim().isNotEmpty)
        ? widget.initialMerchant!.trim()
        : 'Alfamart';
    _merchantController = TextEditingController(text: merchantText);

    _sourceOfFunds = _normalizeOption('GoPay', _fundSourceOptions);
    _category = _normalizeOption('Food & Beverages', _categoryOptions);

    if (widget.initialItems != null && widget.initialItems!.isNotEmpty) {
      _products = widget.initialItems!
          .map(
            (item) => _ScanProductDraft(
              name: item.name,
              price: item.price.round().toString(),
              quantity: item.quantity > 0 ? item.quantity.toString() : '1',
            ),
          )
          .toList();
    } else {
      _products = [
        _ScanProductDraft(name: 'Mineral', price: '5000'),
        _ScanProductDraft(name: 'Ice cream', price: '8000'),
      ];
    }
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

  void _handleBackButton() {
    if (_saving) return;
    Navigator.of(context).pop();
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

  Future<void> _saveReceipt() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final merchantName = _merchantController.text.trim().isEmpty
          ? 'Alfamart'
          : _merchantController.text.trim();

      final parsedItems = _products
          .where((product) => product.name.text.trim().isNotEmpty)
          .map(
            (product) => ReceiptItem(
              name: product.name.text.trim(),
              quantity: (int.tryParse(product.quantity.text) ?? 1) > 0
                  ? (int.tryParse(product.quantity.text) ?? 1)
                  : 1,
              price: _parseReceiptPrice(product.price.text).toDouble(),
            ),
          )
          .toList();

      final effectiveItems = parsedItems.isEmpty
          ? [
              ReceiptItem(
                name: merchantName,
                quantity: 1,
                price: _products
                    .fold<int>(
                      0,
                      (sum, p) =>
                          sum +
                          (_parseReceiptPrice(p.price.text) *
                              (int.tryParse(p.quantity.text) ?? 1)),
                    )
                    .toDouble(),
              ),
            ]
          : parsedItems;

      if (widget.onSave != null) {
        await widget.onSave!(
          merchant: merchantName,
          items: effectiveItems,
          sourceOfFunds: _sourceOfFunds,
          category: _category,
        );
        return;
      }

      if (!mounted) return;
      final historyProducts = effectiveItems
          .map(
            (item) => HistoryProduct(
              name: item.name,
              price: _formatReceiptPrice(item.price.round()),
              rawPrice: item.price,
              quantity: item.quantity,
            ),
          )
          .toList();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => HistoryDetailedScreen(
            merchant: merchantName,
            products: historyProducts,
            sourceOfFunds: _sourceOfFunds,
            category: _category,
            receiptBytes: widget.receiptBytes,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
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
    final safeSource = _normalizeOption(_sourceOfFunds, _fundSourceOptions);
    final safeCategory = _normalizeOption(_category, _categoryOptions);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth =
              (constraints.maxWidth - 40).clamp(0.0, 460.0).toDouble();
          final tileGap = contentWidth >= 355 ? 20.0 : 14.0;
          final tileWidth = (contentWidth - tileGap) / 2;

          return Stack(
            children: [
              Positioned.fill(
                child: widget.receiptBytes != null
                    ? InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 3.5,
                        child: Center(
                          child: Image.memory(
                            widget.receiptBytes!,
                            fit: BoxFit.contain,
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                          ),
                        ),
                      )
                    : Container(
                        color: const Color(0xFF2A2A2A),
                        alignment: Alignment.center,
                        child: const Text(
                          'Preview Struk',
                          style: TextStyle(
                            color: Colors.white70,
                            fontFamily: 'Bricolage Grotesque',
                            fontSize: 16,
                          ),
                        ),
                      ),
              ),
              Positioned(
                top: 40,
                left: 20,
                child: SafeArea(
                  top: false,
                  child: Material(
                    color: const Color(0xCCFFFFFF),
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: InkWell(
                      onTap: _handleBackButton,
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/icons/back.svg',
                            width: 20,
                            height: 16,
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
                ),
              ),
              DraggableScrollableSheet(
                initialChildSize: 0.62,
                minChildSize: 0.16,
                maxChildSize: 0.92,
                snap: true,
                snapSizes: const [0.16, 0.62, 0.92],
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4F4F4),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(36),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x29000000),
                          blurRadius: 18,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(
                        (constraints.maxWidth - contentWidth) / 2,
                        10,
                        (constraints.maxWidth - contentWidth) / 2,
                        32,
                      ),
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFBDBDBD),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: contentWidth,
                          height: 42,
                          child: _ReceiptTextField(
                            controller: _merchantController,
                            textAlign: TextAlign.center,
                            style: _receiptTitleStyle,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const _ReceiptSectionHeader(title: 'Products'),
                        const SizedBox(height: 8),
                        for (var index = 0; index < _products.length; index++)
                          _ScanProductRow(
                            product: _products[index],
                            tileGap: tileGap,
                            tileWidth: tileWidth,
                            onRemove: () => _removeProduct(index),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 6, bottom: 8),
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
                        const SizedBox(height: 14),
                        const _ReceiptSectionHeader(title: 'Source of funds'),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(5, 8, 5, 14),
                          child: _ReceiptDropdown(
                            value: safeSource,
                            options: _fundSourceOptions,
                            onChanged: (value) {
                              setState(() => _sourceOfFunds = value);
                            },
                          ),
                        ),
                        const _ReceiptSectionHeader(title: 'Category'),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(5, 8, 5, 22),
                          child: _ReceiptDropdown(
                            value: safeCategory,
                            options: _categoryOptions,
                            onChanged: (value) {
                              setState(() => _category = value);
                            },
                          ),
                        ),
                        Row(
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
                              label: _saving ? 'Saving...' : 'Save',
                              fill: const Color.fromRGBO(59, 178, 115, 0.5),
                              border: const Color(0xFF05922B),
                              onPressed: _saving ? () {} : _saveReceipt,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
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
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: false,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9.]*')),
                ],
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
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            Positioned(
              right: 30,
              top: 27,
              width: tileWidth * 0.45,
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: product.price,
                builder: (context, value, child) {
                  return ValueListenableBuilder<TextEditingValue>(
                    valueListenable: product.quantity,
                    builder: (context, qtyValue, _) {
                      final qty = (int.tryParse(qtyValue.text.trim()) ?? 1)
                          .clamp(1, 999999);
                      final subtotal = _parseReceiptPrice(value.text) * qty;
                      return Text(
                        _formatReceiptPrice(subtotal),
                        textAlign: TextAlign.right,
                        style: _receiptRegularStyle,
                      );
                    },
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
                  ((int.tryParse(product.quantity.text.trim()) ?? 1)
                      .clamp(1, 999999))),
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
    this.inputFormatters,
  });

  final TextEditingController controller;
  final TextAlign textAlign;
  final TextStyle style;
  final String? prefixText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: textAlign,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: style,
      decoration: InputDecoration(
        prefixText: prefixText,
        prefixStyle: style,
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
    final safeValue = options.contains(value) ? value : options.first;

    return SizedBox(
      height: 36,
      child: DropdownButtonFormField<String>(
        initialValue: safeValue,
        isExpanded: true,
        iconSize: 14,
        icon: SvgPicture.asset(
          'assets/icons/dropdown.svg',
          width: 10,
          height: 8,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => const Icon(
            Icons.arrow_drop_down,
            size: 16,
            color: Color(0xFF1E1E1E),
          ),
        ),
        style: _receiptRegularStyle,
        decoration: const InputDecoration(
          filled: true,
          fillColor: Color(0xFFF8F8F8),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
  _ScanProductDraft({
    required String name,
    required String price,
    String quantity = '1',
  })  : name = TextEditingController(text: name),
        price = TextEditingController(text: price),
        quantity = TextEditingController(text: quantity);

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
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 0;
  final isNegative = trimmed.startsWith('-') ||
      (trimmed.startsWith('(') && trimmed.endsWith(')'));
  final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  final parsed = int.tryParse(digits) ?? 0;
  return isNegative ? -parsed : parsed;
}

String _formatReceiptPrice(int value) {
  final isNegative = value < 0;
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
    buffer.write(digits[index]);
  }
  return isNegative ? '-Rp$buffer' : 'Rp$buffer';
}

const _receiptInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(5)),
  borderSide: BorderSide(color: Color(0xFFCCCCCC)),
);

const _receiptTitleStyle = TextStyle(
  color: Colors.black,
  fontFamily: 'Bricolage Grotesque',
  fontSize: 22,
  fontWeight: FontWeight.w600,
  height: 1.1,
);

const _receiptRegularStyle = TextStyle(
  color: Color(0xFF1E1E1E),
  fontFamily: 'Bricolage Grotesque',
  fontSize: 15,
  fontWeight: FontWeight.w400,
  height: 1.3333333333,
);