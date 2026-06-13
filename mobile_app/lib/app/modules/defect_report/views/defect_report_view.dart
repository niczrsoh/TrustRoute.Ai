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
            // // 2. Defect History for Selected Shipment
            // Text(
            //   'Defect History',
            //   style: Theme.of(context).textTheme.titleMedium?.copyWith(
            //         fontWeight: FontWeight.bold,
            //       ),
            // ),
            // const SizedBox(height: 8),
            // Obx(() {
            //   final history = controller.dynamicDefectHistory;
            //   if (history.isEmpty) {
            //     return const Card(
            //       child: Padding(
            //         padding: EdgeInsets.all(16.0),
            //         child: Text('No previous defects reported for this shipment.'),
            //       ),
            //     );
            //   }
            //   return ListView.builder(
            //     shrinkWrap: true,
            //     physics: const NeverScrollableScrollPhysics(),
            //     itemCount: history.length,
            //     itemBuilder: (context, index) {
            //       final item = history[index];
            //       return Card(
            //         margin: const EdgeInsets.only(bottom: 8),
            //         child: ListTile(
            //           leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            //           title: Text(item.title),
            //           subtitle: Text('Date: ${item.date.toString().substring(0, 10)} • Status: ${item.status}'),
            //         ),
            //       );
            //     },
            //   );
            // }),
            // const SizedBox(height: 24),
            // // 3. Capture / Upload Image
            Text(
              'Report New Defect',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Obx(
              () => controller.capturedImagePath.value.isEmpty
                  ? InkWell(
                      onTap: controller.captureImage,
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: AppTheme.frostBlue.withOpacity(0.3),
                          border: Border.all(
                            color: AppTheme.secondaryBlue.withOpacity(0.4),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.cardWhite,
                                shape: BoxShape.circle,
                                boxShadow: AppTheme.softShadow,
                              ),
                              child: const Icon(
                                Icons.cloud_upload_rounded,
                                size: 40,
                                color: AppTheme.secondaryBlue,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Tap to capture or upload image',
                              style: TextStyle(
                                color: AppTheme.primaryNavy,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Supports JPG, PNG • Max 10MB',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
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
                              icon: const Icon(
                                Icons.close,
                                color: AppTheme.accentRed,
                              ),
                              onPressed: controller.removeImage,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
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
                          color:
                              controller.aiAnalysisResult.value.contains(
                                'Clear',
                              )
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                controller.aiAnalysisResult.value.contains(
                                  'Clear',
                                )
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
                                  controller.aiAnalysisResult.value.contains(
                                        'Clear',
                                      )
                                      ? Icons.check_circle
                                      : Icons.auto_awesome,
                                  color:
                                      controller.aiAnalysisResult.value
                                          .contains('Clear')
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
                  ],
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
    final formattedDefectType = _formatLabel(defectType);
    final confidence = (_asDouble(data['confidence']) * 100).toStringAsFixed(1);

    final mainColor = isClear ? AppTheme.accentGreen : AppTheme.accentRed;
    final bgColor = isClear
        ? AppTheme.accentGreen.withOpacity(0.08)
        : AppTheme.accentRed.withOpacity(0.08);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: mainColor.withOpacity(0.3), width: 2),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isClear ? Icons.verified_rounded : Icons.warning_rounded,
                  color: mainColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Verification Result',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isClear
                          ? 'Condition Verified: Normal'
                          : 'Defect Detected: $formattedDefectType',
                      style: TextStyle(
                        color: mainColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryNavy.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  '$confidence%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 20),
          _buildResultRow(
            'Shipment ID',
            data['shipment_id']?.toString() ?? '-',
          ),
          _buildResultRow('Timestamp', data['timestamp']?.toString() ?? '-'),
          if (data['item_type'] != null &&
              data['item_type'].toString().isNotEmpty &&
              data['item_type'].toString() != 'null')
            _buildResultRow('Item Type', data['item_type'].toString()),
          if (data['damage_location'] != null &&
              data['damage_location'].toString().isNotEmpty &&
              data['damage_location'].toString() != 'null')
            _buildResultRow(
              'Damage Location',
              data['damage_location'].toString(),
            ),
          _buildResultRow(
            'Explanation',
            data['explanation']?.toString() ?? '-',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.security, size: 16, color: Color(0xFF64748B)),
                    SizedBox(width: 8),
                    Text(
                      'Blockchain Evidence Data',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildHashRow(
                  'Shipment Hash',
                  data['shipment_hash']?.toString() ?? '-',
                ),
                _buildHashRow(
                  'Evidence Hash',
                  data['evidence_hash']?.toString() ?? '-',
                ),
                _buildHashRow(
                  'Image Hash',
                  data['image_hash']?.toString() ?? '-',
                ),
                _buildResultRow(
                  'Chain ID',
                  data['defect_type_chain_id']?.toString() ?? '-',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black54)),
          ),
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
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              hash,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.blueGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
