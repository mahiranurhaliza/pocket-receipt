import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final String storeName;
  final double totalAmount;
  final String rawText;

  OcrResult({
    required this.storeName,
    required this.totalAmount,
    required this.rawText,
  });
}

class OcrService {
  static Future<OcrResult> scanReceipt(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      final String fullText = recognizedText.text;

      // 1. Ambil baris pertama yang tidak kosong sebagai perkiraan Nama Toko
      final lines = fullText
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      String detectedStore = lines.isNotEmpty ? lines.first : 'Toko Baru';

      // 2. Cari angka nominal terbesar di struk sebagai perkiraan Total Belanja
      double maxAmount = 0;
      final numberRegex = RegExp(r'(\d{1,3}(?:[.,]\d{3})+|\d{4,})');

      for (final line in lines) {
        final matches = numberRegex.allMatches(line);
        for (final match in matches) {
          String cleanNumber =
              match.group(0)!.replaceAll('.', '').replaceAll(',', '');
          double? value = double.tryParse(cleanNumber);
          if (value != null && value > maxAmount && value < 100000000) {
            maxAmount = value;
          }
        }
      }

      return OcrResult(
        storeName: detectedStore,
        totalAmount: maxAmount,
        rawText: fullText,
      );
    } finally {
      await textRecognizer.close();
    }
  }
}