import 'package:byin_app/features/settings/sensor_params_provider.dart';
import 'package:byin_app/features/telemetry/telemetry_series_provider.dart';
import 'package:byin_app/features/templates/template_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:byin_app/mqtt/mqtt_service.dart';
import 'package:byin_app/services/api_client.dart';
import 'package:byin_app/ui/home_shell.dart';

import 'features/incubators/incubator_provider.dart';
import 'features/telemetry/telemetry_provider.dart';
import 'features/control/control_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ANDROID EMULATOR: 10.0.2.2 == host machine (localhost)
  final api  = ApiClient(baseUrl: 'http://10.0.2.2:3000/api/v1');
  final mqtt = MqttService(
    broker: 'd847cd151fbe4985a1bc32cbd787651d.s1.eu.hivemq.cloud',
    username: 'esp32.subscriber.publisher',
    password: 'DxESP32Rext',
  );

  runApp(MyApp(api: api, mqtt: mqtt));
}

class MyApp extends StatelessWidget {
  final ApiClient api;
  final MqttService mqtt;
  const MyApp({super.key, required this.api, required this.mqtt});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ⬇️ Strongly type
        Provider<ApiClient>.value(value: api),
        Provider<MqttService>.value(value: mqtt),

        // ⬇️ Build ChangeNotifiers from context to avoid null capture
        ChangeNotifierProvider<IncubatorProvider>(
          create: (ctx) => IncubatorProvider(
            ctx.read<ApiClient>(),
            ctx.read<MqttService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => TelemetrySeriesProvider(api, ctx.read<IncubatorProvider>()),
        ),
        ChangeNotifierProvider<TelemetryProvider>(
          create: (ctx) => TelemetryProvider(
            ctx.read<ApiClient>(),
            ctx.read<IncubatorProvider>(),
            pollInterval: const Duration(seconds: 5),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => TemplateProvider(
            ctx.read<ApiClient>(), 
            ctx.read<IncubatorProvider>()
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SensorParamsProvider(api, mqtt),
        ),
        ChangeNotifierProxyProvider<TelemetryProvider, ControlProvider>(
          create: (ctx) =>
              ControlProvider(ctx.read<ApiClient>(), ctx.read<IncubatorProvider>(), ctx.read<TelemetryProvider>()),
          update: (ctx, tel, _) => ControlProvider(ctx.read<ApiClient>(), ctx.read<IncubatorProvider>(), tel),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'BYIN',
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF4D7CFE),
          useMaterial3: true,
        ),
        home: const HomeShell(),
      ),
    );
  }
}
