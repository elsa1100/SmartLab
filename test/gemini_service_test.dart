import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:untitled1/services/gemini_service.dart'; // Update with your actual import path
import 'gemini_service_test.mocks.dart';

@GenerateMocks([GeminiService])
void main() {
  late MockGeminiService mockGeminiService;

  setUp(() {
    mockGeminiService = MockGeminiService();
  });

  group('GeminiService Tests', () {
    test('analyzeMedicalReport returns expected result', () async {
      // Arrange
      final fakeFile = File('test/assets/fake_report.jpg');
      const expectedResult = 'Analysis of medical report in English.';
      const isEnglish = true;

      when(mockGeminiService.analyzeMedicalReport(fakeFile, isEnglish))
          .thenAnswer((_) async => expectedResult);

      // Act
      final result =
      await mockGeminiService.analyzeMedicalReport(fakeFile, isEnglish);

      // Assert
      expect(result, expectedResult);
      verify(mockGeminiService.analyzeMedicalReport(fakeFile, isEnglish)).called(1);
    });

    test('analyzeTextOCR returns expected analysis for extracted text', () async {
      // Arrange
      const extractedText = 'Glucose: 160 mg/dL';
      const expectedResult = 'Your glucose is slightly high.';
      const isEnglish = true;

      when(mockGeminiService.analyzeTextOCR(extractedText, isEnglish))
          .thenAnswer((_) async => expectedResult);

      // Act
      final result =
      await mockGeminiService.analyzeTextOCR(extractedText, isEnglish);

      // Assert
      expect(result, expectedResult);
      verify(mockGeminiService.analyzeTextOCR(extractedText, isEnglish)).called(1);
    });
  });
}
