import 'package:byin_app/features/incubators/incubator_provider.dart';
import 'package:byin_app/features/telemetry/telemetry_series_provider.dart';
import 'package:byin_app/ui/components/line_chart_card.dart';
import 'package:byin_app/ui/components/mode_template_card.dart';
import 'package:byin_app/ui/components/month_picker_row.dart';
import 'package:byin_app/ui/widgets/incubator_drowdown.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/telemetry/telemetry_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inited) {
      _inited = true;
      context.read<TelemetryProvider>().init();

      // fetch incubators + choose default (once)
      context.read<IncubatorProvider>().bootstrap();
    }
  }

  String _bulan(int m) {
    const indo = [
      '', 'Januari','Februari','Maret','April','Mei','Juni',
      'Juli','Agustus','September','Oktober','November','Desember'
    ];
    return indo[m];
  }

  @override
  Widget build(BuildContext context) {
    final tel = context.watch<TelemetryProvider>().last;
    final series = context.watch<TelemetrySeriesProvider>();
    final monthLabel = '${series.month.day.toString().padLeft(2,'0')}-${DateTime(series.month.year, series.month.month + 1, 0).day.toString().padLeft(2,'0')} '
    '${_bulan(series.month.month)} ${series.month.year}';

    List<Widget> charts() => [
      LineChartCard(
        title: 'Grafik Suhu (Baby)',
        subtitle: monthLabel,
        unit: '°C',
        data: series.data,
        selector: (p) => p.tempBaby,
        color: const Color(0xFF4D7CFE),
      ),
      const SizedBox(height: 12),
      LineChartCard(
        title: 'Grafik Suhu (DHT)',
        subtitle: monthLabel,
        unit: '°C',
        data: series.data,
        selector: (p) => p.tempDht,
        color: const Color(0xFF26C6DA),
      ),
      const SizedBox(height: 12),
      LineChartCard(
        title: 'Grafik Kelembapan',
        subtitle: monthLabel,
        unit: '%',
        data: series.data,
        selector: (p) => p.rh,
        color: const Color(0xFF00C853),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Monitor inkubator bayi secara real-time',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),

            // incubator widget
            const IncubatorDropdownCard(),
            const SizedBox(height: 16),


            // mode & template widget
            ModeTemplateCard(),
            const SizedBox(height: 22),

            // temperature metrics
            Row(
              children: [
                _metric('Suhu', tel?.tMain, '°C'),
                const SizedBox(width: 10),
                _metric('Kelembapan', tel?.rh, '%'),
              ],
            ),
            const SizedBox(height: 12),

            // GPS card
            _gpsCard(tel),

            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE9EEF7)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                child: MonthPickerRow(
                  month: series.month,
                  onPrev: series.prevMonth,
                  onNext: series.nextMonth,
                  onPick: () => series.pickMonth(context),
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (series.loading) const LinearProgressIndicator(minHeight: 2),
            if (series.error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Gagal ambil data: ${series.error}',
                    style: const TextStyle(color: Colors.red)),
              ),
            ...charts(),
          ],
        ),
      ),
    );
  }

  Widget _metric(String title, double? v, String unit) {
    return Expanded(
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE9EEF7)),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(v == null ? '--' : v.toStringAsFixed(2),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
            Text(unit, style: const TextStyle(fontSize: 12)),
          ]),
        ),
      ),
    );
  }

  Widget _gpsCard(tel) {
    final lat = tel?.lat, lon = tel?.lon, sat = tel?.gpsSat;
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE9EEF7)),
      ),
      child: ListTile(
        leading: const Icon(Icons.place, color: Color(0xFF4D7CFE)),
        title: const Text('Lokasi GPS'),
        subtitle: Text((lat != null && lon != null)
            ? 'Lat: ${lat.toStringAsFixed(6)}\nLon: ${lon.toStringAsFixed(6)} (Sat: ${sat ?? '-'})'
            : 'N/A'),
      ),
    );
  }
}

