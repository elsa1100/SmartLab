import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class EmailService {
  static Future<bool> sendAnalysisToEmail({
    required BuildContext context,
    required String userName,
    required String userEmail,
    required String analysisResult,
    required bool isEnglish,
    http.Client? client, // Optional client for testing
  }) async {
    const serviceId = 'service_nn17u95';
    const templateIdEnglish = 'template_rdni558';
    const templateIdArabic = 'template_qw27dfe';
    const publicKey = 'aLAIXXjDD9n873wZb';
    final urlString = 'https://api.emailjs.com/api/v1.0/email/send';
    final url = Uri.parse(Uri.encodeFull(urlString));

    // Use the provided client or default to http.Client()
    client ??= http.Client();

    print("Sending POST request to: $url");

    try {
      final response = await client.post(
        url,
        headers: {
          'origin': 'http://localhost',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': serviceId,
          'template_id': isEnglish ? templateIdEnglish : templateIdArabic,
          'user_id': publicKey,
          'template_params': {
            'user_name': userName,
            'analysis_result': analysisResult,
            'to_email': userEmail,
          },
        }),
      );

      final success = response.statusCode == 200;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (isEnglish ? "Email sent successfully" : "تم إرسال البريد بنجاح")
                : (isEnglish ? "Failed to send email" : "فشل إرسال البريد"),
          ),
        ),
      );

      return success;
    } catch (e) {
      print("Error while sending email: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEnglish
                ? "An error occurred while sending the email."
                : "حدث خطأ أثناء إرسال البريد.",
          ),
        ),
      );

      return false;
    }
  }
}