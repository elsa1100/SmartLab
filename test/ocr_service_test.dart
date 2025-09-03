import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'ocr_service_test.mocks.dart';

import 'package:untitled1/services/ocr_service.dart';

@GenerateMocks([http.Client, http.MultipartRequest])
void main() {
  late OCRService ocrService;
  late MockMultipartRequest mockRequest;

  setUp(() {
    mockRequest = MockMultipartRequest();

    // Stub fields and files to behave like maps
    final fakeFields = <String, String>{};
    final fakeFiles = <http.MultipartFile>[];

    when(mockRequest.fields).thenReturn(fakeFields);
    when(mockRequest.files).thenReturn(fakeFiles);

    ocrService = OCRService(
      apiKey: 'fake-api-key',
      multipartRequestFactory: (_) => mockRequest,
    );
  });

  test('extractTextFromMultipartFile returns parsed text on success', () async {
    final fakeResponse = http.StreamedResponse(
      Stream.fromIterable([
        utf8.encode(jsonEncode({
          'ParsedResults': [
            {'ParsedText': 'LDL: 130 mg/dL\nALT: 40 IU/L'}
          ]
        }))
      ]),
      200,
    );

    final multipartFile = http.MultipartFile.fromBytes(
      'file',
      utf8.encode('Mocked text content'),
      filename: 'mocked.txt',
    );

    when(mockRequest.send()).thenAnswer((_) async => fakeResponse);

    final result = await ocrService.extractTextFromMultipartFile(multipartFile, true);

    expect(result, contains('LDL'));
    expect(result, contains('ALT'));
  });
}
