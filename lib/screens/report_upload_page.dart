import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/bottom_nav_bar.dart';
import '../database/database_helper.dart';
import 'results_page.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/gemini_service.dart';
import '../services/ocr_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/top_app_bar.dart';
import '../widgets/base.dart';

class ReportUploadPage extends StatefulWidget {
  final String username;
  final bool isGuest;

  ReportUploadPage({required this.username, required this.isGuest});

  @override
  _ReportUploadPageState createState() => _ReportUploadPageState();
}


final OCRService _ocrService = OCRService(apiKey: 'K89712773788957');


class _ReportUploadPageState extends State<ReportUploadPage> {
  File? _selectedFile;
  String name = "";
  bool isEnglish = true;
  bool _isLoading = false;
  String _analysisResult = "";
  final GeminiService _geminiService = GeminiService();
  final OCRService _ocrService = OCRService(apiKey: 'K89712773788957');

  bool _isPDF = false;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _loadLanguagePreference();
  }

  void _fetchUserName() async {
    String fetchedName = await DatabaseHelper.instance.getUserName(widget.username);
    setState(() {
      name = fetchedName;
    });
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

  Future<void> _pickFile() async {
    if (widget.isGuest) {
      await _showLoginPrompt();

    }

    FilePickerResult? result = await _pickFileFromDevice();
    if (result == null || result.files.single.path == null) {
      return;
    }

    File selected = File(result.files.single.path!);
    bool isPDF = _isPDFFile(selected);

    _startLoading(isPDF);

    try {
      String analysisText = await _analyzeFile(selected, isPDF);
      _navigateToResultsPage(analysisText);
    } catch (e) {
      _handleAnalysisFailure(e);
    } finally {
      _stopLoading();
    }
  }


  Future<void> _showLoginPrompt() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(seconds: 2),
        content: Text(isEnglish ? "Please log in to save analysis." : "يرجى تسجيل الدخول لحفظ التحليل"),
      ),
    );
    await Future.delayed(Duration(seconds: 5));
  }

  Future<FilePickerResult?> _pickFileFromDevice() async {
    return await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
  }

  bool _isPDFFile(File file) {
    return file.path.toLowerCase().endsWith(".pdf");
  }

  void _startLoading(bool isPDF) {
    setState(() {
      _selectedFile = _selectedFile;
      _isPDF = isPDF;
      _isLoading = true;
      _analysisResult = isEnglish ? "Analyzing..." : "...جاري التحليل";
    });
  }

  Future<String> _analyzeFile(File selected, bool isPDF) async {
    if (isPDF) {
      print("PDF file detected: sending directly to Gemini");
      return await _geminiService.analyzeMedicalReport(selected, isEnglish);
    } else {
      final extractedText = await _ocrService.extractTextFromFile(selected, isEnglish);
      bool textIsWeak = _ocrService.isWeakOCRText(extractedText);

      if (textIsWeak) {
        print("Weak OCR result: fallback to Gemini file upload");
        return await _geminiService.analyzeMedicalReport(selected, isEnglish);
      } else {
        print("Strong OCR result: sending extracted text to Gemini");
        return await _geminiService.analyzeTextOCR(extractedText, isEnglish);
      }
    }
  }


  void _navigateToResultsPage(String analysisText) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsPage(
          username: widget.username,
          analysisText: analysisText,
          isGuest: widget.isGuest,
        ),
      ),
    );
  }

  void _handleAnalysisFailure(Object e) {
    String errorMessage = isEnglish ? "Analysis failed." : "فشل التحليل";

    if (e is Exception) {
      errorMessage = isEnglish ? "An error occurred during analysis." : "حدث خطأ أثناء التحليل";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
      ),
    );
  }

  void _stopLoading() {
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3EDF7),
      appBar: SmartLabAppBar(onLanguageToggle: _toggleLanguage),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: 0.9,
              child: Image.asset('assets/logo.png', height: 180),
            ),
            SizedBox(height: 20),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0x6109060C)),
              ),
              child: _selectedFile == null
                  ? Center(
                child: Text(
                  isEnglish ? 'No File Selected or Uploaded' : 'لم يتم تحديد أو تحميل ملف',
                  style: TextStyle(color: Color(0xC709060C), fontSize: 16),
                ),
              )
                  : _isPDF
                  ? Center(
                child: Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
              )
                  : Image.file(_selectedFile!, fit: BoxFit.cover),
            ),
            SizedBox(height: 50),
            _isLoading
                ? Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text(isEnglish ? "Please wait, analyzing..." : "...الرجاء الانتظار، جاري التحليل"),
              ],
            )
                : RoundedButton(
              text: isEnglish ? 'Upload Report' : 'تحميل التقرير',
              onPressed: _pickFile,
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        username: widget.username,
        isEnglish: isEnglish,
        isGuest: widget.isGuest,
      ),
    );
  }
}