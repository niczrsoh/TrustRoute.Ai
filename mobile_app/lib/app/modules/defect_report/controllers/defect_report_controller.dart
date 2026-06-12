import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:trust_route/app/modules/dashboard/controllers/dashboard_controller.dart';

class DefectReportController extends GetxController {
  String get baseUrl {
    return Platform.isAndroid
        ? 'http://10.0.2.2:8000'
        : 'http://127.0.0.1:8000';
  }

  DashboardController get dashboard => Get.find<DashboardController>();

  List<String> get dynamicShipments {
    if (dashboard.availableShipments.isEmpty) {
      return ['SHP-10024-ALPHA', 'SHP-99213-BETA', 'SHP-55092-GAMMA'];
    }
    return dashboard.availableShipments;
  }

  List<DefectRecord> get dynamicDefectHistory {
    return dashboard.recentDefects
        .where((d) => d.shipmentId == selectedShipment.value)
        .toList();
  }

  // State variables
  final selectedShipment = ''.obs;
  final capturedImagePath = ''.obs;
  final isAnalyzing = false.obs;
  final aiAnalysisResult = ''.obs;
  final analysisData = <String, dynamic>{}.obs;

  final ImagePicker _picker = ImagePicker();

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  String _formatLabel(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  @override
  void onInit() {
    super.onInit();
    // Select first shipment by default
    if (dynamicShipments.isNotEmpty) {
      selectedShipment.value = dynamicShipments.first;
    }
    fetchClasses();
  }

  Future<void> fetchClasses() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/classes'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final classes = List<String>.from(data['classes']);
        print('Available defect classes: $classes');
      }
    } catch (e) {
      print('Failed to fetch defect classes: $e');
    }
  }

  Future<void> captureImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // Compress slightly
    );
    if (image != null) {
      capturedImagePath.value = image.path;
      aiAnalysisResult.value = ''; // Reset previous result
      analysisData.clear();
    }
  }

  void removeImage() {
    capturedImagePath.value = '';
    aiAnalysisResult.value = '';
    analysisData.clear();
  }

  Future<void> submitReport() async {
    if (capturedImagePath.value.isEmpty) {
      Get.snackbar('Error', 'Please capture or upload an image first.');
      return;
    }

    isAnalyzing.value = true;
    aiAnalysisResult.value = 'Uploading and analyzing image...';

    try {
      final uri = Uri.parse('$baseUrl/predict');

      var request = http.MultipartRequest('POST', uri);
      request.fields['shipment_id'] = selectedShipment.value;
      request.files.add(
          await http.MultipartFile.fromPath('image', capturedImagePath.value));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        analysisData.value = data; // Store full object
        final String defectType = data['defect_type'].toString();
        final String formattedDefectType = _formatLabel(defectType);
        final confidence =
            (_asDouble(data['confidence']) * 100).toStringAsFixed(1);
        final explanation = data['explanation'];
        final blockchainStatus =
            data['blockchain_status']?.toString() ?? 'not_submitted';

        if (defectType.toLowerCase() == 'normal') {
          aiAnalysisResult.value =
              'Clear: Normal package condition detected.\nConfidence: $confidence%\nBlockchain: $blockchainStatus';
        } else {
          aiAnalysisResult.value =
              'Defect Detected: $formattedDefectType\nConfidence: $confidence%\nBlockchain: $blockchainStatus\nExplanation: $explanation';
        }

        if (Get.isRegistered<DashboardController>()) {
          await Get.find<DashboardController>().fetchReports();
        }

        Get.snackbar(
          'Analysis Complete',
          'Report submitted successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        aiAnalysisResult.value =
            'Analysis Failed. Status Code: ${response.statusCode}\n${response.body}';
      }
    } catch (e) {
      aiAnalysisResult.value =
          'Analysis Failed: Unable to reach backend.\nEnsure the Python FastAPI server is running.';
      print('API Error: $e');
    } finally {
      isAnalyzing.value = false;
    }
  }
}
