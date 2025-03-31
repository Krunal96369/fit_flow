import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Service for handling barcode scanning functionality
class BarcodeScannerService {
  /// Scan a barcode and return the scanned code
  /// Returns null if scanning is canceled or fails
  Future<String?> scanBarcode() async {
    try {
      // Use a dedicated screen for scanning
      final BuildContext? context =
          WidgetsBinding.instance.focusManager.primaryFocus?.context;
      if (context == null) {
        debugPrint('Error: No valid context found for navigation');
        return null;
      }

      final String? result = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
      );

      return result;
    } catch (e) {
      debugPrint('Error scanning barcode: $e');
      return null;
    }
  }

  /// Scan a product barcode and return the code
  /// This is a convenience method specifically for product barcodes
  Future<String?> scanProductBarcode() async {
    return scanBarcode();
  }
}

/// Screen for barcode scanning
class BarcodeScannerScreen extends StatefulWidget {
  /// Constructor
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isScanning = true;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body:
          _isScanning
              ? Stack(
                children: [
                  MobileScanner(
                    controller: controller,
                    onDetect: (capture) {
                      if (!_isScanning) return;

                      final barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty) {
                        final String? code = barcodes.first.rawValue;
                        setState(() {
                          _isScanning = false;
                        });
                        Navigator.of(context).pop(code);
                      }
                    },
                  ),
                  // Scan overlay with cutout
                  CustomPaint(
                    painter: ScannerOverlayPainter(),
                    child: const SizedBox.expand(),
                  ),
                ],
              )
              : const Center(child: CircularProgressIndicator()),
    );
  }
}

/// Custom painter for scanner overlay
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaSize = size.width * 0.7;
    final Rect scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    final backgroundPath =
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final scanArea = Path()..addRect(scanRect);

    final Path backgroundWithHole = Path.combine(
      PathOperation.difference,
      backgroundPath,
      scanArea,
    );

    canvas.drawPath(backgroundWithHole, Paint()..color = Colors.black54);

    canvas.drawRect(
      scanRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Provider for the barcode scanner service
final barcodeScannerServiceProvider = Provider<BarcodeScannerService>((ref) {
  return BarcodeScannerService();
});
