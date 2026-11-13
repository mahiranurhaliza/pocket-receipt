import 'package:flutter/material.dart';

class BarChartDataData {
  final String label;
  final double value;
  final bool isThisMonth;
  final bool isSelected;

  const BarChartDataData({
    required this.label,
    required this.value,
    required this.isThisMonth,
    this.isSelected = false,
  });
}

class ResponsiveBarChart extends StatelessWidget {
  final List<BarChartDataData> items;
  final String title;
  final String totalExpense;
  final double maxValue;

  const ResponsiveBarChart({
    super.key,
    required this.items,
    this.title = 'This week expense',
    this.totalExpense = 'Rp231.000',
    this.maxValue = 440000,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Teks
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1E1E1E),
              fontSize: 15,
              fontFamily: 'Bricolage Grotesque',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            totalExpense,
            style: const TextStyle(
              color: Color(0xFF1E1E1E),
              fontSize: 20,
              fontFamily: 'Bricolage Grotesque',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Area Background Grafik dengan CustomPainter (Grid + Bars)
          Container(
            height: 190,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0x33FFF185),
              borderRadius: BorderRadius.circular(10),
            ),
            child: CustomPaint(
              painter: _BarChartPainter(
                items: items,
                maxValue: maxValue,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Legenda Keterangan
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xB2D2BFEE),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Past month',
                style: TextStyle(
                  color: Color(0xFF1E1E1E),
                  fontSize: 13,
                  fontFamily: 'Bricolage Grotesque',
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 24),
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFB870), Color(0xFFD2BFEE)],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'This month',
                style: TextStyle(
                  color: Color(0xFF1E1E1E),
                  fontSize: 13,
                  fontFamily: 'Bricolage Grotesque',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<BarChartDataData> items;
  final double maxValue;

  _BarChartPainter({
    required this.items,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double topPadding = 24.0;
    const double bottomPadding = 40.0;
    const double rightYAxisWidth = 50.0; // Area khusus untuk Sumbu Y di kanan

    final double chartHeight = size.height - topPadding - bottomPadding;
    final double chartWidth = size.width - rightYAxisWidth;

    // --- 1. MENGGAMBAR DASHED GRID LINES & LABEL SUMBU Y DI KANAN ---
    final List<double> ySteps = [440000, 285000, 135000, 0];
    final List<String> yLabels = ['440k', '285k', '135k', '0'];

    final Paint dashPaint = Paint()
      ..color = const Color(0x7F1E1E1E)
      ..strokeWidth = 1.0;

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < ySteps.length; i++) {
      double ratio = ySteps[i] / maxValue;
      double y = topPadding + (chartHeight * (1.0 - ratio));

      // Gambar Garis Putus-putus
      _drawDashedLine(canvas, Offset(10, y), Offset(chartWidth - 5, y), dashPaint);

      // Gambar Label Sumbu Y di Sebelah Kanan
      textPainter.text = TextSpan(
        text: yLabels[i],
        style: const TextStyle(
          color: Color(0xFF1E1E1E),
          fontSize: 15,
          fontFamily: 'Bricolage Grotesque',
          fontWeight: FontWeight.w400,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(chartWidth + 8, y - (textPainter.height / 2)),
      );
    }

    // --- 2. MENGGAMBAR BATANG GRAFIK & LABEL SUMBU X ---
    if (items.isEmpty) return;

    double barAreaWidth = chartWidth / items.length;
    double barWidth = (barAreaWidth * 0.55).clamp(16.0, 32.0);

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      double centerX = (i * barAreaWidth) + (barAreaWidth / 2);

      // Hitung tinggi batang secara presisi
      double barRatio = (item.value / maxValue).clamp(0.0, 1.0);
      double currentBarHeight = chartHeight * barRatio;
      double barTop = topPadding + (chartHeight - currentBarHeight);
      double barBottom = topPadding + chartHeight;

      Rect barRect = Rect.fromLTRB(
        centerX - (barWidth / 2),
        barTop,
        centerX + (barWidth / 2),
        barBottom,
      );

      // Paint untuk warna/gradien batang
      Paint barPaint = Paint();
      if (item.isThisMonth) {
        barPaint.shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFB870), Color(0xFFD2BFEE)],
        ).createShader(barRect);
      } else {
        barPaint.color = const Color(0xB2D2BFEE);
      }

      // Draw Bar dengan border radius tumpul di bagian atas
      RRect roundedBar = RRect.fromRectAndCorners(
        barRect,
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(roundedBar, barPaint);

      // --- 3. MENGGAMBAR LABEL SUMBU X & GARIS UNDERLINE (JIKA SELECTED) ---
      double labelY = barBottom + 8;

      textPainter.text = TextSpan(
        text: item.label,
        style: const TextStyle(
          color: Color(0xFF1E1E1E),
          fontSize: 14,
          fontFamily: 'Bricolage Grotesque',
          fontWeight: FontWeight.w400,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(centerX - (textPainter.width / 2), labelY),
      );

      // Garis hitam tebal di bawah label jika selected (seperti rentang '19-25' pada referensi)
      if (item.isSelected) {
        Paint underlinePaint = Paint()
          ..color = const Color(0xFF1E1E1E)
          ..strokeWidth = 1.5;

        canvas.drawLine(
          Offset(centerX - 18, labelY + textPainter.height + 2),
          Offset(centerX + 18, labelY + textPainter.height + 2),
          underlinePaint,
        );
      }
    }
  }

  // Fungsi helper untuk menarik garis putus-putus
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    double dashWidth = 3.0;
    double dashSpace = 3.0;
    double distance = (end.dx - start.dx);
    double startX = start.dx;

    while (startX < end.dx) {
      canvas.drawLine(
        Offset(startX, start.dy),
        Offset((startX + dashWidth).clamp(start.dx, end.dx), start.dy),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.items != items || oldDelegate.maxValue != maxValue;
  }
}