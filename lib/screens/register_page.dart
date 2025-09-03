import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../widgets/base.dart';
import 'login_page.dart';

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
          contentPadding:
              EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
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

class RegisterPage extends StatefulWidget {
  final bool isEnglish;
  RegisterPage({required this.isEnglish});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late bool isEnglish;

  @override
  void initState() {
    super.initState();
    isEnglish = widget.isEnglish;
  }

  //Registration function
  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      String name = _nameController.text.trim();
      String email = _emailController.text.trim();
      String username = _usernameController.text.trim();
      String password = _passwordController.text;
      int age = int.tryParse(_ageController.text.trim()) ?? 0;

      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

      if (!emailRegex.hasMatch(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isEnglish
                  ? 'Enter a valid email address!'
                  : 'أدخل بريدًا إلكترونيًا صالحًا!')),
        );
        return;
      }

      if (password.length < 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isEnglish
                  ? 'Password must be at least 8 characters!'
                  : 'يجب أن تكون كلمة المرور 8 أحرف على الأقل!')),
        );
        return;
      }

      if (age <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  isEnglish ? 'Enter a valid age!' : 'أدخل عمرًا صالحًا!')),
        );
        return;
      }

      // Check if username already exists
      bool usernameExists =
          await DatabaseHelper.instance.checkUsernameExists(username);
      if (usernameExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isEnglish
                  ? 'Username already exists. Please choose another.'
                  : 'اسم المستخدم موجود بالفعل. يرجى اختيار اسم آخر.')),
        );
        return;
      }

      try {
        await DatabaseHelper.instance
            .registerUser(name, username, email, password, age);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(isEnglish ? 'User Registered!' : 'تم تسجيل المستخدم!')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isEnglish
                  ? 'Registration failed. Try again.'
                  : 'فشل التسجيل. حاول مرة أخرى.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEnglish ? 'Register' : 'تسجيل'),
          centerTitle: true,
          backgroundColor: Color(0xFFC8BDD6),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                        labelText: isEnglish ? 'Full Name' : 'الاسم الكامل'),
                    textAlign: isEnglish ? TextAlign.start : TextAlign.end,
                    validator: (value) => value!.isEmpty
                        ? (isEnglish
                            ? 'Please enter your full name'
                            : 'يرجى إدخال الاسم الكامل')
                        : null,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                        labelText: isEnglish ? 'Email' : 'البريد الإلكتروني'),
                    textAlign: isEnglish ? TextAlign.start : TextAlign.end,
                    validator: (value) => value!.isEmpty
                        ? (isEnglish
                            ? 'Please enter your email'
                            : 'يرجى إدخال البريد الإلكتروني')
                        : null,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                        labelText: isEnglish ? 'Username' : 'اسم المستخدم'),
                    textAlign: isEnglish ? TextAlign.start : TextAlign.end,
                    validator: (value) => value!.isEmpty
                        ? (isEnglish
                            ? 'Please enter your username'
                            : 'يرجى إدخال اسم المستخدم')
                        : null,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                        labelText: isEnglish ? 'Password' : 'كلمة المرور'),
                    obscureText: true,
                    textAlign: isEnglish ? TextAlign.start : TextAlign.end,
                    validator: (value) => value!.isEmpty
                        ? (isEnglish
                            ? 'Please enter your password'
                            : 'يرجى إدخال كلمة المرور')
                        : null,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _ageController,
                    decoration:
                        InputDecoration(labelText: isEnglish ? 'Age' : 'العمر'),
                    keyboardType: TextInputType.number,
                    textAlign: isEnglish ? TextAlign.start : TextAlign.end,
                    validator: (value) => value!.isEmpty
                        ? (isEnglish
                            ? 'Please enter your age'
                            : 'يرجى إدخال عمرك')
                        : null,
                  ),
                  SizedBox(height: 30),
                  RoundedButton(
                      text: isEnglish ? 'Register' : 'تسجيل',
                      onPressed: _handleRegister),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
