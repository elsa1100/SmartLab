import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../widgets/bottom_nav_bar.dart';
import '../main.dart' as main_view;
import '../widgets/base.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  final bool isGuest;

  ProfilePage({required this.username, this.isGuest = false});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool isEnglish = true;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isEnglish = prefs.getBool('isEnglish') ?? true;
    });
  }

  Future<void> _saveLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isEnglish', isEnglish);
  }

  void _toggleLanguage() {
    setState(() {
      isEnglish = !isEnglish;
    });
    _saveLanguagePreference();
  }

  void _fetchUserInfo() async {
    Map<String, dynamic>? user = await _getUserDetails(widget.username);
    if (user != null) {
      setState(() {
        _nameController.text = user['name'];
        _ageController.text = user['age'].toString();
        _emailController.text = user['email'];
        _passwordController.text = user['password'];
      });
    }
  }

  Future<Map<String, dynamic>?> _getUserDetails(String username) async {
    final db = await DatabaseHelper.instance.database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return result.isNotEmpty ? result.first : null;
  }

  void _updateUserInfo() async {
    if (widget.isGuest) return;

    if (_nameController.text.isEmpty ||
        _ageController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnackBar(isEnglish ? "Please fill all fields" : "يرجى ملء جميع الحقول");
      return;
    }

    if (!_isValidEmail(_emailController.text)) {
      _showSnackBar(isEnglish ? "Please enter a valid email" : "يرجى إدخال بريد إلكتروني صالح");
      return;
    }

    // Check if the email already exists
    bool emailInUse = await _isEmailInUse(_emailController.text, widget.username);
    if (emailInUse) {
      _showSnackBar(isEnglish
          ? "Email is already in use by another user"
          : "البريد الإلكتروني مستخدم من قبل مستخدم آخر");
      return;
    }

    int result = await _updateUserDetails(
      widget.username,
      _nameController.text,
      _emailController.text,
      _passwordController.text,
      int.tryParse(_ageController.text) ?? 0,
    );

    _showSnackBar(
      result > 0
          ? (isEnglish ? "Profile Updated!" : "تم تحديث الملف الشخصي!")
          : (isEnglish ? "Update Failed" : "فشل التحديث"),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isValidEmail(String email) {
    String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    return RegExp(pattern).hasMatch(email);
  }

  Future<bool> _isEmailInUse(String email, String currentUsername) async {
    final db = await DatabaseHelper.instance.database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'email = ? AND username != ?',
      whereArgs: [email, currentUsername],
    );
    return result.isNotEmpty;
  }

  Future<int> _updateUserDetails(
      String username, String newName, String newEmail, String newPassword, int newAge) async {
    final db = await DatabaseHelper.instance.database;
    try {
      return await db.update(
        'users',
        {
          'name': newName,
          'email': newEmail,
          'password': newPassword,
          'age': newAge,
        },
        where: 'username = ?',
        whereArgs: [username],
      );
    } catch (e) {
      print("Error updating user info: $e");
      return 0;
    }
  }

  void _signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => main_view.MyApp(isEnglish: isEnglish)),
          (route) => false,
    );
  }

  void _navigateToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => main_view.MyApp(isEnglish: isEnglish)),
          (route) => false,
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumeric = false, bool isPassword = false, bool isEditable = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        obscureText: isPassword,
        enabled: isEditable,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3EDF7),
      appBar: AppBar(
        title: Text(isEnglish ? "P r o f i l e" : "الملف الشخصي"
          , style: GoogleFonts.handlee(fontSize: 24, fontWeight: FontWeight.w600),),
        centerTitle: true,
        backgroundColor: Color(0xFFC8BDD6),
        actions: [
          IconButton(
            icon: Icon(Icons.language, color: Colors.black),
            onPressed: _toggleLanguage,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        username: widget.username,
        isEnglish: isEnglish,
        isGuest: widget.isGuest,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20),
              Directionality(
                textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
                child: Column(
                  children: [
                    _buildTextField(
                      isEnglish ? "Name" : "الاسم",
                      _nameController,
                      isEditable: !widget.isGuest,
                    ),
                    _buildTextField(
                      isEnglish ? "Age" : "العمر",
                      _ageController,
                      isNumeric: true,
                      isEditable: !widget.isGuest,
                    ),
                    _buildTextField(
                      isEnglish ? "Email" : "البريد الإلكتروني",
                      _emailController,
                      isEditable: !widget.isGuest,
                    ),
                    _buildTextField(
                      isEnglish ? "Password" : "كلمة المرور",
                      _passwordController,
                      isPassword: true,
                      isEditable: !widget.isGuest,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: AbsorbPointer(
                  absorbing: widget.isGuest, // Prevents taps if guest
                  child: RoundedButton(
                    text: isEnglish ? "Save Changes" : "حفظ التغييرات",
                    onPressed: _updateUserInfo,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: RoundedButton(
                  text: widget.isGuest
                      ? (isEnglish ? "Login/Register" : "تسجيل الدخول/التسجيل")
                      : (isEnglish ? "Sign Out" : "تسجيل الخروج"),
                  onPressed: widget.isGuest ? _navigateToLogin : _signOut,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
