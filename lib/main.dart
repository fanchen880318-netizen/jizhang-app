import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/bill_provider.dart';
import 'pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JizhangApp());
}

class JizhangApp extends StatelessWidget {
  const JizhangApp({super.key});

  static const primary = Color(0xFF5B2444);
  static const bg = Color(0xFFE1E0D7);
  static const text = Color(0xFF211E21);
  static const grey = Color(0xFF7B7774);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BillProvider(),
      child: MaterialApp(
        title: '记账',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: primary,
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: bg,
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
          dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ),
        localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        supportedLocales: const [Locale('zh')],
        locale: const Locale('zh'),
        home: const HomePage(),
      ),
    );
  }
}
