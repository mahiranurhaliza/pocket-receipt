import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'models/receipt_model.dart';
import 'services/database_service.dart';
import 'services/ocr_service.dart';

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({
    super.key,
    this.camera,
    this.onImageCaptured,
    this.onImageSelected,
  });

  final CameraDescription? camera;
  final ValueChanged<String>? onImageCaptured;
  final ValueChanged<String>? onImageSelected;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with WidgetsBindingObserver {
  final _imagePicker = ImagePicker();

  CameraController? _cameraController;
  Uint8List? _selectedImage;
  String? _cameraError;
  bool _initializing = false;
  bool _capturing = false;
  bool _flashEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (_initializing) return;
    _initializing = true;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('NoCamera', 'No camera is available.');
      }

      final selectedCamera = widget.camera ??
          cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
            orElse: () => cameras.first,
          );
      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      final previousController = _cameraController;
      setState(() {
        _cameraController = controller;
        _cameraError = null;
        _flashEnabled = false;
      });
      await previousController?.dispose();
    } on CameraException catch (error) {
      if (mounted) {
        setState(() => _cameraError = error.description ?? error.code);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _cameraError = error.toString());
      }
    } finally {
      _initializing = false;
    }
  }

  Future<void> _disposeCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    await controller?.dispose();
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      final enabled = !_flashEnabled;
      await controller.setFlashMode(
        enabled ? FlashMode.torch : FlashMode.off,
      );
      if (mounted) setState(() => _flashEnabled = enabled);
    } on CameraException catch (error) {
      _showError(error.description ?? error.code);
    }
  }

  Future<void> _captureImage() async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        _capturing) {
      return;
    }

    setState(() => _capturing = true);
    try {
      final image = await controller.takePicture();
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() => _selectedImage = bytes);
      widget.onImageCaptured?.call(image.path);
      await _processAndSaveReceipt(image.path);
    } on CameraException catch (error) {
      _showError(error.description ?? error.code);
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _selectImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() => _selectedImage = bytes);
      widget.onImageSelected?.call(image.path);
      await _processAndSaveReceipt(image.path);
    } catch (error) {
      _showError(error.toString());
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _processAndSaveReceipt(String imagePath) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFF05A5A)),
      ),
    );

    OcrResult ocrResult;
    try {
      ocrResult = await OcrService.scanReceipt(imagePath);
    } catch (_) {
      ocrResult = OcrResult(storeName: '', totalAmount: 0, rawText: '');
    }

    if (!mounted) return;
    Navigator.of(context).pop();

    final storeController = TextEditingController(text: ocrResult.storeName);
    final amountController = TextEditingController(
      text: ocrResult.totalAmount > 0
          ? ocrResult.totalAmount.toStringAsFixed(0)
          : '',
    );
    String selectedCategory = 'Makanan';
    final categories = ['Makanan', 'Belanja', 'Transportasi', 'Tagihan', 'Lainnya'];

    String selectedSourceOfFunds = 'Cash';
    final List<String> fundSources = [
      'Cash',
      'GoPay',
      'OVO',
      'DANA',
      'ShopeePay',
      'BCA',
      'BNI',
      'Mandiri',
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF262626),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detail Struk Belanja',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: storeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Nama Toko',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white30),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFF05A5A)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Total Harga (Rp)',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white30),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFF05A5A)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    dropdownColor: const Color(0xFF262626),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white30),
                      ),
                    ),
                    items: categories
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedCategory = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSourceOfFunds,
                    dropdownColor: const Color(0xFF262626),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Sumber Dana (Cash / E-Wallet / Bank)',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white30),
                      ),
                    ),
                    items: fundSources
                        .map((src) => DropdownMenuItem(
                              value: src,
                              child: Text(src),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedSourceOfFunds = val);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
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
                      onPressed: () async {
                        try {
                          final store = storeController.text.trim().isEmpty
                              ? 'Toko Tanpa Nama'
                              : storeController.text.trim();
                          final amount =
                              double.tryParse(amountController.text.trim()) ?? 0;

                          final appDir = await getApplicationDocumentsDirectory();
                          final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}${p.extension(imagePath)}';
                          final savedImage = await File(imagePath).copy('${appDir.path}/$fileName');

                          final newReceipt = ReceiptModel(
                            storeName: store,
                            category: selectedCategory,
                            sourceOfFunds: selectedSourceOfFunds,
                            date: DateTime.now(),
                            totalAmount: amount,
                            imagePath: savedImage.path, // Menggunakan path permanen
                          );

                          await DatabaseService.instance.insertReceipt(newReceipt);

                          if (!ctx.mounted) return;
                          Navigator.of(ctx).pop();
                          setState(() => _selectedImage = null);
                          _showError('Struk berhasil disimpan ke riwayat!');
                        } catch (e) {
                          if (!ctx.mounted) return;
                          Navigator.of(ctx).pop();
                          _showError('Gagal menyimpan: $e');
                        }
                      },
                      child: const Text(
                        'Simpan Struk',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox.expand(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: _CameraSurface(
                    controller: _cameraController,
                    selectedImage: _selectedImage,
                    error: _cameraError,
                  ),
                ),
                Positioned(
                  top: 48,
                  left: 24,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ),
                Positioned(
                  left: 40,
                  bottom: 85,
                  child: _ScanControl(
                    semanticLabel: _flashEnabled
                        ? 'Turn flashlight off'
                        : 'Turn flashlight on',
                    onPressed: _toggleFlash,
                    asset: 'assets/e7334.svg',
                    fallbackIcon:
                        _flashEnabled ? Icons.flash_on : Icons.flash_off,
                    width: 60,
                    height: 60,
                  ),
                ),
                Positioned(
                  left: (constraints.maxWidth - 74) / 2,
                  bottom: 78,
                  child: _ScanControl(
                    semanticLabel: 'Capture image',
                    onPressed: _capturing ? null : _captureImage,
                    asset: 'assets/77734.svg',
                    fallbackIcon: Icons.camera_alt,
                    width: 74,
                    height: 74,
                    isPrimary: true,
                  ),
                ),
                Positioned(
                  right: 40,
                  bottom: 85,
                  child: _ScanControl(
                    semanticLabel: 'Choose image from device storage',
                    onPressed: _selectImage,
                    asset: 'assets/144a1.svg',
                    fallbackIcon: Icons.photo_library,
                    width: 60,
                    height: 60,
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

class _CameraSurface extends StatelessWidget {
  const _CameraSurface({
    required this.controller,
    required this.selectedImage,
    required this.error,
  });

  final CameraController? controller;
  final Uint8List? selectedImage;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (selectedImage != null) {
      return Image.memory(selectedImage!, fit: BoxFit.cover);
    }

    if (controller != null && controller!.value.isInitialized) {
      return LayoutBuilder(
        builder: (context, constraints) {
          var scale = constraints.maxHeight /
              constraints.maxWidth *
              controller!.value.aspectRatio;
          if (scale < 1) scale = 1.0;

          return ClipRect(
            child: Transform.scale(
              scale: scale,
              child: Center(child: CameraPreview(controller!)),
            ),
          );
        },
      );
    }

    return ColoredBox(
      color: const Color(0xFF1E1E1E),
      child: Center(
        child: error == null
            ? const CircularProgressIndicator(color: Color(0xFFF05A5A))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Bricolage Grotesque',
                    fontSize: 15,
                  ),
                ),
              ),
      ),
    );
  }
}

class _ScanControl extends StatelessWidget {
  const _ScanControl({
    required this.semanticLabel,
    required this.onPressed,
    required this.asset,
    required this.fallbackIcon,
    required this.width,
    required this.height,
    this.isPrimary = false,
  });

  final String semanticLabel;
  final VoidCallback? onPressed;
  final String asset;
  final IconData fallbackIcon;
  final double width;
  final double height;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: isPrimary ? const Color(0xFFF05A5A) : Colors.black54,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(
            fallbackIcon,
            color: Colors.white,
            size: isPrimary ? 34 : 26,
          ),
        ),
      ),
    );
  }
}