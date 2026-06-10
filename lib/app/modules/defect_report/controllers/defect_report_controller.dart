import 'package:get/get.dart';

class DefectReportController extends GetxController {
  // Dummy data for shipments
  final List<String> dummyShipments = [
    'SHP-10024-ALPHA',
    'SHP-99213-BETA',
    'SHP-55092-GAMMA',
  ];

  // Dummy defect history
  final Map<String, List<Map<String, String>>> dummyDefectHistory = {
    'SHP-10024-ALPHA': [
      {'date': '2026-06-08', 'issue': 'Minor dent on container side', 'status': 'Resolved'},
      {'date': '2026-06-05', 'issue': 'Seal broken', 'status': 'Pending Investigation'},
    ],
    'SHP-99213-BETA': [],
    'SHP-55092-GAMMA': [
      {'date': '2026-06-01', 'issue': 'Water damage on outer packaging', 'status': 'Resolved'},
    ],
  };

  // State variables
  final selectedShipment = ''.obs;
  final capturedImagePath = ''.obs;
  final isAnalyzing = false.obs;
  final aiAnalysisResult = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Select first shipment by default
    if (dummyShipments.isNotEmpty) {
      selectedShipment.value = dummyShipments.first;
    }
  }

  void captureImage() {
    // Simulating capturing an image
    capturedImagePath.value = 'dummy_image_path.jpg';
    aiAnalysisResult.value = ''; // Reset previous result
  }

  void removeImage() {
    capturedImagePath.value = '';
    aiAnalysisResult.value = '';
  }

  Future<void> submitReport() async {
    if (capturedImagePath.value.isEmpty) {
      Get.snackbar('Error', 'Please capture or upload an image first.');
      return;
    }

    isAnalyzing.value = true;
    aiAnalysisResult.value = 'Analyzing image...';

    // Simulate AI network call
    await Future.delayed(const Duration(seconds: 2));

    isAnalyzing.value = false;
    
    // Randomize result slightly for dummy effect
    final results = [
      'Warning: Major structural dent detected. Confidence: 92%',
      'Alert: Unauthorized seal break detected. Confidence: 88%',
      'Notice: Minor surface scratches, no critical damage. Confidence: 95%',
      'Clear: No visible defects detected. Confidence: 99%',
    ];
    results.shuffle();
    aiAnalysisResult.value = results.first;

    // In a real app we'd add this to the database, for now just show a success message
    Get.snackbar(
      'Analysis Complete', 
      'Report submitted successfully.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
