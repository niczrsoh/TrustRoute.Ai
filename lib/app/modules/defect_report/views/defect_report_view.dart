import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trust_route/app/core/theme/app_theme.dart';
import '../controllers/defect_report_controller.dart';

class DefectReportView extends GetView<DefectReportController> {
  const DefectReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Select Shipment ID
            Text(
              'Select Shipment / Asset ID',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: controller.selectedShipment.value.isNotEmpty
                          ? controller.selectedShipment.value
                          : null,
                      items: controller.dummyShipments.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          controller.selectedShipment.value = newValue;
                        }
                      },
                    ),
                  ),
                )),
            const SizedBox(height: 24),

            // 2. Defect History for Selected Shipment
            Text(
              'Defect History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final history = controller
                      .dummyDefectHistory[controller.selectedShipment.value] ??
                  [];
              if (history.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No previous defects reported for this shipment.'),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      title: Text(item['issue'] ?? ''),
                      subtitle: Text('Date: ${item['date']} • Status: ${item['status']}'),
                    ),
                  );
                },
              );
            }),
            const SizedBox(height: 24),

            // 3. Capture / Upload Image
            Text(
              'Report New Defect',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Obx(() => controller.capturedImagePath.value.isEmpty
                ? InkWell(
                    onTap: controller.captureImage,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Tap to Capture / Upload Image', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  )
                : Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        const Center(child: Icon(Icons.image, size: 64, color: AppTheme.primaryNavy)),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: AppTheme.accentRed),
                            onPressed: controller.removeImage,
                            style: IconButton.styleFrom(backgroundColor: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )),
            const SizedBox(height: 24),

            // 4. Submit & Display AI Result
            Obx(() {
              if (controller.isAnalyzing.value) {
                return const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppTheme.primaryNavy),
                      SizedBox(height: 16),
                      Text('AI is analyzing the image...'),
                    ],
                  ),
                );
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: controller.submitReport,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Analyze & Submit Report'),
                  ),
                  if (controller.aiAnalysisResult.value.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: controller.aiAnalysisResult.value.contains('Clear') 
                            ? Colors.green.shade50 
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: controller.aiAnalysisResult.value.contains('Clear') 
                            ? Colors.green 
                            : AppTheme.accentRed,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                controller.aiAnalysisResult.value.contains('Clear') 
                                    ? Icons.check_circle 
                                    : Icons.auto_awesome, 
                                color: controller.aiAnalysisResult.value.contains('Clear') 
                                    ? Colors.green 
                                    : AppTheme.accentRed,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'AI Analysis Result',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(controller.aiAnalysisResult.value),
                        ],
                      ),
                    ),
                  ]
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
