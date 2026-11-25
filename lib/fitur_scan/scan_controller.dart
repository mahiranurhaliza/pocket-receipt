import 'dart:io';
import 'dart:typed_data';

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
        storeName: 'Alfamart',
        totalAmount: 0,
        rawText: '',
        items: [ReceiptItem(name: 'Item 1', quantity: 1, price: 0)],
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

  Future<int> saveReceipt({
    required String storeName,
    required String category,
    required String sourceOfFunds,
    required List<ReceiptItem> items,
    String? imagePath,
    String note = '',
  }) async {
    final savedPath = await persistImage(imagePath);
    final total =
        items.fold<double>(0, (sum, item) => sum + item.subtotal);

    final model = ReceiptModel(
      storeName: storeName.trim().isEmpty ? 'Alfamart' : storeName.trim(),
      date: DateTime.now(),
      totalAmount: total,
      category: category,
      sourceOfFunds: sourceOfFunds,
      imagePath: savedPath,
      note: note,
      items: items,
    );

    return DatabaseService.instance.insertReceipt(model);
  }
}