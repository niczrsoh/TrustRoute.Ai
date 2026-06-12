import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trust_route/app/core/theme/app_theme.dart';
import '../controllers/dashboard_controller.dart';

class DefectDetailView extends StatelessWidget {
  final DefectRecord defect;

  const DefectDetailView({Key? key, required this.defect}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Defect Details',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 24),
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildImageGallery(),
            const SizedBox(height: 24),
            _buildBlockchainVerification(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    Color statusColor =
        defect.status == 'Resolved' ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              defect.status.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            defect.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            defect.id,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 32),
          _buildInfoRow('Date Reported', _formatDateFull(defect.date)),
          _buildInfoRow('Severity', defect.severity, isSeverity: true),
          _buildInfoRow(
              'Confidence', '${(defect.confidence * 100).toStringAsFixed(1)}%'),
          _buildInfoRow('Shipment ID', defect.shipmentId),
          _buildInfoRow('Asset ID', defect.assetId),
          _buildInfoRow('Location', defect.locationName),
          _buildInfoRow('Coordinates',
              '${defect.latitude.toStringAsFixed(4)}, ${defect.longitude.toStringAsFixed(4)}'),
          const SizedBox(height: 16),
          const Text(
            'Description',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            defect.description,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isSeverity = false}) {
    Color? valueColor;
    if (isSeverity) {
      switch (value) {
        case 'Critical':
          valueColor = Colors.red;
          break;
        case 'High':
          valueColor = Colors.orange;
          break;
        case 'Medium':
          valueColor = Colors.amber;
          break;
        default:
          valueColor = Colors.blue;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Evidence Images',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return Container(
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Center(
                  child: Icon(Icons.image, size: 40, color: Colors.grey),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBlockchainVerification() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey.shade800, Colors.blueGrey.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.verified_user, color: Colors.greenAccent),
              SizedBox(width: 8),
              Text(
                'Blockchain Verified',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildHashRow('Status', defect.blockchainStatus),
          const SizedBox(height: 8),
          _buildHashRow(
              'Tx Hash',
              defect.blockchainTxHash.isNotEmpty &&
                      defect.blockchainTxHash != 'null'
                  ? defect.blockchainTxHash
                  : 'Pending'),
          const SizedBox(height: 8),
          _buildHashRow('Evidence',
              defect.evidenceHash.isNotEmpty ? defect.evidenceHash : 'Pending'),
          if (defect.blockchainError.isNotEmpty &&
              defect.blockchainError != 'null') ...[
            const SizedBox(height: 8),
            _buildHashRow('Error', defect.blockchainError),
          ],
        ],
      ),
    );
  }

  Widget _buildHashRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            softWrap: true,
            style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 14,
                fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  String _formatDateFull(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
