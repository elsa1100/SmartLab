import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OCRService {
  final String apiKey;
  final http.Client client;
  final MultipartRequestFactory multipartRequestFactory;

  OCRService({
    required this.apiKey,
    http.Client? client,
    MultipartRequestFactory? multipartRequestFactory,
  })  : client = client ?? http.Client(),
        multipartRequestFactory = multipartRequestFactory ?? defaultMultipartRequestFactory;

  static http.MultipartRequest defaultMultipartRequestFactory(Uri uri) {
    return http.MultipartRequest('POST', uri);
  }

  /// This is used in production with actual files
  Future<String> extractTextFromFile(File file, bool isEnglish) async {
    final multipartFile = await http.MultipartFile.fromPath('file', file.path);
    return extractTextFromMultipartFile(multipartFile, isEnglish);
  }


  Future<String> extractTextFromMultipartFile(http.MultipartFile file, bool isEnglish) async {
    final uri = Uri.parse("https://api.ocr.space/parse/image");
    final request = multipartRequestFactory(uri)
      ..fields['apikey'] = apiKey
      ..fields['language'] = isEnglish ? 'eng' : 'ara'
      ..files.add(file);

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(responseData);
      final text = jsonResponse['ParsedResults'][0]['ParsedText'];
      return text;
    } else {
      throw Exception("OCR failed: $responseData");
    }
  }

  //if too short , no numbers , half of important words are missing
  bool isWeakOCRText(String extractedText) {
    final requiredKeywords = [
      // CBC
      'WBC', 'RBC', 'Hemoglobin', 'Hematocrit', 'Platelets', 'MCV', 'MCH', 'MCHC',

      // BMP
      'Glucose', 'Calcium', 'Sodium', 'Potassium', 'Chloride', 'CO2', 'BUN', 'Creatinine',

      // Liver Function Tests
      'ALT', 'AST', 'ALP', 'Bilirubin', 'Albumin', 'Total Protein',

      // Lipid Panel
      'Cholesterol', 'Triglycerides', 'HDL', 'LDL',

      // Other common
      'Uric Acid', 'Magnesium', 'Phosphorus', 'Iron', 'Ferritin', 'Vitamin D', 'TSH',
    ];

    String normalizedText = extractedText.toLowerCase();
    int matches = requiredKeywords
        .where((keyword) => normalizedText.contains(keyword.toLowerCase()))
        .length;

    return extractedText.length < 100 ||
        matches < 3 || // Still requiring at least 3 keywords to consider strong
        !RegExp(r'\d+').hasMatch(extractedText);
  }

}

typedef MultipartRequestFactory = http.MultipartRequest Function(Uri uri);
