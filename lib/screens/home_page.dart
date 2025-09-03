import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/top_app_bar.dart';
import '../services/email_service.dart'; // Updated usage
import 'results_page.dart';

class HomePage extends StatefulWidget {
  final String username;
  final bool isGuest;

  const HomePage({super.key, required this.username, required this.isGuest});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String name = "";
  bool isEnglish = true;
  List<Map<String, dynamic>> _userAnalyses = [];
  bool _isSelectionMode = false;
  Set<int> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _loadLanguagePreference();
    await _fetchUserName();
    if (!widget.isGuest) await _fetchUserAnalyses();
  }

  Future<void> _loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isEnglish = prefs.getBool('isEnglish') ?? true;
    setState(() {});
  }

  void _toggleLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isEnglish = !isEnglish;
    await prefs.setBool('isEnglish', isEnglish);
    setState(() {});
  }

  Future<void> _fetchUserName() async {
    if (!widget.isGuest) {
      String fetchedName = await DatabaseHelper.instance.getUserName(widget.username);
      setState(() {
        name = fetchedName;
      });
    } else {
      setState(() {
        name = "Guest";
      });
    }
  }

  Future<void> _fetchUserAnalyses() async {
    if (!widget.isGuest) {
      List<Map<String, dynamic>> analyses = await DatabaseHelper.instance.getUserAnalyses(widget.username);
      setState(() {
        _userAnalyses = analyses;
      });
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedItems.clear();
    });
  }

  void _selectAllItems() {
    setState(() {
      _isSelectionMode = true;
      _selectedItems = _userAnalyses.map((a) => a['id'] as int).toSet();
    });
  }

  Future<void> _deleteSelectedAnalyses() async {
    for (int id in _selectedItems) {
      await DatabaseHelper.instance.deleteAnalysis(id);
    }
    await _fetchUserAnalyses();
    _toggleSelectionMode();
  }

  Future<void> _handleSendEmail(String userName, String userEmail, String analysisResult) async {
    bool success = await EmailService.sendAnalysisToEmail(
      context: context, // ✅ Fix here
      isEnglish: isEnglish,
      userName: userName,
      userEmail: userEmail,
      analysisResult: analysisResult,
    );




  if (success) {
      setState(() {
        _isSelectionMode = false;
        _selectedItems.clear();
      });
    }
  }


  void _prepareAndSendEmail(String name, String username, String analysisResult) async {
     // or DatabaseHelper.instance depending on your implementation
    final userEmail = await DatabaseHelper.instance.getUserEmail(username);

    if (userEmail != null) {
      _handleSendEmail(name, userEmail, analysisResult); // Now this is correct!
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not find email for user $username")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EDF7),
      appBar: SmartLabAppBar(onLanguageToggle: _toggleLanguage),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        username: widget.username,
        isEnglish: isEnglish,
        isGuest: widget.isGuest,
      ),
      body: Directionality(
        textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 60),
              _buildHeader(),
              const SizedBox(height: 20),
              _buildActionsRow(),
              const SizedBox(height: 10),
              Expanded(child: _buildAnalysisList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEnglish
              ? "Hello, ${name.isNotEmpty ? name : "User"}"
              : "مرحباً، ${name.isNotEmpty ? name : "المستخدم"}",
          style: GoogleFonts.handlee(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildActionsRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 40.0),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey, width: 1.0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isEnglish ? "Recent Analysis :" : "التحليلات الأخيرة :",
              style: const TextStyle(fontSize: 20),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              offset: const Offset(0, 50),
              onSelected: (selected) {
                switch (selected) {
                  case 'select':
                    _toggleSelectionMode();
                    break;
                  case 'selectAll':
                    _selectAllItems();
                    break;
                  case 'delete':
                    if (_selectedItems.isNotEmpty) _deleteSelectedAnalyses();
                    break;
                  case 'sendEmail':
                    if (_selectedItems.length != 1) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                          isEnglish
                              ? "Please select exactly one analysis to send"
                              : "يرجى تحديد تحليل واحد فقط للإرسال",
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                      ));
                    } else {
                      final selectedId = _selectedItems.first;
                      final selectedAnalysis = _userAnalyses.firstWhere((a) => a['id'] == selectedId);
                      _prepareAndSendEmail(name, widget.username, selectedAnalysis['analysis_text']);

                    }
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'select',
                  child: Text(isEnglish ? 'Select' : 'تحديد'),
                ),
                PopupMenuItem(
                  value: 'selectAll',
                  child: Text(isEnglish ? 'Select All' : 'تحديد الكل'),
                ),
                PopupMenuItem(
                  value: 'sendEmail',
                  child: Text(isEnglish ? 'Send to Email' : 'إرسال إلى البريد'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    isEnglish ? 'Delete' : 'حذف',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisList() {
    if (widget.isGuest) {
      return Center(
        child: Text(
          isEnglish ? "Guest users cannot view analyses." : "لا يمكن للمستخدمين الضيوف عرض التحليلات.",
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    if (_userAnalyses.isEmpty) {
      return Center(
        child: Text(
          isEnglish ? "No saved analyses yet." : "لا توجد تحليلات محفوظة بعد.",
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _userAnalyses.length,
      itemBuilder: (context, index) {
        var analysis = _userAnalyses[index];
        bool isSelected = _selectedItems.contains(analysis['id']);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            elevation: 4,
            color: Colors.white,
            shadowColor: Colors.deepPurple.shade100,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              title: Text(
                analysis['test_name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  "${isEnglish ? "Date:" : "التاريخ:"} ${analysis['timestamp'].substring(0, 10)}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              trailing: _isSelectionMode
                  ? Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    value!
                        ? _selectedItems.add(analysis['id'])
                        : _selectedItems.remove(analysis['id']);
                  });
                },
              )
                  : const Icon(Icons.arrow_forward_ios, size: 20),
              onTap: () {
                if (_isSelectionMode) {
                  setState(() {
                    isSelected
                        ? _selectedItems.remove(analysis['id'])
                        : _selectedItems.add(analysis['id']);
                  });
                } else {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                      builder: (context) => ResultsPage(
                      username: widget.username,
                      analysisText: analysis['analysis_text'],
                      isGuest: widget.isGuest,
                      isAlreadySaved: true,

                      ),
                      ),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }
}
