import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({
    super.key,
    this.cameraController,
    this.onToggleFlash,
    this.onFocusTap,
    this.onImageCaptured,
    this.onImageSelected,
  });

  final CameraController? cameraController;
  final Future<bool> Function()? onToggleFlash;
  final Future<void> Function(Offset normalizedPoint)? onFocusTap;
  final ValueChanged<String>? onImageCaptured;
  final ValueChanged<String>? onImageSelected;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  Uint8List? _previewBytes;
  bool _capturing = false;
  bool _flashEnabled = false;

  @override
  void initState() {
    super.initState();
    _syncFlashFromController(widget.cameraController);
  }

  @override
  void didUpdateWidget(covariant ScanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cameraController != widget.cameraController) {
      _syncFlashFromController(widget.cameraController);
    }
  }

  void _syncFlashFromController(CameraController? controller) {
    if (controller != null && controller.value.isInitialized) {
      _flashEnabled = controller.value.flashMode == FlashMode.torch;
    }
  }

  Future<void> _toggleFlash() async {
    if (widget.onToggleFlash != null) {
      final enabled = await widget.onToggleFlash!();
      if (mounted) {
        setState(() => _flashEnabled = enabled);
      }
      return;
    }
    setState(() => _flashEnabled = !_flashEnabled);
  }

  Future<void> _captureImage() async {
    if (_capturing) return;
    setState(() => _capturing = true);

    try {
      if (widget.onImageCaptured != null) {
        widget.onImageCaptured!('camera://capture');
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ScanDetailed(receiptBytes: _previewBytes),
        ),
      );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _selectImage() async {
    if (_capturing) return;
    setState(() => _capturing = true);

    try {
      if (widget.onImageSelected != null) {
        widget.onImageSelected!('gallery://pick');
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ScanDetailed(receiptBytes: _previewBytes),
        ),
      );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
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
                  Positioned(
                    width: constraints.maxWidth,
                    height: pageHeight,
                    child: _ScanPreviewSurface(
                      cameraController: widget.cameraController,
                      previewBytes: _previewBytes,
                      capturing: _capturing,
                      flashEnabled: _flashEnabled,
                      onFocusTap: widget.onFocusTap,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    width: constraints.maxWidth,
                    child: IgnorePointer(
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
                  ),
                  Positioned(
                    bottom: 0,
                    width: constraints.maxWidth,
                    child: IgnorePointer(
                      child: SvgPicture.asset(
                        'assets/cover/bg-1.svg',
                        width: contentWidth,
                        height: 250,
                        fit: BoxFit.fill,
                        placeholderBuilder: (_) => Container(
                          width: contentWidth,
                          height: 250,
                          decoration: const BoxDecoration(
                            color: Color(0xFFECECEC),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(48),
                            ),
                          ),
                        ),
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
                        onTap: () => Navigator.of(context).maybePop(),
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
                    left: contentLeft,
                    bottom: 151,
                    width: tileWidth,
                    child: Center(
                      child: _ScanControl(
                        semanticLabel: _flashEnabled
                            ? 'Turn flashlight off'
                            : 'Turn flashlight on',
                        onPressed: _toggleFlash,
                        asset: 'assets/icons/flashlight.svg',
                        fallbackIcon: Icons.bolt,
                        active: _flashEnabled,
                        width: 66,
                        height: 66,
                      ),
                    ),
                  ),
                  Positioned(
                    left: contentLeft + tileWidth + tileGap,
                    bottom: 151,
                    width: tileWidth,
                    child: Center(
                      child: _ScanControl(
                        semanticLabel: 'Choose image from device storage',
                        onPressed: _capturing ? null : _selectImage,
                        asset: 'assets/icons/add-media.svg',
                        fallbackIcon: Icons.add_photo_alternate_outlined,
                        width: 66,
                        height: 66,
                      ),
                    ),
                  ),
                  Positioned(
                    left: (constraints.maxWidth - 71) / 2,
                    bottom: 73.5,
                    child: _ScanControl(
                      semanticLabel: 'Capture image',
                      onPressed: _capturing ? null : _captureImage,
                      asset: 'assets/icons/capture.svg',
                      fallbackIcon: Icons.circle,
                      isCapture: true,
                      width: 71,
                      height: 71,
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

class _ScanPreviewSurface extends StatefulWidget {
  const _ScanPreviewSurface({
    required this.cameraController,
    required this.previewBytes,
    required this.capturing,
    required this.flashEnabled,
    this.onFocusTap,
  });

  final CameraController? cameraController;
  final Uint8List? previewBytes;
  final bool capturing;
  final bool flashEnabled;
  final Future<void> Function(Offset normalizedPoint)? onFocusTap;

  @override
  State<_ScanPreviewSurface> createState() => _ScanPreviewSurfaceState();
}

class _ScanPreviewSurfaceState extends State<_ScanPreviewSurface> {
  Offset? _focusPoint;
  bool _showFocusRing = false;
  int _focusToken = 0;

  void _handleTapDown(TapDownDetails details, BoxConstraints constraints) {
    final controller = widget.cameraController;
    final canFocusCamera =
        controller != null && controller.value.isInitialized && !widget.capturing;
    if (!canFocusCamera) return;
    if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) return;

    final local = details.localPosition;
    final normalized = Offset(
      (local.dx / constraints.maxWidth).clamp(0.0, 1.0),
      (local.dy / constraints.maxHeight).clamp(0.0, 1.0),
    );

    final currentToken = ++_focusToken;
    setState(() {
      _focusPoint = local;
      _showFocusRing = true;
    });

    widget.onFocusTap?.call(normalized);

    Future<void>.delayed(const Duration(milliseconds: 950), () {
      if (!mounted || currentToken != _focusToken) return;
      setState(() => _showFocusRing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.cameraController;
    final hasCameraPreview =
        controller != null && controller.value.isInitialized;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _handleTapDown(details, constraints),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.previewBytes != null)
                Image.memory(widget.previewBytes!, fit: BoxFit.cover)
              else if (hasCameraPreview)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.value.previewSize?.height ?? 1,
                    height: controller.value.previewSize?.width ?? 1,
                    child: CameraPreview(controller),
                  ),
                )
              else
                const ColoredBox(color: Color(0xFF1E1E1E)),
              if (widget.flashEnabled)
                const IgnorePointer(
                  child: ColoredBox(color: Color.fromRGBO(255, 255, 255, 0.14)),
                ),
              if (_showFocusRing && _focusPoint != null)
                Positioned(
                  left: _focusPoint!.dx - 30,
                  top: _focusPoint!.dy - 30,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: _showFocusRing ? 1.0 : 0.0,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFEC5C),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (widget.capturing)
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE55B5B)),
                ),
            ],
          ),
        );
      },
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
    this.active = false,
    this.isCapture = false,
  });

  final String semanticLabel;
  final VoidCallback? onPressed;
  final String asset;
  final IconData fallbackIcon;
  final double width;
  final double height;
  final bool active;
  final bool isCapture;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox(
          width: width,
          height: height,
          child: SvgPicture.asset(
            asset,
            width: width,
            height: height,
            fit: BoxFit.contain,
            placeholderBuilder: (_) => isCapture
                ? Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF8F8F8),
                      border: Border.all(
                        color: const Color(0xFFDDDDDD),
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE55B5B),
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF8F8F8),
                      border: Border.all(
                        color: active
                            ? const Color(0xFF22918B)
                            : const Color(0xFFE0E0E0),
                      ),
                    ),
                    child: Icon(
                      fallbackIcon,
                      size: width * 0.4,
                      color: const Color(0xFFB388EB),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class ScanDetailed extends StatelessWidget {
  const ScanDetailed({super.key, required this.receiptBytes});

  final Uint8List? receiptBytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt preview')),
      body: Center(
        child: receiptBytes == null
            ? const Text('No image captured')
            : Image.memory(receiptBytes!, fit: BoxFit.contain),
      ),
    );
  }
}