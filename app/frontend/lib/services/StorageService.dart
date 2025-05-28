import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final String baseUrl;
  final Dio dio;

  StorageService({String environment = 'local'})
      : baseUrl = _getBaseUrl(environment),
        dio = Dio() {
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(minutes: 15);
  }

  static String _getBaseUrl(String environment) {
    switch (environment) {
      case 'local':
        return Platform.isAndroid
            ? 'http://10.0.2.2:8000'
            : 'http://localhost:8000';
      case 'aws':
        return 'http://13.57.218.69:8000';
      default:
        throw ArgumentError('Invalid environment: $environment');
    }
  }

  Future<Map<String, dynamic>> analyzeAndStoreShot(
      File mediaFile, String player, bool isVideo) async {
    try {
      print(
          "StorageService: Preparing to analyze ${isVideo ? 'video' : 'image'} for player: $player");

      var uri = '$baseUrl/upload';
      print("StorageService: Connecting to $uri");

      // Get file size
      int fileSize = await mediaFile.length();
      print("StorageService: File size: $fileSize bytes");

      // Get MIME type
      String? mimeType = lookupMimeType(mediaFile.path);

      // Convert MIME type string to MediaType object
      MediaType? mediaType;
      if (mimeType != null) {
        List<String> parts = mimeType.split('/');
        if (parts.length == 2) {
          mediaType = MediaType(parts[0], parts[1]);
        }
      }

      // Prepare form data
      var formData = FormData.fromMap({
        'player': player,
        'is_video': isVideo.toString(),
        'file': await MultipartFile.fromFile(
          mediaFile.path,
          filename: path.basename(mediaFile.path),
          contentType: mediaType,
        ),
      });

      print("StorageService: Sending request...");
      var response = await retry(() => dio.post(uri, data: formData));

      print("StorageService: Response status: ${response.statusCode}");
      print("StorageService: Response body: ${response.data}");

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
            'Failed to analyze ${isVideo ? 'video' : 'image'}: ${response.statusCode} - ${response.data}');
      }
    } on DioException catch (e) {
      print(
          "StorageService: DioException in analyzeAndStoreShot: ${e.message}");
      print("StorageService: DioException type: ${e.type}");
      print("StorageService: DioException response: ${e.response?.data}");
      rethrow;
    } catch (e) {
      print("StorageService: Unexpected error in analyzeAndStoreShot: $e");
      rethrow;
    }
  }

  Future<T> retry<T>(Future<T> Function() fn, {int maxRetries = 3}) async {
    for (var i = 0; i < maxRetries; i++) {
      try {
        return await fn();
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        print("StorageService: Retry attempt ${i + 1} after error: $e");
        await Future.delayed(Duration(seconds: 2 * (i + 1)));
      }
    }
    throw Exception("Max retries reached");
  }
}
