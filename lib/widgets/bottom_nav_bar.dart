import 'package:flutter/material.dart';
import '../screens/home_page.dart';
import '../screens/report_upload_page.dart';
import '../screens/profile_page.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final String username;
  final bool isEnglish;
  final bool isGuest;

  BottomNavBar(
      {required this.currentIndex,
      required this.username,
      required this.isEnglish,
      required this.isGuest});

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
  }

  // Function to handle navigation when a button is tapped
  void _onItemTapped(BuildContext context, int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    Widget page;
    switch (index) {
      case 0:
        page = HomePage(
          username: widget.username,
          isGuest: widget.isGuest,
        );
        break;
      case 1:
        page = ReportUploadPage(
          username: widget.username,
          isGuest: widget.isGuest,
        );
        break;
      case 2:
        page = ProfilePage(
          username: widget.username,
          isGuest: widget.isGuest,
        );
        break;
      default:
        return;
    }

    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => page),
        (Route<dynamic> route) => false,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Color(0xFFC8BDD6),
      selectedItemColor: Colors.blue,
      unselectedItemColor: Color(0xFF31273C),
      currentIndex: _currentIndex,
      onTap: (index) => _onItemTapped(context, index),
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: widget.isEnglish ? "Home" : "الصفحة الرئيسية",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.upload, size: 40),
          label: widget.isEnglish ? "Upload" : "تحميل",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: widget.isEnglish ? "Profile" : "الملف الشخصي",
        ),
      ],
    );
  }
}
