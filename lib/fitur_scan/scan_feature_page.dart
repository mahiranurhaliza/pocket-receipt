import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../UI/scan.dart';
import 'scan_controller.dart';
import 'scan_detail_feature_page.dart';

class ScanFeaturePage extends StatefulWidget {
  const ScanFeaturePage({
    super.key,
    this.camera,
  });

  final CameraDescription? camera;

  @override
  State<ScanFeaturePage> createState() => _ScanFeaturePageState();
}

class _ScanFeaturePageState extends State<ScanFeaturePage>
    with WidgetsBindingObserver {
  late final ScanController _controller;
  bool _handling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = ScanController(preferredCamera: widget.camera);
    _initAndRefresh();
  }

  Future<void> _initAndRefresh() async {
    try {
      await _controller.initializeCamera();
    } catch (_) {
      // Abaikan error inisialisasi agar layar tetap aman
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _controller.disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initAndRefresh();
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openDetailWithOutcome(ScanCaptureOutcome? outcome) async {
    if (!mounted || outcome == null) return;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ScanDetailFeaturePage(
          imagePath: outcome.imagePath,
          imageBytes: outcome.imageBytes,
          ocrResult: outcome.ocrResult,
          controller: _controller,
        ),
      ),
    );

    if (saved == true && mounted) {
      _showMessage('Struk berhasil disimpan ke riwayat!');
    }
  }

  Future<void> _runScanFlow(Future<ScanCaptureOutcome?> Function() action) async {
    if (_handling || !mounted) return;
    _handling = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFF05A5A)),
      ),
    );

    try {
      final outcome = await action();
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      await _openDetailWithOutcome(outcome);
    } catch (e) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showMessage('Gagal memproses struk: $e');
    } finally {
      _handling = false;
    }
  }

  void _handleCapture(String _) {
    _runScanFlow(_controller.captureAndScan);
  }

  void _handleSelect(String _) {
    _runScanFlow(_controller.pickFromGalleryAndScan);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.disposeCamera();
    super.dispose();
  }

 @override
  Widget build(BuildContext context) {
    return ScanScreen(
      cameraController: _controller.cameraController,
      onToggleFlash: _controller.toggleFlash,
      onFocusTap: _controller.focusAtNormalizedPoint,
      onImageCaptured: _handleCapture,
      onImageSelected: _handleSelect,
    );
  }
}