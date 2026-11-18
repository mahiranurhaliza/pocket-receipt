import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'models/receipt_model.dart';
import 'services/database_service.dart';

class HistoryDetailedScreen extends StatefulWidget {
  const HistoryDetailedScreen({
    super.key,
    this.receiptId,
    this.merchant = 'Alfamart',
    this.dateTime = '20 Oct 2026 11:46:18 WIB',
    this.products = const [
      HistoryProduct(name: 'Mineral', quantity: 1, rawPrice: 5000, price: 'Rp5.000'),
    ],
    this.total = 'Rp5.000',
    this.sourceOfFunds = 'Cash',
    this.category = 'Belanja',
    this.note = '',
    this.receiptAsset,
  });

  final int? receiptId;
  final String merchant;
  final String dateTime;
  final List<HistoryProduct> products;
  final String total;
  final String sourceOfFunds;
  final String category;
  final String note;
  final String? receiptAsset;

  @override
  State<HistoryDetailedScreen> createState() => _HistoryDetailedScreenState();
}

class _HistoryDetailedScreenState extends State<HistoryDetailedScreen> {
  late String _merchant;
  late String _total;
  late String _currentSourceOfFunds;
  late String _category;
  late String _note;
  late List<HistoryProduct> _products;

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

  static const List<String> _categories = [
    'Makanan',
    'Belanja',
    'Transportasi',
    'Tagihan',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _merchant = widget.merchant;
    _total = widget.total;
    _currentSourceOfFunds = widget.sourceOfFunds;
    _category = widget.category;
    _note = widget.note;
    _products = List<HistoryProduct>.from(widget.products);
  }

  String _formatRupiah(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(amount);
  }

  double _parseRupiah(String formatted) {
    final digits = formatted.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(digits) ?? 0;
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
              _merchant,
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

  Future<void> _showEditAllDialog() async {
    final storeController = TextEditingController(text: _merchant);
    final noteController = TextEditingController(text: _note);

    // Siapkan controller per item produk
    final List<Map<String, dynamic>> itemRows = _products.map((prod) {
      final rawVal =
          prod.rawPrice > 0 ? prod.rawPrice : _parseRupiah(prod.price);
      final qty = prod.quantity > 0 ? prod.quantity : 1;
      // Bersihkan sufiks "(2x)" jika masih menempel di nama lama
      final cleanName = prod.name.replaceAll(RegExp(r'\s*\(\d+x\)$'), '').trim();
      return <String, dynamic>{
        'name': TextEditingController(text: cleanName),
        'qty': TextEditingController(text: qty.toString()),
        'price': TextEditingController(text: rawVal.toStringAsFixed(0)),
        'unitPrice': qty > 0 ? rawVal / qty : rawVal,
      };
    }).toList();

    if (itemRows.isEmpty) {
      itemRows.add({
        'name': TextEditingController(),
        'qty': TextEditingController(text: '1'),
        'price': TextEditingController(text: '0'),
        'unitPrice': 0.0,
      });
    }

    String tempCategory =
        _categories.contains(_category) ? _category : _categories.first;
    String tempSource = _fundSources.contains(_currentSourceOfFunds)
        ? _currentSourceOfFunds
        : _fundSources.first;

    double computeTotal() {
      double sum = 0;
      for (final row in itemRows) {
        final p = double.tryParse((row['price'] as TextEditingController)
                .text
                .replaceAll(RegExp(r'[^0-9]'), '')) ??
            0;
        sum += p;
      }
      return sum;
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF8F8F8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final autoTotal = computeTotal();

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.86,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edit Detail Transaksi',
                        style: TextStyle(
                          color: Color(0xFF1E1E1E),
                          fontFamily: 'Bricolage Grotesque',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: storeController,
                        style: const TextStyle(fontFamily: 'Bricolage Grotesque'),
                        decoration: const InputDecoration(
                          labelText: 'Nama Toko / Merchant',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Daftar Produk, Qty & Harga',
                            style: TextStyle(
                              color: Color(0xFF1E1E1E),
                              fontFamily: 'Bricolage Grotesque',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setModalState(() {
                                itemRows.add({
                                  'name': TextEditingController(),
                                  'qty': TextEditingController(text: '1'),
                                  'price': TextEditingController(),
                                  'unitPrice': 0.0,
                                });
                              });
                            },
                            icon: const Icon(Icons.add,
                                color: Color(0xFFF05A5A), size: 18),
                            label: const Text(
                              'Tambah Produk',
                              style: TextStyle(
                                color: Color(0xFFF05A5A),
                                fontFamily: 'Bricolage Grotesque',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      for (int i = 0; i < itemRows.length; i++) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: TextField(
                                  controller: itemRows[i]['name']
                                      as TextEditingController,
                                  style: const TextStyle(
                                    fontFamily: 'Bricolage Grotesque',
                                    fontSize: 13,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Produk',
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 52,
                                child: TextField(
                                  controller: itemRows[i]['qty']
                                      as TextEditingController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Bricolage Grotesque',
                                    fontSize: 13,
                                  ),
                                  onChanged: (val) {
                                    final newQty = int.tryParse(val) ?? 1;
                                    final unitPrice =
                                        itemRows[i]['unitPrice'] as double;
                                    if (unitPrice > 0 && newQty > 0) {
                                      (itemRows[i]['price']
                                              as TextEditingController)
                                          .text = (unitPrice * newQty)
                                              .toStringAsFixed(0);
                                    }
                                    setModalState(() {});
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'Qty',
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 10),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: itemRows[i]['price']
                                      as TextEditingController,
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    final enteredPrice = double.tryParse(
                                            val.replaceAll(
                                                RegExp(r'[^0-9]'), '')) ??
                                        0;
                                    final currentQty = int.tryParse(
                                            (itemRows[i]['qty']
                                                    as TextEditingController)
                                                .text) ??
                                        1;
                                    itemRows[i]['unitPrice'] = currentQty > 0
                                        ? enteredPrice / currentQty
                                        : enteredPrice;
                                    setModalState(() {});
                                  },
                                  style: const TextStyle(
                                    fontFamily: 'Bricolage Grotesque',
                                    fontSize: 13,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Harga (Rp)',
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              if (itemRows.length > 1)
                                InkWell(
                                  onTap: () {
                                    setModalState(() => itemRows.removeAt(i));
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(
                                      Icons.remove_circle_outline,
                                      color: Color(0xFFE42525),
                                      size: 20,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      // Total otomatis (read-only / tidak dapat diedit manual)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDEDED),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCCCCCC)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Harga (Otomatis)',
                              style: TextStyle(
                                color: Color(0xFF555555),
                                fontFamily: 'Bricolage Grotesque',
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              _formatRupiah(autoTotal),
                              style: const TextStyle(
                                color: Color(0xFF1E1E1E),
                                fontFamily: 'Bricolage Grotesque',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: tempCategory,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories
                            .map((cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => tempCategory = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: tempSource,
                        decoration: const InputDecoration(
                          labelText: 'Sumber Dana (Source of funds)',
                          border: OutlineInputBorder(),
                        ),
                        items: _fundSources
                            .map((src) =>
                                DropdownMenuItem(value: src, child: Text(src)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => tempSource = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      // Catatan maksimal 100 karakter
                      TextField(
                        controller: noteController,
                        maxLength: 100,
                        maxLines: 2,
                        style: const TextStyle(
                          fontFamily: 'Bricolage Grotesque',
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Catatan (Maks. 100 karakter)',
                          hintText: 'Tambahkan catatan transaksi...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF05A5A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text(
                            'Simpan Perubahan',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Bricolage Grotesque',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (saved == true) {
      final newMerchant = storeController.text.trim().isEmpty
          ? _merchant
          : storeController.text.trim();
      final newNote = noteController.text.trim();

      final Map<String, ReceiptItem> mergedMap = {};
      for (int i = 0; i < itemRows.length; i++) {
        final rawName =
            (itemRows[i]['name'] as TextEditingController).text.trim();
        final name = rawName.isEmpty ? 'Produk ${i + 1}' : rawName;
        final qty = int.tryParse(
                (itemRows[i]['qty'] as TextEditingController).text.trim()) ??
            1;
        final price = double.tryParse(
                (itemRows[i]['price'] as TextEditingController)
                    .text
                    .replaceAll(RegExp(r'[^0-9]'), '')) ??
            0;

        final key = name.toLowerCase();
        if (mergedMap.containsKey(key)) {
          final existing = mergedMap[key]!;
          mergedMap[key] = ReceiptItem(
            name: existing.name,
            quantity: existing.quantity + (qty > 0 ? qty : 1),
            price: existing.price + price,
          );
        } else {
          mergedMap[key] = ReceiptItem(
            name: name,
            quantity: qty > 0 ? qty : 1,
            price: price,
          );
        }
      }

      final updatedItems = mergedMap.values.toList();
      final newTotalAmount =
          updatedItems.fold<double>(0, (sum, item) => sum + item.price);
      final formattedTotal = _formatRupiah(newTotalAmount);

      if (widget.receiptId != null) {
        await DatabaseService.instance.updateReceipt(
          id: widget.receiptId!,
          storeName: newMerchant,
          totalAmount: newTotalAmount,
          category: tempCategory,
          sourceOfFunds: tempSource,
          note: newNote,
          items: updatedItems,
        );
      }

      if (!mounted) return;
      setState(() {
        _merchant = newMerchant;
        _total = formattedTotal;
        _category = tempCategory;
        _currentSourceOfFunds = tempSource;
        _note = newNote;
        _products = updatedItems
            .map((item) => HistoryProduct(
                  name: item.name,
                  quantity: item.quantity,
                  rawPrice: item.price,
                  price: _formatRupiah(item.price),
                ))
            .toList();
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Perubahan transaksi disimpan')),
        );
    }
  }

  Future<void> _confirmAndDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Hapus Transaksi?',
          style: TextStyle(fontFamily: 'Bricolage Grotesque'),
        ),
        content: Text(
          'Transaksi "$_merchant" ($_total) akan dihapus permanen dari riwayat.',
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
      if (widget.receiptId != null) {
        await DatabaseService.instance.deleteReceipt(widget.receiptId!);
      }
      if (widget.receiptAsset != null && widget.receiptAsset!.isNotEmpty) {
        final file = File(widget.receiptAsset!);
        if (file.existsSync()) {
          try {
            await file.delete();
          } catch (_) {}
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil dihapus')),
        );
      Navigator.of(context).pop(true);
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
        ? Image.file(
            file,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          )
        : Image.asset(
            path,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, _, _) => const Center(
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

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                  Padding(
                    padding: EdgeInsets.only(
                      top: 40,
                      left: contentLeft,
                      right: contentLeft,
                      bottom: 36,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: 32,
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
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Edit Transaksi',
                                  onPressed: _showEditAllDialog,
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: Color(0xFF1E1E1E),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Hapus Transaksi',
                                  onPressed: _confirmAndDelete,
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFE42525),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _showEditAllDialog,
                          child: Text(
                            _merchant,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black,
                              fontFamily: 'Bricolage Grotesque',
                              fontSize: 25,
                              fontWeight: FontWeight.w600,
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: receiptWidth,
                          height: 200,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F8F8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: _buildReceiptPreview(),
                        ),
                        const SizedBox(height: 10),
                        Text(
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
                        const SizedBox(height: 20),
                        _ProductsSection(
                          products: _products,
                          total: _total,
                         ),
                        const SizedBox(height: 12),
                        _DetailSection(
                          title: 'Source of funds',
                          value: _currentSourceOfFunds,
                         ),
                        const SizedBox(height: 12),
                        _DetailSection(
                          title: 'Category',
                          value: _category,
                          ),
                        const SizedBox(height: 12),
                        _DetailSection(
                          title: 'Notes',
                          value: _note.isEmpty
                              ? 'Tambah catatan (maks. 100 karakter)...'
                              : _note,
                          isPlaceholder: _note.isEmpty,
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
  const _ProductsSection({
    required this.products,
    required this.total,
    this.onEdit,
  });

  final List<HistoryProduct> products;
  final String total;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Products'),
          const SizedBox(height: 6),
          for (final product in products)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${product.name} (${product.quantity}x)',
                      style: _regularStyle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    product.price,
                    textAlign: TextAlign.right,
                    style: _regularStyle,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          const _DashedDivider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
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
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.value,
    this.isPlaceholder = false,
    this.onEdit,
  });

  final String title;
  final String value;
  final bool isPlaceholder;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title),
        InkWell(
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: _regularStyle.copyWith(
                      color: isPlaceholder
                          ? const Color(0xFF888888)
                          : const Color(0xFF1E1E1E),
                      fontStyle:
                          isPlaceholder ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ),
                if (onEdit != null) ...[
                  const SizedBox(width: 8),
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.showEditLabel = false,
  });

  final String title;
  final bool showEditLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFAAAAAA)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1E1E1E),
              fontFamily: 'Bricolage Grotesque',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (showEditLabel)
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
  const HistoryProduct({
    required this.name,
    this.quantity = 1,
    this.rawPrice = 0,
    required this.price,
  });

  final String name;
  final int quantity;
  final double rawPrice;
  final String price;
}

const _regularStyle = TextStyle(
  color: Color(0xFF1E1E1E),
  fontFamily: 'Bricolage Grotesque',
  fontSize: 15,
  fontWeight: FontWeight.w400,
  height: 1.3333333333,
);