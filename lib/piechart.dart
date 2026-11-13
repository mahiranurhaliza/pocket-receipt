import 'dart:math' as math;
import 'package:flutter/material.dart';

// 1. Model data untuk tiap kategori chart
class PieCategoryData {
  final String label;
  final double value;
  final Color color;

  PieCategoryData({
    required this.label,
    required this.value,
    required this.color,
  });
}

// 2. CustomPainter untuk menggambar Donut Chart secara otomatis
class DonutChartPainter extends CustomPainter {
  final List<PieCategoryData> categories;
  final double holeRadiusRatio; // Rasio lubang tengah (0.0 - 1.0)

  DonutChartPainter({
    required this.categories,
    this.holeRadiusRatio = 0.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Hitung total dari seluruh nilai kategori
    final double totalValue = categories.fold(
      0.0,
      (sum, item) => sum + item.value,
    );

    if (totalValue <= 0) return;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double outerRadius = math.min(size.width, size.height) / 2;
    final double innerRadius = outerRadius * holeRadiusRatio;
    final double strokeWidth = outerRadius - innerRadius;
    final double drawRadius = innerRadius + (strokeWidth / 2);

    // Mulai dari atas (270 derajat atau -pi/2)
    double startAngle = -math.pi / 2;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Drawing setiap potong (arc) secara proporsional
    for (final category in categories) {
      final double sweepAngle = (category.value / totalValue) * 2 * math.pi;

      paint.color = category.color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: drawRadius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.categories != categories ||
        oldDelegate.holeRadiusRatio != holeRadiusRatio;
  }
}

// 3. Widget Wrapper yang Responsif terhadap Lebar & Panjang Layar
class ResponsivePieChart extends StatelessWidget {
  final List<PieCategoryData> categories;
  final double chartSize; // Ukuran diameter chart

  const ResponsivePieChart({
    super.key,
    required this.categories,
    this.chartSize = 200,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Menentukan ukuran diameter chart secara dinamis sesuai layar
        final double availableSize = math.min(
          constraints.maxWidth,
          constraints.maxHeight == double.infinity
              ? constraints.maxWidth
              : constraints.maxHeight,
        );
        //final double chartSize = availableSize * chartSize;

        return Center(
          child: SizedBox(
            width: chartSize,
            height: chartSize,
            child: CustomPaint(
              painter: DonutChartPainter(
                categories: categories,
                holeRadiusRatio: 0.5, // Lebar lubang putih tengah
              ),
            ),
          ),
        );
      },
    );
  }
}