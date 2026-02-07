// lib/features/members/screens/qr_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/utils/theme_utils.dart';
import 'package:cleanslate/core/services/deep_link_service.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late MobileScannerController cameraController;
  bool hasScanned = false;
  bool isTorchOn = false;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? rawValue = barcode.rawValue;
      if (rawValue != null && !hasScanned) {
        setState(() {
          hasScanned = true;
        });

        // Parse the code (supports both raw codes and deep links like cleanslate://join/CODE)
        final code = DeepLinkService.parseJoinCode(rawValue);
        
        if (code != null) {
          Navigator.pop(context, code);
        } else {
          // Invalid code format
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Invalid QR code. Please scan a valid household invite code.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() {
            hasScanned = false;
          });
        }
      }
    }
  }

  void _toggleTorch() async {
    await cameraController.toggleTorch();
    setState(() {
      isTorchOn = !isTorchOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scan QR Code',
          style: TextStyle(
            color: AppColors.textLight,
            fontFamily: 'Switzer',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        iconTheme: IconThemeData(color: AppColors.textLight),
        actions: [
          IconButton(
            icon: Icon(
              isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: isTorchOn ? Colors.yellow : Colors.white,
            ),
            onPressed: _toggleTorch,
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch, color: Colors.white),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: cameraController, onDetect: _handleBarcode),
          // Custom overlay
          CustomPaint(
            painter: ScannerOverlayPainter(
              borderColor: AppColors.primary,
              borderWidth: 4.0,
              overlayColor: Colors.black.withValues(alpha: 0.5),
              borderRadius: 12,
              borderLength: 40,
              cutOutSize: 300,
            ),
            child: Container(),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Point camera at QR code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'VarelaRound',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the scanner overlay
class ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  ScannerOverlayPainter({
    required this.borderColor,
    required this.borderWidth,
    required this.overlayColor,
    required this.borderRadius,
    required this.borderLength,
    required this.cutOutSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scanArea = cutOutSize;
    final double left = (size.width - scanArea) / 2;
    final double top = (size.height - scanArea) / 2;
    final double right = left + scanArea;
    final double bottom = top + scanArea;

    // Draw overlay
    final Paint overlayPaint =
        Paint()
          ..color = overlayColor
          ..style = PaintingStyle.fill;

    final Path overlayPath =
        Path()
          ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTRB(left, top, right, bottom),
              Radius.circular(borderRadius),
            ),
          )
          ..fillType = PathFillType.evenOdd;

    canvas.drawPath(overlayPath, overlayPaint);

    // Draw border
    final Paint borderPaint =
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;

    final Path borderPath = Path();

    // Top left corner
    borderPath
      ..moveTo(left + borderRadius, top)
      ..lineTo(left + borderLength, top)
      ..moveTo(left, top + borderRadius)
      ..lineTo(left, top + borderLength)
      ..moveTo(left + borderRadius, top)
      ..arcToPoint(
        Offset(left, top + borderRadius),
        radius: Radius.circular(borderRadius),
      );

    // Top right corner
    borderPath
      ..moveTo(right - borderLength, top)
      ..lineTo(right - borderRadius, top)
      ..moveTo(right, top + borderRadius)
      ..lineTo(right, top + borderLength)
      ..moveTo(right - borderRadius, top)
      ..arcToPoint(
        Offset(right, top + borderRadius),
        radius: Radius.circular(borderRadius),
        clockwise: true,
      );

    // Bottom right corner
    borderPath
      ..moveTo(right, bottom - borderLength)
      ..lineTo(right, bottom - borderRadius)
      ..moveTo(right - borderRadius, bottom)
      ..lineTo(right - borderLength, bottom)
      ..moveTo(right, bottom - borderRadius)
      ..arcToPoint(
        Offset(right - borderRadius, bottom),
        radius: Radius.circular(borderRadius),
        clockwise: true,
      );

    // Bottom left corner
    borderPath
      ..moveTo(left + borderLength, bottom)
      ..lineTo(left + borderRadius, bottom)
      ..moveTo(left, bottom - borderLength)
      ..lineTo(left, bottom - borderRadius)
      ..moveTo(left + borderRadius, bottom)
      ..arcToPoint(
        Offset(left, bottom - borderRadius),
        radius: Radius.circular(borderRadius),
        clockwise: true,
      );

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(ScannerOverlayPainter oldDelegate) => false;
}
