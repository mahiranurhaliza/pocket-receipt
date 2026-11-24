import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HistoryDetailedScreen(),
    ),
  );
}

class HistoryDetailedScreen extends StatefulWidget {
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
    this.receiptBytes,
  });

  final String merchant;
  final String dateTime;
  final List<HistoryProduct> products;
  final String total;
  final String sourceOfFunds;
  final String category;
  final String? receiptAsset;
  final Uint8List? receiptBytes;

  @override
  State<HistoryDetailedScreen> createState() => _HistoryDetailedScreenState();
}

class _HistoryDetailedScreenState extends State<HistoryDetailedScreen> {
  late String _merchant;
  late List<HistoryProduct> _products;
  late String _sourceOfFunds;
  late String _category;
  bool _editing = false;
  bool _bannerVisible = false;
  bool _bannerMounted = false;
  String _bannerMessage = 'Your changes have been saved';
  Timer? _hideBannerTimer;
  Timer? _unmountBannerTimer;

  late final TextEditingController _merchantController;
  late List<_EditableProduct> _editableProducts;
  late String _editSourceOfFunds;
  late String _editCategory;

  static const _fundOptions = ['Gopay', 'BNI', 'Shopeepay', 'Cash'];
  static const _categoryOptions = [
    'Food & Beverages',
    'Shopping',
    'Transport',
    'Bills',
  ];

  @override
  void initState() {
    super.initState();
    _merchant = widget.merchant;
    _products = List.of(widget.products);
    _sourceOfFunds = widget.sourceOfFunds;
    _category = widget.category;
    _merchantController = TextEditingController(text: _merchant);
    _editableProducts = _products
        .map((product) => _EditableProduct.fromProduct(product))
        .toList();
    _editSourceOfFunds = _fundOptions.contains(_sourceOfFunds)
        ? _sourceOfFunds
        : _fundOptions.first;
    _editCategory = _categoryOptions.contains(_category)
        ? _category
        : _categoryOptions.first;
  }

  @override
  void dispose() {
    _hideBannerTimer?.cancel();
    _unmountBannerTimer?.cancel();
    _merchantController.dispose();
    for (final product in _editableProducts) {
      product.dispose();
    }
    super.dispose();
  }

  void _syncEditDraft() {
    _merchantController.text = _merchant;
    final previousProducts = _editableProducts;
    _editableProducts = _products
        .map((product) => _EditableProduct.fromProduct(product))
        .toList();
    _editSourceOfFunds = _fundOptions.contains(_sourceOfFunds)
        ? _sourceOfFunds
        : _fundOptions.first;
    _editCategory = _categoryOptions.contains(_category)
        ? _category
        : _categoryOptions.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final product in previousProducts) {
        product.dispose();
      }
    });
  }

  void _showFeedbackBanner(String message) {
    _hideBannerTimer?.cancel();
    _unmountBannerTimer?.cancel();

    setState(() {
      _bannerMessage = message;
      _bannerMounted = true;
      _bannerVisible = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _bannerVisible = true);
    });

    _hideBannerTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() => _bannerVisible = false);

      _unmountBannerTimer = Timer(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        setState(() => _bannerMounted = false);
      });
    });
  }

  HistoryDetailedResult get _result => HistoryDetailedResult(
        merchant: _merchant,
        products: _products,
        total: _formattedTotal,
        sourceOfFunds: _sourceOfFunds,
        category: _category,
      );

  String get _formattedTotal {
    final total = _products.fold<int>(
      0,
      (sum, product) => sum + (_parsePrice(product.price) * product.quantity),
    );
    return _formatPrice(total);
  }

  Future<void> _startEditing() async {
    _hideBannerTimer?.cancel();
    _unmountBannerTimer?.cancel();
    setState(() {
      _syncEditDraft();
      _editing = true;
      _bannerVisible = false;
      _bannerMounted = false;
    });
  }

  Future<void> _cancelEditing() async {
    final discard = await _showConfirmation(
      messageStart: 'Are you sure want to ',
      emphasizedWord: 'discard',
      messageEnd: ' this edits?',
      primaryLabel: 'Discard',
      secondaryLabel: 'Keep editing',
    );
    if (discard == true && mounted) {
      setState(() {
        _syncEditDraft();
        _editing = false;
      });
    }
  }

  void _removeEditableProduct(int index) {
    if (_editableProducts.length == 1) return;
    final removed = _editableProducts.removeAt(index);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  void _addEditableProduct() {
    setState(() {
      _editableProducts.add(
        _EditableProduct(
          name: TextEditingController(),
          price: TextEditingController(text: '0'),
          quantity: TextEditingController(text: '1'),
        ),
      );
    });
  }

  void _saveEdits() {
    final products = _editableProducts
        .where((product) => product.name.text.trim().isNotEmpty)
        .map(
          (product) => HistoryProduct(
            name: product.name.text.trim(),
            price: _formatPrice(_parsePrice(product.price.text)),
            quantity: int.tryParse(product.quantity.text) ?? 1,
          ),
        )
        .toList();

    setState(() {
      _merchant = _merchantController.text.trim().isEmpty
          ? _merchant
          : _merchantController.text.trim();
      _products = products.isEmpty ? _products : products;
      _sourceOfFunds = _editSourceOfFunds;
      _category = _editCategory;
      _editing = false;
    });
    _showFeedbackBanner('Your changes have been saved');
  }

  Future<void> _deleteReceipt() async {
    final delete = await _showConfirmation(
      messageStart: 'Are you sure want to ',
      emphasizedWord: 'delete',
      messageEnd: ' this receipt?',
      primaryLabel: 'Cancel',
      secondaryLabel: 'Yes',
      primaryReturnsTrue: false,
    );
    if (delete == true && mounted) {
      Navigator.of(context).pop(_result.copyWith(deleted: true));
    }
  }

  Future<bool?> _showConfirmation({
    required String messageStart,
    required String emphasizedWord,
    required String messageEnd,
    required String primaryLabel,
    required String secondaryLabel,
    bool primaryReturnsTrue = true,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Confirmation',
      barrierColor: const Color.fromRGBO(255, 255, 255, 0.42),
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 300,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  border: Border.all(color: const Color(0xFFCCCCCC)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 45),
                    SizedBox(
                      width: 250,
                      child: Text.rich(
                        TextSpan(
                          style: _regularStyle.copyWith(fontSize: 20),
                          children: [
                            TextSpan(text: messageStart),
                            TextSpan(
                              text: emphasizedWord,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(text: messageEnd),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _PillButton(
                          label: primaryLabel,
                          fill: const Color.fromRGBO(235, 93, 93, 0.5),
                          border: const Color(0xFFE42525),
                          onPressed: () =>
                              Navigator.of(context).pop(primaryReturnsTrue),
                        ),
                        const SizedBox(width: 10),
                        _PillButton(
                          label: secondaryLabel,
                          fill: const Color(0xFFCCCCCC),
                          border: const Color(0xFFAAAAAA),
                          onPressed: () =>
                              Navigator.of(context).pop(!primaryReturnsTrue),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleBack() {
    if (_editing) {
      setState(() => _editing = false);
    } else {
      Navigator.of(context).pop(_result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_editing) {
          await _cancelEditing();
        } else if (context.mounted) {
          Navigator.of(context).pop(_result);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFDDDDDD),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final bottomInset = MediaQuery.paddingOf(context).bottom;
            final pageHeight =
                constraints.maxHeight < 900 ? 900.0 : constraints.maxHeight;
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
                      child: const IgnorePointer(
                        child: ColoredBox(
                          color: Color(0x55F8F8F8),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -63,
                      left: (constraints.maxWidth - 578) / 2,
                      child: SvgPicture.asset(
                        'assets/58487.svg',
                        width: 578,
                        height: pageHeight + 63,
                        fit: BoxFit.fill,
                      ),
                    ),
                    _BackButton(left: contentLeft, onPressed: _handleBack),
                    if (!_editing) ...[
                      Positioned(
                        top: 90,
                        left: contentLeft,
                        width: contentWidth,
                        child: Text(
                          _merchant,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _titleStyle,
                        ),
                      ),
                      _ReceiptImage(
                        top: 120,
                        left: contentLeft,
                        width: contentWidth,
                        asset: widget.receiptAsset,
                        bytes: widget.receiptBytes,
                      ),
                      Positioned(
                        top: 325,
                        left: contentLeft,
                        width: contentWidth,
                        child: Text(
                          widget.dateTime,
                          textAlign: TextAlign.center,
                          style: _regularStyle,
                        ),
                      ),
                      Positioned(
                        top: 368,
                        left: contentLeft,
                        width: contentWidth,
                        child: Column(
                          children: [
                            _ProductsSection(
                              products: _products,
                              total: _formattedTotal,
                            ),
                            const SizedBox(height: 10),
                            _DetailSection(
                              title: 'Source of funds',
                              value: _sourceOfFunds,
                            ),
                            const SizedBox(height: 10),
                            _DetailSection(
                              title: 'Category',
                              value: _category,
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: pageHeight - 100 - bottomInset,
                        left: contentLeft,
                        width: contentWidth,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _PillButton(
                              label: 'Edit',
                              asset: 'assets/icons/edit.svg',
                              fill: const Color(0xFFF8F8F8),
                              border: const Color(0xFFCCCCCC),
                              onPressed: _startEditing,
                            ),
                            SizedBox(width: tileGap),
                            _PillButton(
                              label: 'Delete',
                              asset: 'assets/icons/delete.svg',
                              fill: const Color(0xFFF8F8F8),
                              border: const Color(0xFFCCCCCC),
                              onPressed: _deleteReceipt,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Positioned(
                        top: 85,
                        left: contentLeft,
                        width: contentWidth,
                        height: 30,
                        child: Center(
                          child: SizedBox(
                            width: tileWidth,
                            height: 30,
                            child: _CompactTextField(
                              controller: _merchantController,
                              textAlign: TextAlign.center,
                              style: _titleStyle,
                            ),
                          ),
                        ),
                      ),
                      _ReceiptImage(
                        top: 120,
                        left: contentLeft,
                        width: contentWidth,
                        asset: widget.receiptAsset,
                        bytes: widget.receiptBytes,
                      ),
                      Positioned(
                        top: 325,
                        left: contentLeft,
                        width: contentWidth,
                        child: Text(
                          widget.dateTime,
                          textAlign: TextAlign.center,
                          style: _regularStyle,
                        ),
                      ),
                      Positioned(
                        top: 368,
                        left: contentLeft,
                        width: contentWidth,
                        child: Column(
                          children: [
                            const _SectionHeader(title: 'Products'),
                            const SizedBox(height: 5),
                            for (var index = 0;
                                index < _editableProducts.length;
                                index++)
                              _EditableProductRow(
                                product: _editableProducts[index],
                                contentWidth: contentWidth,
                                tileGap: tileGap,
                                tileWidth: tileWidth,
                                onRemove: () => _removeEditableProduct(index),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 3, bottom: 5),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: _AssetIconButton(
                                  asset: 'assets/icons/add.svg',
                                  onPressed: _addEditableProduct,
                                ),
                              ),
                            ),
                            const _TotalRow(),
                            const SizedBox(height: 10),
                            const _SectionHeader(title: 'Source of funds'),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(5, 5, 5, 10),
                              child: _CompactDropdown(
                                value: _editSourceOfFunds,
                                options: _fundOptions,
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _editSourceOfFunds = value);
                                  }
                                },
                              ),
                            ),
                            const _SectionHeader(title: 'Category'),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
                              child: _CompactDropdown(
                                value: _editCategory,
                                options: _categoryOptions,
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _editCategory = value);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: pageHeight - 100 - bottomInset,
                        left: contentLeft,
                        width: contentWidth,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _PillButton(
                              label: 'Cancel',
                              fill: const Color.fromRGBO(235, 93, 93, 0.5),
                              border: const Color(0xFFE42525),
                              onPressed: _cancelEditing,
                            ),
                            SizedBox(width: tileGap),
                            _PillButton(
                              label: 'Save',
                              fill: const Color.fromRGBO(59, 178, 115, 0.5),
                              border: const Color(0xFF05922B),
                              onPressed: _saveEdits,
                            ),
                          ],
                        ),
                      ),
                    ],
                    Positioned(
                      left: contentLeft,
                      width: contentWidth,
                      top: pageHeight - 50 - bottomInset,
                      height: 50 + bottomInset,
                      child: const IgnorePointer(
                        child: ColoredBox(
                          color: Color.fromRGBO(248, 248, 248, 0.5),
                        ),
                      ),
                    ),
                    if (_bannerMounted)
                      Positioned(
                        top: 40,
                        left: contentLeft,
                        width: contentWidth,
                        child: IgnorePointer(
                          ignoring: !_bannerVisible,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            opacity: _bannerVisible ? 1.0 : 0.0,
                            child: AnimatedSlide(
                              duration: const Duration(milliseconds: 350),
                              curve: _bannerVisible
                                  ? Curves.easeOutCubic
                                  : Curves.easeInCubic,
                              offset: _bannerVisible
                                  ? Offset.zero
                                  : const Offset(0, -1.6),
                              child: _SuccessBanner(
                                message: _bannerMessage,
                                width: contentWidth,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EditableProductRow extends StatelessWidget {
  const _EditableProductRow({
    required this.product,
    required this.contentWidth,
    required this.tileGap,
    required this.tileWidth,
    required this.onRemove,
  });

  final _EditableProduct product;
  final double contentWidth;
  final double tileGap;
  final double tileWidth;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final nameRight = (contentWidth * 0.45).clamp(110.0, 165.0);
    final priceWidth = (contentWidth * 0.225).clamp(64.0, 84.0);
    final qtyLeft = tileWidth + tileGap;
    final qtyWidth = (contentWidth * 0.14).clamp(44.0, 54.0);
    final subtotalWidth = (contentWidth * 0.197).clamp(58.0, 74.0);

    return SizedBox(
      height: 54,
      child: Stack(
        children: [
          Positioned(
            left: 5,
            right: nameRight,
            top: 0,
            height: 25,
            child: _CompactTextField(controller: product.name),
          ),
          Positioned(
            left: 5,
            width: priceWidth,
            top: 27,
            height: 25,
            child: _CompactTextField(
              controller: product.price,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          Positioned(
            left: qtyLeft,
            width: qtyWidth,
            top: 27,
            height: 25,
            child: _CompactTextField(
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
            width: subtotalWidth,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: product.price,
              builder: (context, value, child) => Text(
                _formatPrice(_parsePrice(value.text)),
                textAlign: TextAlign.right,
                style: _regularStyle,
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: _AssetIconButton(
              asset: 'assets/icons/remove.svg',
              onPressed: onRemove,
            ),
          ),
        ],
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
    return Column(
      children: [
        const _SectionHeader(title: 'Products'),
        Padding(
          padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
          child: Column(
            children: [
              for (final product in products)
                SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${product.name}\n${_plainPrice(product.price)}',
                          style: _regularStyle,
                        ),
                      ),
                      SizedBox(
                        width: 34,
                        child: Text(
                          '\nx${product.quantity}',
                          textAlign: TextAlign.center,
                          style: _regularStyle,
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: Text(
                          '\n${product.price}',
                          textAlign: TextAlign.right,
                          style: _regularStyle,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _TotalRow(total: total),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({this.total});

  final String? total;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Stack(
        children: [
          const Positioned.fill(child: _DashedDivider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Row(
              children: [
                const Expanded(child: Text('Total', style: _regularStyle)),
                if (total != null)
                  Text(
                    total!,
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
                child: Text(value, style: _regularStyle),
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

class _CompactTextField extends StatelessWidget {
  const _CompactTextField({
    required this.controller,
    this.textAlign = TextAlign.left,
    this.style = _regularStyle,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        enabledBorder: _inputBorder,
        focusedBorder: _inputBorder.copyWith(
          borderSide: const BorderSide(color: Color(0xFF999999)),
        ),
      ),
    );
  }
}

class _CompactDropdown extends StatelessWidget {
  const _CompactDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

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
        ),
        style: _regularStyle,
        decoration: const InputDecoration(
          filled: true,
          fillColor: Color(0xFFF8F8F8),
          contentPadding: EdgeInsets.symmetric(horizontal: 5),
          enabledBorder: _inputBorder,
          focusedBorder: _inputBorder,
        ),
        items: [
          for (final option in options)
            DropdownMenuItem(value: option, child: Text(option)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.left, required this.onPressed});

  final double left;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40,
      left: left,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 30,
          height: 40,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SvgPicture.asset(
              'assets/icons/back.svg',
              width: 22,
              height: 17,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptImage extends StatelessWidget {
  const _ReceiptImage({
    required this.top,
    required this.left,
    required this.width,
    required this.asset,
    required this.bytes,
  });

  final double top;
  final double left;
  final double width;
  final String? asset;
  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      width: width,
      height: 200,
      child: Center(
        child: SizedBox(
          width: width.clamp(0.0, 300.0).toDouble(),
          height: 200,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: bytes != null
                ? Image.memory(bytes!, fit: BoxFit.cover)
                : asset == null
                    ? null
                    : Image.asset(asset!, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.fill,
    required this.border,
    required this.onPressed,
    this.asset,
  });

  final String label;
  final Color fill;
  final Color border;
  final VoidCallback onPressed;
  final String? asset;

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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (asset != null) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: Center(
                    child: SvgPicture.asset(
                      asset!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(label, style: _regularStyle),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetIconButton extends StatelessWidget {
  const _AssetIconButton({required this.asset, required this.onPressed});

  final String asset;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 25,
        height: 25,
        child: Center(child: SvgPicture.asset(asset)),
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({
    required this.message,
    required this.width,
  });

  final String message;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: width.clamp(0.0, 340.0).toDouble(),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3BB273), Color(0xFF22918B)],
          ),
          border: Border.all(color: const Color(0xFFCCCCCC)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 25,
              height: 25,
              child: Center(
                child: SvgPicture.asset('assets/icons/success.svg'),
              ),
            ),
            Expanded(
              child: Text(
                message,
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFF8F8F8),
                  fontFamily: 'Bricolage Grotesque',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 25),
          ],
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _DashedDividerPainter());
  }
}

class _DashedDividerPainter extends CustomPainter {
  const _DashedDividerPainter();

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
  bool shouldRepaint(covariant _DashedDividerPainter oldDelegate) => false;
}

class HistoryProduct {
  const HistoryProduct({
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  final String name;
  final String price;
  final int quantity;
}

class HistoryDetailedResult {
  const HistoryDetailedResult({
    required this.merchant,
    required this.products,
    required this.total,
    required this.sourceOfFunds,
    required this.category,
    this.deleted = false,
  });

  final String merchant;
  final List<HistoryProduct> products;
  final String total;
  final String sourceOfFunds;
  final String category;
  final bool deleted;

  HistoryDetailedResult copyWith({bool? deleted}) {
    return HistoryDetailedResult(
      merchant: merchant,
      products: products,
      total: total,
      sourceOfFunds: sourceOfFunds,
      category: category,
      deleted: deleted ?? this.deleted,
    );
  }
}

class _EditableProduct {
  _EditableProduct({
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory _EditableProduct.fromProduct(HistoryProduct product) {
    return _EditableProduct(
      name: TextEditingController(text: product.name),
      price: TextEditingController(text: _plainPrice(product.price)),
      quantity: TextEditingController(text: product.quantity.toString()),
    );
  }

  final TextEditingController name;
  final TextEditingController price;
  final TextEditingController quantity;

  void dispose() {
    name.dispose();
    price.dispose();
    quantity.dispose();
  }
}

int _parsePrice(String value) {
  return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
}

String _plainPrice(String value) => _parsePrice(value).toString();

String _formatPrice(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
    buffer.write(digits[index]);
  }
  return 'Rp$buffer';
}

const _inputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(5)),
  borderSide: BorderSide(color: Color(0xFFCCCCCC)),
);

const _titleStyle = TextStyle(
  color: Colors.black,
  fontFamily: 'Bricolage Grotesque',
  fontSize: 25,
  fontWeight: FontWeight.w600,
  height: 0.8,
);

const _regularStyle = TextStyle(
  color: Color(0xFF1E1E1E),
  fontFamily: 'Bricolage Grotesque',
  fontSize: 15,
  fontWeight: FontWeight.w400,
  height: 1.3333333333,
);