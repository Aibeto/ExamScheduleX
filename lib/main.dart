import 'package:examschedulex/models/ui_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LiquidGlassWidgets.initialize();

  const uiConfig = UiConfig();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(LiquidGlassWidgets.wrap(
    child: ExamScheduleApp(fontFamily: uiConfig.fontFamily),
    adaptiveQuality: true,
  ));
}

class ExamScheduleApp extends StatelessWidget {
  final String fontFamily;

  const ExamScheduleApp({super.key, required this.fontFamily});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exam Schedule X',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: fontFamily,
        textTheme: TextTheme(
          bodyMedium:
              TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold),
          bodyLarge:
              TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold),
          bodySmall:
              TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold),
          titleLarge:
              TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold),
          titleMedium:
              TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold),
          titleSmall:
              TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold),
          headlineSmall:
              TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold),
          headlineMedium:
              TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold),
          headlineLarge:
              TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold),
        ),
      ),
      home: const ExamScheduleHomePage(),
    );
  }
}
