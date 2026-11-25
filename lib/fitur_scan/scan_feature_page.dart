import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../UI/scan.dart';
import '../UI/scanDetailed.dart';
import 'scan_controller.dart';

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
    _controller.initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _controller.disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _controller.initializeCamera();
    }
  }

  Future<void> _handleCapture(String _) async {
    if (_handling) return;
    _handling = true;
    try {
      final outcome = await _controller.captureAndScan();
      if (!mounted || outcome == null) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ScanDetailedScreen(receiptBytes: outcome.imageBytes),
        ),
      );
    } finally {
      _handling = false;
    }
  }

  Future<void> _handleSelect(String _) async {
    if (_handling) return;
    _handling = true;
    try {
      final outcome = await _controller.pickFromGalleryAndScan();
      if (!mounted || outcome == null) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ScanDetailedScreen(receiptBytes: outcome.imageBytes),
        ),
      );
    } finally {
      _handling = false;
    }
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
      onImageCaptured: _handleCapture,
      onImageSelected: _handleSelect,
    );
  }
}