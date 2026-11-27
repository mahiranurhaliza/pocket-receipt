import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Offset;

import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/database_service.dart';
import '../database/receipt_model.dart';
import 'ocr_service.dart';

class ScanCaptureOutcome {
  const ScanCaptureOutcome({
    required this.imagePath,
    required this.imageBytes,
    required this.ocrResult,
  });

  final String imagePath;
  final Uint8List imageBytes;
  final OcrResult ocrResult;
}

class ScanController {
  ScanController({
    this.preferredCamera,
    ImagePicker? imagePicker,
  }) : _imagePicker = imagePicker ?? ImagePicker();

  final CameraDescription? preferredCamera;
  final ImagePicker _imagePicker;

  CameraController? _cameraController;
  bool _flashEnabled = false;
  bool _initializing = false;

  CameraController? get cameraController => _cameraController;
  bool get isFlashEnabled => _flashEnabled;

  Future<void> initializeCamera() async {
    if (_initializing) return;
    _initializing = true;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final selected = preferredCamera ??
          cameras.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.back,
            orElse: () => cameras.first,
          );

      final controller = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);

      final previous = _cameraController;
      _cameraController = controller;
      _flashEnabled = false;
      await previous?.dispose();
    } finally {
      _initializing = false;
    }
  }

  Future<void> disposeCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    await controller?.dispose();
  }

  Future<bool> toggleFlash() async {
    final controller = _cameraController;
    if (controller != null && controller.value.isInitialized) {
      final next = !_flashEnabled;
      await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      _flashEnabled = next;
    } else {
      _flashEnabled = !_flashEnabled;
    }
    return _flashEnabled;
  }

  /// Mengatur titik fokus dan eksposur kamera berdasarkan koordinat ternormalisasi `(0.0..1.0, 0.0..1.0)`.
  Future<void> focusAtNormalizedPoint(Offset normalizedPoint) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    final clamped = Offset(
      normalizedPoint.dx.clamp(0.0, 1.0),
      normalizedPoint.dy.clamp(0.0, 1.0),
    );

    try {
      if (controller.value.focusPointSupported) {
        await controller.setFocusPoint(clamped);
      }
    } catch (_) {}

    try {
      if (controller.value.exposurePointSupported) {
        await controller.setExposurePoint(clamped);
      }
    } catch (_) {}

    try {
      await controller.setFocusMode(FocusMode.auto);
    } catch (_) {}
  }

  /// Mengembalikan mode fokus dan titik fokus/eksposur ke default otomatis.
  Future<void> resetFocus() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      await controller.setFocusMode(FocusMode.auto);
      if (controller.value.focusPointSupported) {
        await controller.setFocusPoint(null);
      }
      if (controller.value.exposurePointSupported) {
        await controller.setExposurePoint(null);
      }
    } catch (_) {}
  }

  Future<ScanCaptureOutcome?> captureAndScan() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return pickFromGalleryAndScan();
    }

    final photo = await controller.takePicture();
    final bytes = await photo.readAsBytes();
    final ocr = await _safeScan(photo.path);

    return ScanCaptureOutcome(
      imagePath: photo.path,
      imageBytes: bytes,
      ocrResult: ocr,
    );
  }

  Future<ScanCaptureOutcome?> pickFromGalleryAndScan() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final ocr = await _safeScan(picked.path);

    return ScanCaptureOutcome(
      imagePath: picked.path,
      imageBytes: bytes,
      ocrResult: ocr,
    );
  }

  Future<OcrResult> _safeScan(String imagePath) async {
    try {
      return await OcrService.scanReceipt(imagePath);
    } catch (_) {
      return const OcrResult(
        storeName: '',
        totalAmount: 0,
        rawText: '',
        items: [ReceiptItem(name: 'Item 1', quantity: 1, price: 0)],
        receiptDateText: '',
      );
    }
  }

  Future<String?> persistImage(String? sourcePath) async {
    if (sourcePath == null ||
        sourcePath.isEmpty ||
        sourcePath.startsWith('simulated://')) {
      return null;
    }

    final file = File(sourcePath);
    if (!file.existsSync()) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName =
        'receipt_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}';
    final copied = await file.copy(p.join(appDir.path, fileName));
    return copied.path;
  }

  List<ReceiptItem> normalizeItems(List<ReceiptItem> rawItems) {
  final blockedWords = RegExp(
    r'\b(total|total item|total belanja|total disc|subtotal|sub total|subtota\w*|jumlah|tunai|kembalian)\b',
    caseSensitive: false,
  );

  final filtered = rawItems
      .where((item) => !blockedWords.hasMatch(item.name.trim()))
      .toList();

  final sourceList = filtered.isNotEmpty
        ? filtered
        : [const ReceiptItem(name: 'nama produk', quantity: 1, price: 0)];

    final Map<String, ReceiptItem> merged = {};
    for (int i = 0; i < sourceList.length; i++) {
      final item = sourceList[i];
      final name =
          item.name.trim().isEmpty ? 'nama produk' : item.name.trim();
      final qty = item.quantity > 0 ? item.quantity : 1;
      final price = item.price.isFinite ? item.price : 0.0;

      final key = '${name.toLowerCase()}_${price.toStringAsFixed(0)}';
      if (merged.containsKey(key)) {
        final existing = merged[key]!;
        merged[key] = ReceiptItem(
          name: existing.name,
          quantity: existing.quantity + qty,
          price: existing.price,
        );
      } else {
        merged[key] = ReceiptItem(
          name: name,
          quantity: qty,
          price: price,
        );
      }
    }

    return merged.values.toList();
}

  Future<int> saveReceipt({
    required String storeName,
    required String category,
    required String sourceOfFunds,
    required List<ReceiptItem> items,
    String? imagePath,
    String note = '',
    String receiptDateText = '',
  }) async {
    final savedPath = await persistImage(imagePath);
    final normalizedItems = normalizeItems(items);
    final total = normalizedItems.fold<double>( 0,
          (sum, item) => sum + (item.price * item.quantity),);

    final trimmedNote = note.trim();
    final cleanReceiptDate = receiptDateText.trim();
    final effectiveNote = trimmedNote.isNotEmpty
        ? trimmedNote
        : (cleanReceiptDate.isNotEmpty ? 'Tgl struk: $cleanReceiptDate' : '');

    final model = ReceiptModel(
      storeName:
          storeName.trim().isEmpty ? 'Toko Tanpa Nama' : storeName.trim(),
      date: DateTime.now(),
      totalAmount: total,
      category: category,
      sourceOfFunds: sourceOfFunds,
      imagePath: savedPath,
      note: effectiveNote,
      items: normalizedItems,
    );

    return DatabaseService.instance.insertReceipt(model);
  }
}