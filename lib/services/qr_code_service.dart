import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

class QrCodeService {
  /// Generate QR code image from serial number
  /// Returns the image as Uint8List (PNG format)
  Future<Uint8List?> generateQrCodeImage(
    String serialNumber, {
    double size = 300,
    Color foregroundColor = Colors.black,
    Color backgroundColor = Colors.white,
  }) async {
    try {
      // Create a QR code painter
      final qrValidationResult = QrValidator.validate(
        data: serialNumber,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
      );

      if (qrValidationResult.status == QrValidationStatus.error) {
        throw Exception('Invalid QR code data: ${qrValidationResult.error}');
      }

      // Create the QR code painter
      final painter = QrPainter(
        data: serialNumber,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
        eyeStyle: QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: foregroundColor,
        ),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: foregroundColor,
        ),
        gapless: true,
      );

      // Create a picture recorder to capture the painting
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);

      // Paint the QR code
      painter.paint(canvas, Size(size, size));

      // Convert to image
      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());

      // Convert to PNG bytes
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error generating QR code image: $e');
      return null;
    }
  }

  /// Download QR code as PNG file (web platform)
  void downloadQrCodeWeb(Uint8List imageBytes, String filename) {
    try {
      // Create a blob from the image bytes
      final blob = html.Blob([
        imageBytes,
      ], 'image/png'); // ignore: deprecated_member_use

      // Create a download link
      final url = html.Url.createObjectUrlFromBlob(
        blob,
      ); // ignore: deprecated_member_use
      final anchor =
          html.AnchorElement(href: url) // ignore: deprecated_member_use
            ..setAttribute('download', '$filename.png');
      anchor.click();

      // Clean up
      html.Url.revokeObjectUrl(url); // ignore: deprecated_member_use
    } catch (e) {
      debugPrint('Error downloading QR code: $e');
    }
  }

  /// Download QR code as PNG file (web only for now)
  Future<void> downloadQrCode(Uint8List imageBytes, String filename) async {
    try {
      // For web platform only
      downloadQrCodeWeb(imageBytes, filename);
    } catch (e) {
      debugPrint('Error downloading QR code: $e');
      rethrow;
    }
  }

  /// Generate QR code widget for display
  Widget buildQrCodeWidget(
    String serialNumber, {
    double size = 200,
    Color foregroundColor = Colors.black,
    Color backgroundColor = Colors.white,
    bool showData = true,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: QrImageView(
            data: serialNumber,
            version: QrVersions.auto,
            size: size,
            backgroundColor: backgroundColor,
            eyeStyle: QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: foregroundColor,
            ),
            dataModuleStyle: QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: foregroundColor,
            ),
            errorCorrectionLevel: QrErrorCorrectLevel.H,
            gapless: true,
          ),
        ),
        if (showData) ...[
          const SizedBox(height: 8),
          Text(
            serialNumber,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }
}
