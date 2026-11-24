import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'scanDetailed.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ScanScreen(),
    ),
  );
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({
    super.key,
    this.onImageCaptured,
    this.onImageSelected,
  });

  final ValueChanged<String>? onImageCaptured;
  final ValueChanged<String>? onImageSelected;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  Uint8List? _previewBytes;
  bool _capturing = false;
  bool _flashEnabled = false;

  void _toggleFlash() {
    setState(() => _flashEnabled = !_flashEnabled);
  }

  Future<void> _openReceiptEditor({
    required Uint8List? receiptBytes,
    required String? callbackPath,
    required ValueChanged<String>? onCallback,
  }) async {
    if (!mounted) return;
    setState(() {
      _previewBytes = receiptBytes;
    });
    if (callbackPath != null) {
      onCallback?.call(callbackPath);
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ScanDetailedScreen(receiptBytes: receiptBytes),
      ),
    );
  }

  Future<void> _captureImage() async {
    if (_capturing) return;

    setState(() => _capturing = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      await _openReceiptEditor(
        receiptBytes: null,
        callbackPath: 'simulated://captured_receipt.png',
        onCallback: widget.onImageCaptured,
      );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _selectImage() async {
    if (_capturing) return;

    setState(() => _capturing = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      await _openReceiptEditor(
        receiptBytes: null,
        callbackPath: 'simulated://selected_receipt.png',
        onCallback: widget.onImageSelected,
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
                      previewBytes: _previewBytes,
                      capturing: _capturing,
                      flashEnabled: _flashEnabled,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    width: constraints.maxWidth,
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
                  Positioned(
                    bottom: 0,
                    width: constraints.maxWidth,
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

class _ScanPreviewSurface extends StatelessWidget {
  const _ScanPreviewSurface({
    required this.previewBytes,
    required this.capturing,
    required this.flashEnabled,
  });

  final Uint8List? previewBytes;
  final bool capturing;
  final bool flashEnabled;

  @override
  Widget build(BuildContext context) {
    if (previewBytes != null) {
      return Image.memory(previewBytes!, fit: BoxFit.cover);
    }

    return Stack(
      children: [
        const ColoredBox(
          color: Color(0xFF1E1E1E),
          child: SizedBox.expand(),
        ),
        if (flashEnabled)
          const Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(color: Color.fromRGBO(255, 255, 255, 0.14)),
            ),
          ),
        if (capturing)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFFE55B5B)),
          ),
      ],
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