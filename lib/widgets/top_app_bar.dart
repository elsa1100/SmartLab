import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SmartLabAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onLanguageToggle;

  const SmartLabAppBar({Key? key, required this.onLanguageToggle})
      : super(key: key);

  @override
  _SmartLabAppBarState createState() => _SmartLabAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SmartLabAppBarState extends State<SmartLabAppBar> {
  bool isEnglish = true;

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isEnglish = prefs.getBool('isEnglish') ?? true;
    });
  }

  Future<void> _toggleLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isEnglish = !isEnglish;
      prefs.setBool('isEnglish', isEnglish);
    });
    widget.onLanguageToggle();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        'Smart Lab',
        style: GoogleFonts.handlee(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      backgroundColor: const Color(0xFFC8BDD6),
      actions: [
        IconButton(
          icon: const Icon(Icons.language, color: Colors.black),
          onPressed: _toggleLanguage,
        ),
      ],
    );
  }
}
