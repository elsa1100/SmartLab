import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../main.dart' as main_view;
import '../widgets/base.dart';
import '../services/email_service.dart'; // make sure to import your EmailService

class ResultsPage extends StatefulWidget {
  final String username;
  final String analysisText;
  final bool isGuest;
  final bool isAlreadySaved;

  ResultsPage({
    required this.username,
    required this.analysisText,
    required this.isGuest,
    this.isAlreadySaved = false,
  });

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  String name = "";
  String userEmail = "";
  bool isEnglish = true;
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _loadLanguagePreference();
    _fetchUserEmail();
  }

  void _fetchUserName() async {
    String fetchedName =
    await DatabaseHelper.instance.getUserName(widget.username);
    setState(() {
      name = fetchedName;
    });
  }

  void _fetchUserEmail() async {
    try {
      String? fetchedEmail = await DatabaseHelper.instance.getUserEmail(widget.username);
      if (fetchedEmail != null) {
        setState(() {
          userEmail = fetchedEmail;
        });
      } else {
        print("No email found for username: ${widget.username}");
      }
    } catch (e) {
      print("Error while fetching user email: $e");
    }
  }


  Future<void> _loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isEnglish = prefs.getBool('isEnglish') ?? true;
    });
  }

  void _toggleLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isEnglish = !isEnglish;
      prefs.setBool('isEnglish', isEnglish);
    });
  }

  void _saveAnalysis() async {
    if (isSaved || widget.isGuest) return;

    final plainText = widget.analysisText.trim();

    int result = await DatabaseHelper.instance.insertAnalysis(
      widget.username,
      "Medical Test",
      plainText,
    );

    if (result > 0) {
      setState(() {
        isSaved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEnglish
                ? "Analysis saved successfully!"
                : "تم حفظ التحليل بنجاح",
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEnglish ? "Failed to save analysis." : "فشل في حفظ التحليل",
          ),
        ),
      );
    }
  }

  void _signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => main_view.MyApp(isEnglish: isEnglish),
      ),
          (route) => false,
    );
  }

  void _sendEmail() async {
    if (userEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEnglish
              ? "Email not found. Please check your account."
              : "البريد الإلكتروني غير موجود. الرجاء التحقق من حسابك."),
        ),
      );
      return;
    }

    final success = await EmailService.sendAnalysisToEmail(
      context: context,
      userName: name,
      userEmail: userEmail,
      analysisResult: widget.analysisText,
      isEnglish: isEnglish,
    );

    if (!success) {

    }
  }

  void _navigateToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => main_view.MyApp(isEnglish: isEnglish),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3EDF7),
      appBar: AppBar(
        title: Text(
          isEnglish ? "Test Analysis" : "تحليل الاختبار",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFFC8BDD6),
        actions: [
          IconButton(
            icon: Icon(Icons.language),
            onPressed: _toggleLanguage,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment:
          isEnglish ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Directionality(
              textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
              child: Text(
                isEnglish ? "Medical Report Summary" : "ملخص التقرير الطبي",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 5)
                      ],
                    ),
                    child: SelectableText(
                      widget.analysisText,
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                      textAlign:
                      isEnglish ? TextAlign.left : TextAlign.right,
                    ),
                  ),
                  SizedBox(height: 20),
                  if (widget.isGuest)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: Text(
                            isEnglish
                                ? "Login to save this analysis."
                                : "سجّل الدخول لحفظ هذا التحليل",
                            style: TextStyle(color: Colors.red),
                            textAlign:
                            isEnglish ? TextAlign.left : TextAlign.right,
                          ),
                        ),
                        const SizedBox(height: 12),
                        RoundedButton(
                          text: widget.isGuest
                              ? (isEnglish ? 'Login Now' : 'سجّل الدخول الآن')
                              : (isEnglish ? 'Logout' : 'تسجيل الخروج'),
                          onPressed:
                          widget.isGuest ? _navigateToLogin : _signOut,
                        ),
                      ],
                    ),
                  SizedBox(height: 8),
                  if (!widget.isAlreadySaved && !widget.isGuest)
                    ElevatedButton.icon(
                      onPressed: isSaved ? _sendEmail : _saveAnalysis,
                      icon: Icon(
                        isSaved ? Icons.email : Icons.save,
                      ),
                      label: Text(
                        isSaved
                            ? (isEnglish
                            ? "Send to Email"
                            : "إرسال إلى البريد")
                            : (isEnglish
                            ? "Save Analysis"
                            : "حفظ التحليل"),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFC8BDD6),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
