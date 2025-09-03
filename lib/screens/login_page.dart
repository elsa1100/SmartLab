import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import 'home_page.dart';
import 'register_page.dart';
import '../widgets/base.dart';

class LoginPage extends StatefulWidget {
  final bool isEnglish;
  final VoidCallback onLanguageChanged;

  LoginPage({required this.isEnglish, required this.onLanguageChanged});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late bool isEnglish;
  bool guest = false;

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
    widget.onLanguageChanged();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      String username = _usernameController.text.trim();
      String password = _passwordController.text;

      if (username.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isEnglish
                  ? 'Please fill in all fields.'
                  : 'يرجى تعبئة جميع الحقول.')),
        );
        return;
      }
      try {
        bool userExists =
            await DatabaseHelper.instance.loginUser(username, password);
        if (userExists) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(isEnglish
                    ? 'Login successful!'
                    : 'تم تسجيل الدخول بنجاح!')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    HomePage(username: username, isGuest: guest)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(isEnglish
                    ? 'Invalid username or password.'
                    : 'اسم المستخدم أو كلمة المرور غير صحيحة.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isEnglish
                  ? 'Login failed. Try again later.'
                  : 'فشل تسجيل الدخول. حاول مرة أخرى لاحقًا.')),
        );
      }
    }
  }

  void _loginAsGuest() {
    setState(() {
      guest = true;
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => HomePage(username: "Guest", isGuest: guest)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isEnglish ? 'Login' : 'تسجيل الدخول',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.language, color: Colors.black),
            onPressed: _toggleLanguage,
          ),
        ],
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment:
                isEnglish ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              SizedBox(height: 30),
              Center(child: Image.asset('assets/logo.png', height: 200)),
              SizedBox(height: 50),
              Directionality(
                textDirection:
                    isEnglish ? TextDirection.ltr : TextDirection.rtl,
                child: TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: isEnglish ? 'Username' : 'اسم المستخدم',
                  ),
                  textAlign: isEnglish ? TextAlign.start : TextAlign.end,
                  validator: (value) => value!.isEmpty
                      ? (isEnglish
                          ? 'Please enter your username'
                          : 'يرجى إدخال اسم المستخدم')
                      : null,
                ),
              ),
              SizedBox(height: 20),
              Directionality(
                textDirection:
                    isEnglish ? TextDirection.ltr : TextDirection.rtl,
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: isEnglish ? 'Password' : 'كلمة المرور',
                  ),
                  textAlign: isEnglish ? TextAlign.start : TextAlign.end,
                  validator: (value) => value!.isEmpty
                      ? (isEnglish
                          ? 'Please enter your password'
                          : 'يرجى إدخال كلمة المرور')
                      : null,
                ),
              ),
              SizedBox(height: 50),
              Center(
                child: RoundedButton(
                  text: isEnglish ? 'Login' : 'دخول',
                  onPressed: _handleLogin,
                  padding: EdgeInsets.symmetric(horizontal: 70, vertical: 12),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: isEnglish
                      ? [
                          Text("Don't have an account? "),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      RegisterPage(isEnglish: isEnglish),
                                ),
                              );
                            },
                            child: Text('Register'),
                          )
                        ]
                      : [
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      RegisterPage(isEnglish: isEnglish),
                                ),
                              );
                            },
                            child: Text('إنشاء حساب'),
                          ),
                          Text("ليس لديك حساب؟ "),
                        ],
                ),
              ),
              SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: _loginAsGuest,
                  child: Text(
                    isEnglish ? "Continue as Guest" : "الدخول كضيف",
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
