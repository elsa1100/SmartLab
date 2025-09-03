import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database/database_helper.dart';
import 'screens/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isEnglish = prefs.getBool('isEnglish') ?? true;

  runApp(MyApp(isEnglish: isEnglish));
}

class MyApp extends StatefulWidget {
  final bool isEnglish;
  MyApp({required this.isEnglish});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool isEnglish;

  @override
  void initState() {
    super.initState();
    isEnglish = widget.isEnglish;
  }

  void _toggleLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isEnglish = !isEnglish;
      prefs.setBool('isEnglish', isEnglish);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Lab',
      theme: ThemeData(
        fontFamily: 'Roboto',
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Color(0xFFF8F1FF),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Color(0xFF725E8C)),
        ),
      ),
      home: LoginPage(
        isEnglish: isEnglish,
        onLanguageChanged: _toggleLanguage,
      ),
    );
  }
}
