import 'dart:io';
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
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: Image.file(
                              File(controller.capturedImagePath.value),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
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
                    if (controller.analysisData.isNotEmpty)
                      _buildAnalysisResultCard(controller.analysisData)
                    else
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

  Widget _buildAnalysisResultCard(Map<String, dynamic> data) {
    final defectType = data['defect_type']?.toString() ?? 'unknown';
    final isClear = defectType.toLowerCase() == 'normal';
    final formattedDefectType = defectType.isNotEmpty ? '${defectType[0].toUpperCase()}${defectType.substring(1)}' : defectType;
    final confidence = data['confidence'] != null ? ((data['confidence'] as double) * 100).toStringAsFixed(1) : '0';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isClear ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isClear ? Colors.green : AppTheme.accentRed,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isClear ? Icons.check_circle : Icons.auto_awesome,
                color: isClear ? Colors.green : AppTheme.accentRed,
              ),
              const SizedBox(width: 8),
              const Text(
                'AI Analysis Result',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildResultRow('Condition', isClear ? 'Clear: Normal' : 'Defect: $formattedDefectType'),
          _buildResultRow('Confidence', '$confidence%'),
          _buildResultRow('Shipment ID', data['shipment_id']?.toString() ?? '-'),
          _buildResultRow('Timestamp', data['timestamp']?.toString() ?? '-'),
          if (data['item_type'] != null && data['item_type'].toString().isNotEmpty && data['item_type'].toString() != 'null')
             _buildResultRow('Item Type', data['item_type'].toString()),
          if (data['damage_location'] != null && data['damage_location'].toString().isNotEmpty && data['damage_location'].toString() != 'null')
             _buildResultRow('Damage Location', data['damage_location'].toString()),
          _buildResultRow('Explanation', data['explanation']?.toString() ?? '-'),
          const Divider(height: 24),
          const Text('Blockchain Evidence Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          _buildHashRow('Shipment Hash', data['shipment_hash']?.toString() ?? '-'),
          _buildHashRow('Evidence Hash', data['evidence_hash']?.toString() ?? '-'),
          _buildHashRow('Image Hash', data['image_hash']?.toString() ?? '-'),
          _buildResultRow('Chain ID', data['defect_type_chain_id']?.toString() ?? '-'),
          _buildResultRow('Confidence BPS', data['confidence_bps']?.toString() ?? '-'),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black54))),
        ],
      ),
    );
  }

  Widget _buildHashRow(String label, String hash) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
          Expanded(child: Text(hash, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.blueGrey))),
        ],
      ),
    );
  }
}
