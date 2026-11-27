import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../database/receipt_model.dart';

class OcrResult {
  final String storeName;
  final double totalAmount;
  final String rawText;
  final List<ReceiptItem> items;
  final String receiptDateText;

  const OcrResult({
    required this.storeName,
    required this.totalAmount,
    required this.rawText,
    this.items = const [],
    this.receiptDateText = '',
  });
}

class OcrService {
  /// Kata kunci ringkasan/pembayaran yang bukan item produk maupun biaya tambahan.
  static const List<String> _summaryOrPaymentKeywords = [
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
    'saldo',
    'pembayaran',
    'metode pembayaran',
    'gopay',
    'ovo',
    'dana',
    'shopeepay',
    'qris',
    'status',
    'sukses',
    'belum lunas',
    'id transaksi',
    'nama acquirer',
    'nama merchant',
    'lokasi merchant',
    'merchant pan',
    'terminal id',
    'open time',
    'user:',
    'table ',
    'pax',
  ];

  /// Kata kunci biaya tambahan / pajak / layanan / pembulatan yang masuk perhitungan.
  static const List<String> _chargeKeywords = [
    'service',
    'ppn',
    'pajak',
    'tax',
    'pb 1',
    'pb1',
    'rounding',
    'pembulatan',
    'biaya admin',
    'admin',
  ];

  static bool _isRoundingLine(String text) {
    final normalized =
        text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return false;
    return normalized == 'rounding' ||
        normalized.startsWith('rounding ') ||
        normalized.startsWith('rounding:') ||
        normalized.contains(' rounding') ||
        normalized == 'pembulatan' ||
        normalized.startsWith('pembulatan ') ||
        normalized.startsWith('pembulatan:') ||
        normalized.contains(' pembulatan');
  }

  static bool _isChargeLine(String text) {
    final normalized =
        text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return false;
    return _chargeKeywords.any(
      (kw) =>
          normalized == kw ||
          normalized.startsWith('$kw ') ||
          normalized.startsWith('$kw:') ||
          normalized.startsWith('$kw.') ||
          normalized.contains(' $kw ') ||
          normalized.endsWith(' $kw'),
    );
  }

  static bool _isNonProductLine(String text) {
    if (_isChargeLine(text)) return false;

    final normalized =
        text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return true;

    return _summaryOrPaymentKeywords.any(
      (kw) =>
          normalized == kw ||
          normalized.startsWith('$kw ') ||
          normalized.startsWith('$kw:') ||
          normalized.startsWith('$kw.') ||
          normalized.contains(' $kw ') ||
          normalized.endsWith(' $kw') ||
          normalized.contains('total item') ||
          normalized.contains('total belanja') ||
          normalized.contains('total disc') ||
          normalized.contains('jumlah tagihan'),
    );
  }

  static double _parseSignedNumber(String raw) {
    final trimmed = raw.trim();
    final isNegative = trimmed.startsWith('-') ||
        (trimmed.startsWith('(') && trimmed.endsWith(')'));
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    final value = double.tryParse(digits) ?? 0;
    return isNegative ? -value : value;
  }

  static double _normalizeItemPrice(String itemName, double rawPrice) {
    if (_isRoundingLine(itemName)) {
      return -rawPrice.abs();
    }
    return rawPrice;
  }

  static bool _looksLikeAddressOrLongText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return true;

    final wordCount = trimmed.split(RegExp(r'\s+')).length;
    if (trimmed.length > 38 || wordCount > 6) {
      return true;
    }

    final lower = trimmed.toLowerCase();
    final addressPatterns = [
      RegExp(
        r'\b(jl\.?|jln\.?|jalan|gg\.?|gang|blok|kav\.?|no\.?|rt\.?|rw\.?)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(kel\.?|kelurahan|kec\.?|kecamatan|kab\.?|kabupaten|kota|prov\.?|provinsi|regency)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(selatan|utara|timur|barat|pusat)\b',
        caseSensitive: false,
      ),
      RegExp(r'\b\d{5}\b'),
    ];

    return addressPatterns.any((regex) => regex.hasMatch(lower));
  }

  static Future<OcrResult> scanReceipt(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      final String fullText = recognizedText.text;

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
        reconstructedRows.add(group.map((l) => l.text.trim()).join('   '));
      }

      final String detectedStore = _detectStoreName(reconstructedRows);
      final String detectedDate = _detectReceiptDate(reconstructedRows);

      final rpRegex = RegExp(
        r'(?:rp|idr)\.?\s*(\(?\s*-?\s*(?:\d{1,3}(?:[.,]\d{3})+|\d+)\s*\)?)',
        caseSensitive: false,
      );
      final bool hasExplicitRp = rpRegex.hasMatch(fullText);

      List<ReceiptItem> detectedItems = [];
      double fallbackTotal = _extractReceiptTotal(reconstructedRows, rpRegex);

      if (hasExplicitRp) {
        detectedItems = _parseExplicitRpRows(
          reconstructedRows,
          rpRegex,
          (val) {
            if (val > fallbackTotal) fallbackTotal = val;
          },
        );
      }

      if (detectedItems.isEmpty) {
        detectedItems = _parseCashierReceiptRows(
          reconstructedRows,
          (val) {
            if (val > fallbackTotal) fallbackTotal = val;
          },
        );
      }

      if (detectedItems.isEmpty) {
        detectedItems.add(
          const ReceiptItem(
            name: 'nama produk',
            quantity: 1,
            price: 0,
          ),
        );
      }

      final double totalFromItems = detectedItems.fold(
  0,
  (sum, item) => sum + (item.price * item.quantity),
);

      final double finalTotal =
          detectedItems.isNotEmpty ? totalFromItems : fallbackTotal;

      return OcrResult(
        storeName: detectedStore,
        totalAmount: finalTotal,
        rawText: fullText,
        items: detectedItems,
        receiptDateText: detectedDate,
      );
    } finally {
      await textRecognizer.close();
    }
  }

  static double _extractReceiptTotal(List<String> rows, RegExp rpRegex) {
    double best = 0;
    for (final row in rows) {
      final lower = row.toLowerCase().trim();
      final isTotalRow = lower.startsWith('total') ||
          lower.contains('grand total') ||
          lower.contains('total belanja') ||
          lower.contains('jumlah tagihan');
      if (!isTotalRow) continue;

      final rpMatch = rpRegex.firstMatch(row);
      if (rpMatch != null) {
        final val = _parseSignedNumber(rpMatch.group(1)!).abs();
        if (val > best) best = val;
        continue;
      }

      final numMatches =
          RegExp(r'(\d{1,3}(?:[.,]\d{3})+|\d+)').allMatches(row);
      for (final m in numMatches) {
        final val = _parseSignedNumber(m.group(1)!).abs();
        if (val >= 100 && val < 500000000 && val > best) {
          best = val;
        }
      }
    }
    return best;
  }

  static DateTime? parseReceiptDate(String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return null;

    final monthMap = <String, int>{
      'jan': 1,
      'januari': 1,
      'feb': 2,
      'februari': 2,
      'mar': 3,
      'maret': 3,
      'apr': 4,
      'april': 4,
      'may': 5,
      'mei': 5,
      'jun': 6,
      'juni': 6,
      'jul': 7,
      'juli': 7,
      'aug': 8,
      'agu': 8,
      'agustus': 8,
      'sep': 9,
      'sept': 9,
      'september': 9,
      'oct': 10,
      'okt': 10,
      'oktober': 10,
      'nov': 11,
      'november': 11,
      'dec': 12,
      'des': 12,
      'desember': 12,
    };

    int hour = 0;
    int minute = 0;
    int second = 0;

    final timeMatch =
        RegExp(r'\b(\d{1,2}):(\d{2})(?::(\d{2}))?\b').firstMatch(cleaned);
    if (timeMatch != null) {
      final h = int.tryParse(timeMatch.group(1)!) ?? 0;
      final m = int.tryParse(timeMatch.group(2)!) ?? 0;
      final s = int.tryParse(timeMatch.group(3) ?? '0') ?? 0;
      if (h >= 0 && h <= 23 && m >= 0 && m <= 59 && s >= 0 && s <= 59) {
        hour = h;
        minute = m;
        second = s;
      }
    }

    int normalizeYear(int y) {
      if (y >= 100) return y;
      return y >= 70 ? 1900 + y : 2000 + y;
    }

    bool isValidYmd(int y, int m, int d) {
      if (m < 1 || m > 12 || d < 1 || d > 31) return false;
      final dt = DateTime(y, m, d);
      return dt.year == y && dt.month == m && dt.day == d;
    }

    final namedMatch = RegExp(
      r'\b(\d{1,2})\s+([a-zA-Z]+)\s+(\d{2,4})\b',
    ).firstMatch(cleaned);
    if (namedMatch != null) {
      final day = int.tryParse(namedMatch.group(1)!);
      final monthKey = namedMatch.group(2)!.toLowerCase();
      final rawYear = int.tryParse(namedMatch.group(3)!);
      final month = monthMap[monthKey];

      if (day != null && month != null && rawYear != null) {
        final year = normalizeYear(rawYear);
        if (isValidYmd(year, month, day)) {
          return DateTime(year, month, day, hour, minute, second);
        }
      }
    }

    final ymdMatch = RegExp(
      r'\b(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})\b',
    ).firstMatch(cleaned);
    if (ymdMatch != null) {
      final year = int.tryParse(ymdMatch.group(1)!);
      final month = int.tryParse(ymdMatch.group(2)!);
      final day = int.tryParse(ymdMatch.group(3)!);
      if (year != null &&
          month != null &&
          day != null &&
          isValidYmd(year, month, day)) {
        return DateTime(year, month, day, hour, minute, second);
      }
    }

    final dmyMatch = RegExp(
      r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})\b',
    ).firstMatch(cleaned);
    if (dmyMatch != null) {
      final day = int.tryParse(dmyMatch.group(1)!);
      final month = int.tryParse(dmyMatch.group(2)!);
      final rawYear = int.tryParse(dmyMatch.group(3)!);
      if (day != null && month != null && rawYear != null) {
        final year = normalizeYear(rawYear);
        if (isValidYmd(year, month, day)) {
          return DateTime(year, month, day, hour, minute, second);
        }
      }
    }

    return null;
  }

  static String _detectReceiptDate(List<String> rows) {
    final monthNameRegex = RegExp(
      r'\b\d{1,2}\s+(?:jan|feb|mar|apr|may|mei|jun|jul|aug|agu|sep|oct|okt|nov|dec|des)[a-z]*\s+\d{2,4}(?:\s*,?\s*\d{1,2}[:.]\d{2}(?:[:.]\d{2})?)?\b',
      caseSensitive: false,
    );
    final numericDateRegex = RegExp(
      r'\b(\d{1,2}[/\-.]\d{1,2}[/\-.]\d{2,4}|\d{4}[/\-.]\d{1,2}[/\-.]\d{1,2})(?:\s*,?\s*\d{1,2}[:.]\d{2}(?:[:.]\d{2})?)?\b',
    );
    final dateLabelLineRegex = RegExp(
      r'\b(tgl|tanggal|date|open\s*time|waktu|jam)\b',
      caseSensitive: false,
    );

    for (final row in rows) {
      final cleanRow = row.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
      if (!dateLabelLineRegex.hasMatch(cleanRow)) continue;

      final mMonth = monthNameRegex.firstMatch(cleanRow);
      if (mMonth != null) return mMonth.group(0)!.trim();

      final mNum = numericDateRegex.firstMatch(cleanRow);
      if (mNum != null) return mNum.group(0)!.trim();
    }

    for (final row in rows) {
      final cleanRow = row.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
      final mMonth = monthNameRegex.firstMatch(cleanRow);
      if (mMonth != null) return mMonth.group(0)!.trim();
    }

    for (final row in rows) {
      final cleanRow = row.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
      final mNum = numericDateRegex.firstMatch(cleanRow);
      if (mNum != null) return mNum.group(0)!.trim();
    }

    return '';
  }

  static String _detectStoreName(List<String> rows) {
    // 1. Cek seluruh baris struk untuk frasa pembayaran/transfer eksplisit (tidak terbatas baris awal)
    const transferPatterns = [
      'berhasil bayar ke ',
      'bayar ke ',
      'kirim ke ',
    ];

    for (final row in rows) {
      final cleanRow = row.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
      final lower = cleanRow.toLowerCase();

      for (final pattern in transferPatterns) {
        final idx = lower.indexOf(pattern);
        if (idx != -1) {
          final startIdx = idx + pattern.length;
          if (startIdx < cleanRow.length) {
            final candidate =
                cleanRow.substring(startIdx).split('-').first.trim();
            if (candidate.isNotEmpty) {
              return candidate;
            }
          }
        }
      }
    }

    // 2. Cek label "Nama merchant" di baris mana pun
    for (int i = 0; i < rows.length; i++) {
      final cleanRow = rows[i].replaceAll(RegExp(r'\s{2,}'), ' ').trim();
      final lower = cleanRow.toLowerCase();

      if (lower.startsWith('nama merchant')) {
        final afterColon = cleanRow.replaceFirst(
          RegExp(r'^nama\s+merchant\s*:?\s*', caseSensitive: false),
          '',
        );
        if (afterColon.isNotEmpty) return afterColon.trim();
        if (i + 1 < rows.length) {
          final nextClean =
              rows[i + 1].replaceAll(RegExp(r'\s{2,}'), ' ').trim();
          if (nextClean.isNotEmpty) return nextClean;
        }
      }
    }

    // 3. Fallback ke baris paling atas yang singkat dan bukan alamat
    const skipTopHeader = [
      'status',
      'sukses',
      'belum lunas',
      'rincian transaksi',
      'detail pembayaran',
      'npwp',
      'tower',
      'bon ',
      'kasir',
      'tgl',
      'tanggal',
      'waktu',
      'open time',
      'member',
      'telp',
      'wa:',
      'sms/',
      'gopay',
      'ovo',
      'dana',
      'shopeepay',
      'hore,',
      'split -',
      'bagi bukti',
    ];

    for (final row in rows.take(6)) {
      final cleanFirst = row.split(RegExp(r'\s{2,}')).first.trim();
      final lower = cleanFirst.toLowerCase();
      if (cleanFirst.length < 3) continue;
      if (skipTopHeader.any((k) => lower.contains(k))) continue;
      if (RegExp(r'^(rp|idr|\d)', caseSensitive: false).hasMatch(cleanFirst)) {
        continue;
      }
      if (RegExp(r'^[A-Z0-9]{10,}$').hasMatch(cleanFirst) &&
          !RegExp(r'^[A-Z\s&.\-]+$').hasMatch(cleanFirst)) {
        continue;
      }
      if (_looksLikeAddressOrLongText(cleanFirst)) continue;

      return cleanFirst;
    }

    return 'Toko Baru';
  }
  
  static List<ReceiptItem> _parseExplicitRpRows(
    List<String> rows,
    RegExp rpRegex,
    void Function(double) onFallbackPrice,
  ) {
    final Map<String, ReceiptItem> grouped = {};

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      final match = rpRegex.firstMatch(row);
      if (match == null) continue;

      final price = _parseSignedNumber(match.group(1)!);
      if (price == 0 || price.abs() >= 100000000) continue;

      onFallbackPrice(price.abs());
      if (_isNonProductLine(row)) continue;

      String itemName = row.substring(0, match.start).trim();
      itemName = itemName.replaceAll(RegExp(r'[-:=]+$'), '').trim();

      if (itemName.isEmpty && i > 0) {
        final prev = rows[i - 1].split(RegExp(r'\s{2,}')).first.trim();
        if (!rpRegex.hasMatch(prev) &&
            !_isNonProductLine(prev) &&
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

      final normalizedPrice = _normalizeItemPrice(itemName, price);
      _addOrMergeItem(grouped, itemName, qty, normalizedPrice);
    }

    return grouped.values.toList();
  }

  static List<ReceiptItem> _parseCashierReceiptRows(
    List<String> rows,
    void Function(double) onFallbackPrice,
  ) {
    final stopKeywords = [
      'subtotal',
      'sub total',
      'subtota',
      'total item',
      'total disc',
      'total belanja',
      'grand total',
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
      'open time',
      'user:',
      'table ',
      'pax',
      'belum lunas',
      'bandung regency',
      'jawa barat',
      'telp',
      'sms/',
    ];

    final qtyUnitSubtotalRegex = RegExp(
      r'^(\d{1,3})\s*[xX*]\s*(\d{1,3}(?:[.,]\d{3})+|\d+)(?:\s+(\d{1,3}(?:[.,]\d{3})+|\d+))?$',
    );
    final fourColRegex = RegExp(
      r'^(.+?)\s{2,}(\d{1,3})\s+(\d{1,3}(?:[.,]\d{3})+)\s+(\d{1,3}(?:[.,]\d{3})+)$',
    );
    final threePriceColRegex = RegExp(
      r'^(.+?)\s{2,}(\d{1,3}(?:[.,]\d{3})+)\s+(\d{1,3}(?:[.,]\d{3})+)$',
    );
    final threeQtyColRegex = RegExp(
      r'^(.+?)\s{2,}(\d{1,2})\s+(\d{1,3}(?:[.,]\d{3})+)$',
    );
    final twoColRegex = RegExp(
      r'^(.+?)\s{2,}(\(?\s*-?\s*(?:\d{1,3}(?:[.,]\d{3})+|\d+)\s*\)?)$',
    );
    final discRegex = RegExp(
      r'^(?:disc|diskon)\.?\s*-?\s*(\d{1,3}(?:[.,]\d{3})+|\d+)$',
      caseSensitive: false,
    );

    final Map<String, ReceiptItem> grouped = {};
    String? lastAddedKey;
    String? pendingProductName;
    bool passedSubtotal = false;

    for (final row in rows) {
      final cleanRow = row.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
      final lower = cleanRow.toLowerCase();

      if (lower.startsWith('total') ||
          lower.contains('total belanja') ||
          lower.contains('grand total')) {
        final m = RegExp(r'(\d{1,3}(?:[.,]\d{3})+)').firstMatch(cleanRow);
        if (m != null) {
          onFallbackPrice(_parseSignedNumber(m.group(1)!).abs());
        }
        break;
      }

      if (lower.startsWith('subtotal') || lower.startsWith('sub total')) {
        passedSubtotal = true;
        pendingProductName = null;
        continue;
      }

      if (passedSubtotal && !_isChargeLine(cleanRow)) {
        pendingProductName = null;
        continue;
      }

      if (stopKeywords.any((kw) => lower == kw || lower.startsWith(kw)) ||
          _isNonProductLine(cleanRow)) {
        if (lower.startsWith('jumlah') || lower.startsWith('tunai')) {
          break;
        }
        pendingProductName = null;
        continue;
      }

      if (skipLineKeywords.any((kw) => lower.contains(kw))) {
        pendingProductName = null;
        continue;
      }

      if (RegExp(r'^[A-Z0-9]{10,}$').hasMatch(cleanRow) &&
          !RegExp(r'^[A-Z\s]+$').hasMatch(cleanRow)) {
        pendingProductName = null;
        continue;
      }

      final discMatch = discRegex.firstMatch(cleanRow);
      if (discMatch != null &&
          lastAddedKey != null &&
          grouped.containsKey(lastAddedKey)) {
        final discVal = _parseSignedNumber(discMatch.group(1)!).abs();
        final prevItem = grouped[lastAddedKey]!;
        final updatedPrice = prevItem.price - discVal;
        grouped[lastAddedKey] = ReceiptItem(
          name: prevItem.name,
          quantity: prevItem.quantity,
          price: updatedPrice,
        );
        continue;
      }

      final qSubMatch = qtyUnitSubtotalRegex.firstMatch(cleanRow);
      if (qSubMatch != null && pendingProductName != null) {
        final qty = (int.tryParse(qSubMatch.group(1)!) ?? 1).clamp(1, 9999);
        double unitPrice = _parseSignedNumber(qSubMatch.group(2)!);
        final double subtotal = qSubMatch.group(3) != null
            ? _parseSignedNumber(qSubMatch.group(3)!)
            : 0;

        if (unitPrice <= 0 && subtotal > 0) {
          unitPrice = subtotal / qty;
        }

        if (unitPrice.abs() >= 1 && unitPrice.abs() < 50000000) {
          final adjustedPrice = _normalizeItemPrice(pendingProductName, unitPrice);
          lastAddedKey = _addOrMergeItem(
            grouped,
            pendingProductName,
            qty,
            adjustedPrice,
          );
        }
        pendingProductName = null;
        continue;
      }

      String? itemName;
      int qty = 1;
      double unitPrice = 0;

      final m4 = fourColRegex.firstMatch(row);
      final m3Price = threePriceColRegex.firstMatch(row);
      final m3Qty = threeQtyColRegex.firstMatch(row);
      final m2 = twoColRegex.firstMatch(row);

      if (m4 != null) {
        itemName = m4.group(1)!.trim();
        qty = (int.tryParse(m4.group(2)!) ?? 1).clamp(1, 9999);
        unitPrice = _parseSignedNumber(m4.group(3)!);
      } else if (m3Price != null) {
        itemName = m3Price.group(1)!.trim();
        final firstNum = _parseSignedNumber(m3Price.group(2)!);
        final secondNum = _parseSignedNumber(m3Price.group(3)!);
        if (secondNum >= firstNum && firstNum > 0) {
          qty = (secondNum / firstNum).round().clamp(1, 9999);
          unitPrice = firstNum;
        } else {
          unitPrice = secondNum;
        }
      } else if (m3Qty != null) {
        itemName = m3Qty.group(1)!.trim();
        qty = (int.tryParse(m3Qty.group(2)!) ?? 1).clamp(1, 9999);
        final totalRowPrice = _parseSignedNumber(m3Qty.group(3)!);
        unitPrice = qty > 0 ? totalRowPrice / qty : totalRowPrice;
      } else if (m2 != null) {
        itemName = m2.group(1)!.trim();
        unitPrice = _parseSignedNumber(m2.group(2)!);
      }

      if (itemName != null &&
          itemName.length >= 2 &&
          !RegExp(r'^\d+$').hasMatch(itemName) &&
          !_isNonProductLine(itemName) &&
          unitPrice.abs() >= 1 &&
          unitPrice.abs() < 50000000) {
        itemName = itemName.replaceAll(RegExp(r'[-:=]+$'), '').trim();
        final adjustedPrice = _normalizeItemPrice(itemName, unitPrice);
        lastAddedKey = _addOrMergeItem(grouped, itemName, qty, adjustedPrice);
        pendingProductName = null;
        continue;
      }

      final hasLetters = RegExp(r'[a-zA-Z]{2,}').hasMatch(cleanRow);
      final hasPriceLikeNumber =
          RegExp(r'\d{1,3}(?:[.,]\d{3})+').hasMatch(cleanRow);
      if (!passedSubtotal &&
          hasLetters &&
          !hasPriceLikeNumber &&
          cleanRow.length >= 2 &&
          !_isNonProductLine(cleanRow)) {
        pendingProductName = cleanRow.replaceAll(RegExp(r'[-:=]+$'), '').trim();
      } else {
        pendingProductName = null;
      }
    }

    return grouped.values.toList();
  }

  static String _addOrMergeItem(
    Map<String, ReceiptItem> grouped,
    String itemName,
    int qty,
    double unitPrice,
  ) {
    if (_isNonProductLine(itemName)) return '';
    final key = itemName.toLowerCase();
    if (grouped.containsKey(key)) {
      final existing = grouped[key]!;
      grouped[key] = ReceiptItem(
        name: existing.name,
        quantity: existing.quantity + qty,
        price: unitPrice != 0 ? unitPrice : existing.price,
      );
    } else {
      grouped[key] = ReceiptItem(
        name: itemName,
        quantity: qty > 0 ? qty : 1,
        price: unitPrice,
      );
    }
    return key;
  }
}