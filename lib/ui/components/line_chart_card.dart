import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:byin_app/features/telemetry/telemetry_series_model.dart';

typedef ValueSelector = double? Function(TelemetrySeriesPoint);

class LineChartCard extends StatelessWidget {
  final String title;
  final String subtitle; // misal: "20 data terakhir" atau rentang bulan
  final String unit;
  final List<TelemetrySeriesPoint> data;
  final ValueSelector selector;
  final Color color;

  const LineChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.unit,
    required this.data,
    required this.selector,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final points = _spots();
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE9EEF7)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: points.isEmpty
                  ? const Center(child: Text('Tidak ada data'))
                  : LineChart(_chart(points)),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _spots() {
    return data
        .map((p) {
          final y = selector(p);
          if (y == null) return null;
          final x = p.ts.millisecondsSinceEpoch.toDouble();
          return FlSpot(x, y);
        })
        .whereType<FlSpot>()
        .toList();
  }

  LineChartData _chart(List<FlSpot> spots) {
    double minX = spots.first.x, maxX = spots.first.x;
    double minY = spots.first.y, maxY = spots.first.y;

    for (final s in spots) {
      if (s.x < minX) minX = s.x;
      if (s.x > maxX) maxX = s.x;
      if (s.y < minY) minY = s.y;
      if (s.y > maxY) maxY = s.y;
    }

    // Jika semua X sama (1 titik), beri padding ±12 jam (ms)
    double dx = maxX - minX;
    if (dx <= 0) {
      const padX = 12 * 60 * 60 * 1000.0; // 12 jam dalam ms
      minX -= padX;
      maxX += padX;
      dx = maxX - minX;
    }

    // Jika Y sama, beri padding ±1 unit
    double dy = maxY - minY;
    if (dy <= 0) {
      const padY = 1.0;
      minY -= padY;
      maxY += padY;
      dy = maxY - minY;
    }

    // Interval aman (tidak nol)
    final xInterval = dx / 4;
    final yInterval = dy / 4;

    final dfDay = DateFormat('dd');
    final dfTooltip = DateFormat('dd MMM yyyy\nHH:mm');

    return LineChartData(
      minX: minX,
      maxX: maxX,
      minY: minY.isFinite ? minY : 0,
      maxY: maxY.isFinite ? maxY : 1,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: const Color(0xFFEAEFF7), strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            interval: yInterval, // <-- tidak nol lagi
            getTitlesWidget: (v, _) => Text(
              v.toStringAsFixed(0),
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: xInterval, // <-- tidak nol lagi
            getTitlesWidget: (v, _) {
              final dt = DateTime.fromMillisecondsSinceEpoch(v.toInt());
              return Text(
                dfDay.format(dt),
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          barWidth: 3,
          color: color,
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [color.withOpacity(.25), color.withOpacity(0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          dotData: FlDotData(show: spots.length <= 2), // titik terlihat bila data sedikit
        ),
      ],
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipRoundedRadius: 8,
          getTooltipItems: (touched) {
            return touched.map((s) {
              final dt = DateTime.fromMillisecondsSinceEpoch(s.x.toInt());
              return LineTooltipItem(
                '${dfTooltip.format(dt)}\n${s.y.toStringAsFixed(2)} $unit',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              );
            }).toList();
          },
        ),
      ),
    );
  }
}