import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey = "AIzaSyCYKNC77uYi7LkRQY0uCPitQcKc9PWedCU";

  // 🔹 Analyze medical report file (image or PDF)
  Future<String> analyzeMedicalReport(File file, bool isEnglish) async {
    String apiUrl =
        "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$apiKey";

    List<int> fileBytes = await file.readAsBytes();
    String base64File = base64Encode(fileBytes);

    String fileExtension = file.path
        .split('.')
        .last
        .toLowerCase();
    String mimeType =
    (fileExtension == 'pdf') ? 'application/pdf' : 'image/jpeg';

    String prompt = isEnglish
        ? """
         This is a medical test report. Please analyze the attached file (image or PDF) and return the result in the following clear format:

         1. Abnormal values:
            - Test name: value (High or Low)

         2. Simple explanation of each abnormal value:
            - Test name: short explanation

         3. Possible medical conditions and advice:
            - Test name: related conditions and medical advice (e.g., see a doctor, or monitor)

         Please keep it short, informative, professional, and avoid using symbols like ** or markdown formatting.
         """
        : """
هذا تقرير فحص طبي. يرجى تحليله وترتيب النتيجة بالتنسيق التالي:         
         
         ١. القيم الخارجة عن المعدل الطبيعي ( سرد الارقام باللغه العربيه )         :
              -  اسم التحليل: القيمة (مرتفعة أو منخفضة)

٢. شرح بسيط قصير لكل القيم الخارجة عن المعدل الطبيعي :         
            - اسم التحليل: شرح طبي مختصر

٣. الحالات الصحية المحتملة والنصائح بشكل قصير ومختصر :         
            - اسم التحليل: الأمراض المحتملة والنصيحة الطبية

❗️ ملاحظات مهمة :         
- لا تكتب أسماء التحاليل او الاختصارات  أو الشروحات باللغة الإنجليزية إطلاقًا.         
- استخدم فقط أسماء التحاليل الطبية العربية المعروفة.         
- اجعل الإجابة منسقة وواضحة ومناسبة لفهم غير المختصين.         
         """;

    var requestBody = {
      "contents": [
        {
          "parts": [
            {
              "inlineData": {"mimeType": mimeType, "data": base64File}
            },
            {"text": prompt}
          ]
        }
      ]
    };

    var response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      return jsonResponse["candidates"][0]["content"]["parts"][0]["text"] ??
          "No explanation found.";
    } else {
      return "Error: ${response.body}";
    }
  }

  // 🔹 Analyze extracted OCR text
  Future<String> analyzeTextOCR(String extractedText, bool isEnglish) async {
    String apiUrl =
        "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$apiKey";

    String prompt = isEnglish
        ? """
This is an extracted text from a medical lab report:

$extractedText

Please analyze it and organize the result in the following format:

1. Abnormal values:
   - Test name: value (High or Low)

2. Simple explanation of each abnormal value:
   - Test name: short explanation

3. Possible medical conditions and advice:
   - Test name: related conditions and medical advice (e.g., see a doctor, or monitor)

Keep the explanation short, clear, and professional.
"""
        : """
هذا نص مستخرج من تقرير طبي:

$extractedText

يرجى تحليله وترتيب النتيجة بالتنسيق التالي:

١. القيم الخارجة عن المعدل الطبيعي:
   - اسم التحليل: القيمة (مرتفعة أو منخفضة)

٢. شرح بسيط لكل تحليل قصير :
   - اسم التحليل: شرح طبي مختصر

٣. الحالات الصحية المحتملة والنصائح (قصير ):
   - اسم التحليل: الأمراض المحتملة والنصيحة الطبية (مثل راجع الطبيب، أو راقب فقط)

يجب أن تكون الإجابة مرتبة، مختصرة، وواضحة باللغة العربية دون رموز إنجليزية أو وحدات مثل mg/dL.
""";

    var requestBody = {
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse["candidates"][0]["content"]["parts"][0]["text"] ??
          "No interpretation returned.";
    } else {
      return "Error: ${response.body}";
    }
  }

}
