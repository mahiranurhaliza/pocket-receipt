import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/receipt_model.dart';

class OcrResult {
  final String storeName;
  final double totalAmount;
  final String rawText;
  final List<ReceiptItem> items;

  OcrResult({
    required this.storeName,
    required this.totalAmount,
    required this.rawText,
    this.items = const [],
  });
}

class OcrService {
  // Daftar kata kunci ringkasan/pembayaran yang TIDAK BOLEH dianggap sebagai produk
  static const List<String> _nonProductKeywords = [
    'total',
    'total item',
    'total disc',
    'total belanja',
    'grand total',
    'subtotal',
    'sub total',
    'jumlah',
    'jumlah bayar',
    'jumlah tagihan',
    'nominal',
    'tunai',
    'cash',
    'kembali',
    'kembalian',
    'change',
    'ppn',
    'dpp',
    'pajak',
    'tax',
    'diskon',
    'discount',
    'hemat',
    'anda menyimpan',
    'saldo',
    'biaya admin',
    'admin',
    'pembayaran',
    'metode pembayaran',
    'gopay',
    'ovo',
    'dana',
    'shopeepay',
    'qris',
  ];

  static bool _isNonProductLine(String text) {
    // Normalisasi semua spasi berlebih menjadi 1 spasi tunggal
    final normalized = text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return true;

    return _nonProductKeywords.any(
      (kw) =>
          normalized == kw ||
          normalized.startsWith('$kw ') ||
          normalized.startsWith('$kw:') ||
          normalized.startsWith('$kw.') ||
          normalized.contains(' $kw ') ||
          normalized.endsWith(' $kw') ||
          normalized.contains('total item') ||
          normalized.contains('total belanja') ||
          normalized.contains('total disc'),
    );
  }

  static Future<OcrResult> scanReceipt(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      final String fullText = recognizedText.text;

      // Gabungkan elemen dalam satu baris vertikal (Y) yang sejajar
      final List<TextLine> allLines = [];
      for (final block in recognizedText.blocks) {
        allLines.addAll(block.lines);
      }
      allLines.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

      final List<String> reconstructedRows = [];
      final List<List<TextLine>> rowGroups = [];

      for (final line in allLines) {
        final centerY = line.boundingBox.center.dy;
        final lineHeight = line.boundingBox.height;
        final tolerance = lineHeight > 0 ? lineHeight * 0.55 : 14.0;

        bool added = false;
        for (final group in rowGroups) {
          final groupCenterY = group.first.boundingBox.center.dy;
          if ((centerY - groupCenterY).abs() <= tolerance) {
            group.add(line);
            added = true;
            break;
          }
        }
        if (!added) {
          rowGroups.add([line]);
        }
      }

      for (final group in rowGroups) {
        group.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
        // Pisahkan antar blok horizontal dengan 3 spasi agar batas kolom tetap jelas
        reconstructedRows.add(group.map((l) => l.text.trim()).join('   '));
      }

      // 1. Deteksi Nama Toko
      String detectedStore = _detectStoreName(reconstructedRows);

      // 2. Cek apakah struk menggunakan prefix "Rp" / "IDR"
      final rpRegex = RegExp(
        r'(?:rp|idr)\.?\s*(\d{1,3}(?:[.,]\d{3})+|\d+)',
        caseSensitive: false,
      );
      final bool hasExplicitRp = rpRegex.hasMatch(fullText);

      List<ReceiptItem> detectedItems = [];
      double fallbackTotal = 0;

      if (hasExplicitRp) {
        detectedItems = _parseExplicitRpRows(
          reconstructedRows,
          rpRegex,
          detectedStore,
          (val) {
            if (val > fallbackTotal) fallbackTotal = val;
          },
        );
      } else {
        detectedItems = _parseCashierReceiptRows(
          reconstructedRows,
          (val) {
            if (val > fallbackTotal) fallbackTotal = val;
          },
        );
      }

      if (detectedItems.isEmpty) {
        detectedItems.add(
          ReceiptItem(
            name: detectedStore,
            quantity: 1,
            price: fallbackTotal,
          ),
        );
      }

      final double totalFromItems =
          detectedItems.fold(0, (sum, item) => sum + item.price);

      return OcrResult(
        storeName: detectedStore,
        totalAmount: totalFromItems > 0 ? totalFromItems : fallbackTotal,
        rawText: fullText,
        items: detectedItems,
      );
    } finally {
      await textRecognizer.close();
    }
  }

  static String _detectStoreName(List<String> rows) {
    final knownBrands = [
      'alfamart',
      'indomaret',
      'alfamidi',
      'superindo',
      'hypermart',
      'transmart',
      'lawson',
      'familymart',
      'circle k',
      'mcdonald',
      'kfc',
      'hokben',
      'starbucks',
      'mixue',
      'fore coffee',
      'kopi kenangan',
      'gramedia',
      'guardian',
      'watsons',
      'sociolla',
      'uniqlo',
      'miniso',
    ];

    // Prioritas 1: Cek pola "bayar ke <Nama Toko>" atau "Merchant Name <Nama Toko>"
    for (int i = 0; i < rows.length; i++) {
      final lower = rows[i].toLowerCase();
      if (lower.contains('bayar ke ')) {
        final idx = lower.indexOf('bayar ke ');
        final candidate = rows[i].substring(idx + 9).split('-').first.trim();
        if (candidate.isNotEmpty) return candidate;
      }
      if (lower.startsWith('merchant name')) {
        final parts = rows[i].split(RegExp(r'\s{2,}'));
        if (parts.length > 1 && parts.last.trim().isNotEmpty) {
          return parts.last.trim();
        }
      }
    }

    // Prioritas 2: Pada bukti GoPay/E-wallet, nama toko berada tepat 1 baris di bawah "Rp35.000"
    for (int i = 0; i < rows.length - 1; i++) {
      if (RegExp(r'^(?:rp|idr)\.?\s*\d', caseSensitive: false)
          .hasMatch(rows[i].trim())) {
        final nextLine = rows[i + 1].split('   ').first.trim();
        if (nextLine.length >= 3 && !_isNonProductLine(nextLine)) {
          return nextLine;
        }
      }
    }

    // Prioritas 3: Cek nama brand terkenal di 8 baris teratas
    for (final row in rows.take(8)) {
      final lower = row.toLowerCase();
      for (final brand in knownBrands) {
        if (lower.contains(brand)) {
          return brand
              .split(' ')
              .map((w) => w[0].toUpperCase() + w.substring(1))
              .join(' ');
        }
      }
    }

    // Prioritas 4: Baris atas pertama yang bukan nama e-wallet, alamat, atau angka
    final skipHeader = [
      'status',
      'rincian transaksi',
      'npwp',
      'jl.',
      'jalan',
      'tower',
      'bon ',
      'kasir',
      'tgl',
      'member',
      'telp',
      'wa:',
      'sms/',
      'gopay',
      'ovo',
      'dana',
      'shopeepay',
    ];

    for (final row in rows.take(6)) {
      final lower = row.toLowerCase();
      if (skipHeader.any((k) => lower.contains(k))) continue;
      if (RegExp(r'^(rp|idr|\d)', caseSensitive: false).hasMatch(row)) continue;
      if (row.length >= 3) {
        return row.split('   ').first.trim();
      }
    }

    return 'Toko Baru';
  }

  /// Mode A: Mengambil harga khusus yang diawali "Rp"
  static List<ReceiptItem> _parseExplicitRpRows(
    List<String> rows,
    RegExp rpRegex,
    String storeName,
    void Function(double) onFallbackPrice,
  ) {
    final Map<String, ReceiptItem> grouped = {};

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];

      final match = rpRegex.firstMatch(row);
      if (match == null) continue;

      final digits = match.group(1)!.replaceAll('.', '').replaceAll(',', '');
      final price = double.tryParse(digits) ?? 0;
      if (price <= 0 || price >= 100000000) continue;

      onFallbackPrice(price);

      // Jangan pernah masukkan baris Total / Jumlah / Tunai / Kembalian ke produk
      if (_isNonProductLine(row)) continue;

      String itemName = row.substring(0, match.start).trim();
      itemName = itemName.replaceAll(RegExp(r'[-:=]+$'), '').trim();

      if (itemName.isEmpty && i > 0) {
        final prev = rows[i - 1].split('   ').first.trim();
        if (!rpRegex.hasMatch(prev) &&
            !_isNonProductLine(prev) &&
            prev.toLowerCase() != 'status' &&
            prev.toLowerCase() != 'rincian transaksi' &&
            prev.length >= 2) {
          itemName = prev;
        }
      }

      if (itemName.length < 2 ||
          RegExp(r'^\d+$').hasMatch(itemName) ||
          _isNonProductLine(itemName)) {
        continue;
      }

      int qty = 1;
      final prefixQty = RegExp(r'^(\d+)\s*[xX*]\s*(.+)$').firstMatch(itemName);
      final suffixQty = RegExp(r'^(.+?)\s*[xX*]\s*(\d+)$').firstMatch(itemName);
      if (prefixQty != null) {
        qty = int.tryParse(prefixQty.group(1)!) ?? 1;
        itemName = prefixQty.group(2)!.trim();
      } else if (suffixQty != null) {
        itemName = suffixQty.group(1)!.trim();
        qty = int.tryParse(suffixQty.group(2)!) ?? 1;
      }

      _addOrMergeItem(grouped, itemName, qty, price);
    }

    return grouped.values.toList();
  }

  /// Mode B: Mengidentifikasi Produk, Jumlah (Qty), dan Harga pada struk kasir tanpa "Rp"
  static List<ReceiptItem> _parseCashierReceiptRows(
    List<String> rows,
    void Function(double) onFallbackPrice,
  ) {
    final stopKeywords = [
      'total item',
      'total disc',
      'total belanja',
      'grand total',
      'subtotal',
      'sub total',
      'jumlah',
      'tunai',
      'cash',
      'kembalian',
      'kembali',
      'ppn',
      'dpp',
      'tgl.',
      'member :',
      'potensi poin',
      'kritik',
      'saran',
      'terima kasih',
    ];

    final skipLineKeywords = [
      'npwp',
      'jl.',
      'jalan',
      'tower',
      'bon ',
      'kasir',
      'alfamart',
      'indomaret',
      'gading',
      'soreang',
      'tangerang',
      'telp',
      'sms/',
    ];

    // 4 kolom dipisahkan spasi lebar (>= 2 spasi): [Nama Produk]  [Qty]  [Harga Satuan]  [Subtotal]
    final fourColRegex = RegExp(
      r'^(.+?)\s{2,}(\d{1,3})\s+(\d{1,3}(?:[.,]\d{3})+)\s+(\d{1,3}(?:[.,]\d{3})+)$',
    );
    // 3 kolom: [Nama Produk]  [Harga Satuan]  [Subtotal] (jika Qty terlewat atau menyatu)
    final threePriceColRegex = RegExp(
      r'^(.+?)\s{2,}(\d{1,3}(?:[.,]\d{3})+)\s+(\d{1,3}(?:[.,]\d{3})+)$',
    );
    // 3 kolom dengan Qty eksplisit setelah spasi lebar: [Nama Produk]  [Qty]  [Subtotal]
    final threeQtyColRegex = RegExp(
      r'^(.+?)\s{2,}(\d{1,2})\s+(\d{1,3}(?:[.,]\d{3})+)$',
    );
    // 2 kolom: [Nama Produk]  [Subtotal]
    final twoColRegex = RegExp(
      r'^(.+?)\s{2,}(\d{1,3}(?:[.,]\d{3})+)$',
    );
    // Baris diskon di bawah produk: "Disc. -7,000"
    final discRegex = RegExp(
      r'^(?:disc|diskon)\.?\s*-?\s*(\d{1,3}(?:[.,]\d{3})+|\d+)$',
      caseSensitive: false,
    );

    final Map<String, ReceiptItem> grouped = {};
    String? lastAddedKey;

    for (final row in rows) {
      final lower = row.toLowerCase().trim();

      if (lower.contains('total belanja') || lower.contains('grand total')) {
        final m = RegExp(r'(\d{1,3}(?:[.,]\d{3})+)').firstMatch(row);
        if (m != null) {
          final val = double.tryParse(
                  m.group(1)!.replaceAll('.', '').replaceAll(',', '')) ??
              0;
          onFallbackPrice(val);
        }
        break;
      }

      // Hentikan pemindaian produk begitu menyentuh baris Total / Jumlah / Tunai
      if (stopKeywords.any((kw) => lower == kw || lower.startsWith(kw)) ||
          _isNonProductLine(row)) {
        if (lower.startsWith('total') ||
            lower.startsWith('jumlah') ||
            lower.startsWith('tunai')) {
          break;
        }
        continue;
      }

      if (skipLineKeywords.any((kw) => lower.contains(kw))) continue;

      // Potong harga produk di atasnya jika ada baris "Disc. -7,000"
      final discMatch = discRegex.firstMatch(row);
      if (discMatch != null &&
          lastAddedKey != null &&
          grouped.containsKey(lastAddedKey)) {
        final discVal = double.tryParse(
                discMatch.group(1)!.replaceAll('.', '').replaceAll(',', '')) ??
            0;
        final prevItem = grouped[lastAddedKey]!;
        final updatedPrice =
            (prevItem.price - discVal).clamp(0.0, double.infinity);
        grouped[lastAddedKey] = ReceiptItem(
          name: prevItem.name,
          quantity: prevItem.quantity,
          price: updatedPrice,
        );
        continue;
      }

      String? itemName;
      int qty = 1;
      double rowTotalPrice = 0;

      final m4 = fourColRegex.firstMatch(row);
      final m3Price = threePriceColRegex.firstMatch(row);
      final m3Qty = threeQtyColRegex.firstMatch(row);
      final m2 = twoColRegex.firstMatch(row);

      if (m4 != null) {
        itemName = m4.group(1)!.trim();
        qty = int.tryParse(m4.group(2)!) ?? 1;
        rowTotalPrice = double.tryParse(
                m4.group(4)!.replaceAll('.', '').replaceAll(',', '')) ??
            0;
      } else if (m3Price != null) {
        itemName = m3Price.group(1)!.trim();
        final unitPrice = double.tryParse(
                m3Price.group(2)!.replaceAll('.', '').replaceAll(',', '')) ??
            0;
        rowTotalPrice = double.tryParse(
                m3Price.group(3)!.replaceAll('.', '').replaceAll(',', '')) ??
            0;
        qty = (unitPrice > 0 && rowTotalPrice >= unitPrice)
            ? (rowTotalPrice / unitPrice).round()
            : 1;
      } else if (m3Qty != null) {
        itemName = m3Qty.group(1)!.trim();
        qty = int.tryParse(m3Qty.group(2)!) ?? 1;
        rowTotalPrice = double.tryParse(
                m3Qty.group(3)!.replaceAll('.', '').replaceAll(',', '')) ??
            0;
      } else if (m2 != null) {
        itemName = m2.group(1)!.trim();
        rowTotalPrice = double.tryParse(
                m2.group(2)!.replaceAll('.', '').replaceAll(',', '')) ??
            0;
      }

      if (itemName != null &&
          itemName.length >= 2 &&
          !RegExp(r'^\d+$').hasMatch(itemName) &&
          !_isNonProductLine(itemName) &&
          rowTotalPrice >= 100 &&
          rowTotalPrice < 50000000) {
        itemName = itemName.replaceAll(RegExp(r'[-:=]+$'), '').trim();
        lastAddedKey = _addOrMergeItem(grouped, itemName, qty, rowTotalPrice);
      }
    }

    return grouped.values.toList();
  }

  static String _addOrMergeItem(
    Map<String, ReceiptItem> grouped,
    String itemName,
    int qty,
    double price,
  ) {
    if (_isNonProductLine(itemName)) return '';
    final key = itemName.toLowerCase();
    if (grouped.containsKey(key)) {
      final existing = grouped[key]!;
      grouped[key] = ReceiptItem(
        name: existing.name,
        quantity: existing.quantity + qty,
        price: existing.price + price,
      );
    } else {
      grouped[key] = ReceiptItem(
        name: itemName,
        quantity: qty > 0 ? qty : 1,
        price: price,
      );
    }
    return key;
  }
}