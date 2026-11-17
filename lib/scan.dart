import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

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
          final designLeft = (constraints.maxWidth - 405) / 2;

          return Stack(
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
                top: 0,
                left: designLeft,
                child: SvgPicture.asset(
                  'assets/7c491.svg',
                  width: 405,
                  height: 150,
                ),
              ),
              Positioned(
                bottom: 0,
                left: designLeft,
                child: SvgPicture.asset(
                  'assets/be877.svg',
                  width: 405,
                  height: 250,
                ),
              ),
              Positioned(
                top: 40,
                left: designLeft + 25,
                child: SizedBox(
                  width: 22,
                  height: 40,
                  child: InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/25d47.svg',
                        width: 22,
                        height: 17,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: designLeft + 41,
                bottom: 151,
                child: _ScanControl(
                  semanticLabel:
                      _flashEnabled ? 'Turn flashlight off' : 'Turn flashlight on',
                  onPressed: _toggleFlash,
                  asset: 'assets/e7334.svg',
                  width: 66,
                  height: 66,
                ),
              ),
              Positioned(
                right: designLeft + 38,
                bottom: 151,
                child: _ScanControl(
                  semanticLabel: 'Choose image from device storage',
                  onPressed: _selectImage,
                  asset: 'assets/144a1.svg',
                  width: 66,
                  height: 66,
                ),
              ),
              Positioned(
                left: designLeft + 168.5,
                bottom: 73.5,
                child: _ScanControl(
                  semanticLabel: 'Capture image',
                  onPressed: _capturing ? null : _captureImage,
                  asset: 'assets/77734.svg',
                  width: 71,
                  height: 71,
                ),
              ),
            ],
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
    required this.width,
    required this.height,
  });

  final String semanticLabel;
  final VoidCallback? onPressed;
  final String asset;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SvgPicture.asset(asset, width: width, height: height),
      ),
    );
  }
}
