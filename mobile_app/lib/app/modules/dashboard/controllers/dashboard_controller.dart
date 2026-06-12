import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class LiveShipment {
  final String id;
  final List<LatLng> route;
  final Color color;
  final double speed;
  int currentSegment;
  double segmentProgress;
  LatLng currentLocation;

  LiveShipment({
    required this.id,
    required this.route,
    required this.color,
    required this.speed,
    this.currentSegment = 0,
    this.segmentProgress = 0.0,
  }) : currentLocation = route.first;
}

class DefectRecord {
  final String id;
  final String title;
  final String status;
  final DateTime date;
  final String severity;
  final String shipmentId;
  final String assetId;
  final String description;
  final String locationName;
  final double latitude;
  final double longitude;
  final String shipmentHash;
  final String evidenceHash;

  DefectRecord({
    required this.id,
    required this.title,
    required this.status,
    required this.date,
    required this.severity,
    required this.shipmentId,
    required this.assetId,
    this.description = 'Detailed description of the issue encountered during transit.',
    this.locationName = 'Unknown Location',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.shipmentHash = '',
    this.evidenceHash = '',
  });

  factory DefectRecord.fromJson(Map<String, dynamic> json) {
    String type = json['defect_type']?.toString() ?? 'unknown';
    String title = type.isNotEmpty ? type[0].toUpperCase() + type.substring(1) : 'Unknown';
    if (title.toLowerCase() == 'normal') {
      title = 'Normal Condition';
    } else {
      title = '$title Detected';
    }

    String severity = 'Low';
    if (type.toLowerCase() == 'crack') severity = 'Critical';
    else if (type.toLowerCase() == 'dent') severity = 'Medium';
    else if (type.toLowerCase() == 'leakage') severity = 'High';

    return DefectRecord(
      id: 'DEF-${json['id']}',
      title: title,
      status: 'Pending', // Default
      date: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      severity: severity,
      shipmentId: json['shipment_id']?.toString() ?? 'Unknown',
      assetId: (json['item_type'] != null && json['item_type'].toString().isNotEmpty && json['item_type'].toString() != 'null') ? json['item_type'].toString() : 'ASSET-204-X (Default)',
      description: json['explanation']?.toString() ?? 'No description provided.',
      locationName: (json['damage_location'] != null && json['damage_location'].toString().isNotEmpty && json['damage_location'].toString() != 'null') ? json['damage_location'].toString() : 'Warehouse B, Port Klang',
      latitude: 3.0014,
      longitude: 101.3934,
      shipmentHash: json['shipment_hash']?.toString() ?? '',
      evidenceHash: json['evidence_hash']?.toString() ?? '',
    );
  }
}

class BlockchainEvent {
  final String title;
  final String subtitle;
  final String date;
  final String hash;
  final String statusColor; // 'blue', 'red', 'green', 'grey'
  final bool isCompleted;

  BlockchainEvent({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.hash,
    required this.statusColor,
    this.isCompleted = true,
  });
}

class BlockchainShipment {
  final String shipmentId;
  final String assetId;
  final String mainTxHash;
  final List<BlockchainEvent> events;

  BlockchainShipment({
    required this.shipmentId,
    required this.assetId,
    required this.mainTxHash,
    required this.events,
  });
}

class DashboardController extends GetxController {
  // Bottom navigation state
  final selectedIndex = 0.obs;

  void changeTabIndex(int index) {
    selectedIndex.value = index;
  }

  // Live Monitoring State
  final selectedLiveShipment = 'All'.obs;

  // Global route definitions
  static const routeJapanToKlang = [
    LatLng(35.4437, 139.6380), // Yokohama, Japan
    LatLng(25.0, 122.0),       // East China Sea (Waypoint)
    LatLng(13.0805, 100.8872), // Laem Chabang, Thailand
    LatLng(6.0, 102.5),        // Gulf of Thailand (Waypoint)
    LatLng(3.0014, 101.3934),  // Port Klang, Malaysia
  ];

  static const routeChinaToSingapore = [
    LatLng(31.2304, 121.4737), // Shanghai, China
    LatLng(24.0, 119.0),       // Taiwan Strait (Waypoint)
    LatLng(10.7626, 106.6601), // Ho Chi Minh, Vietnam
    LatLng(1.3521, 103.8198),  // Singapore
  ];

  static const routeIndiaToKlang = [
    LatLng(18.9220, 72.8347), // Mumbai, India
    LatLng(6.9271, 79.8612),  // Colombo, Sri Lanka
    LatLng(5.0, 95.0),        // Andaman Sea (Waypoint)
    LatLng(3.0014, 101.3934), // Port Klang, Malaysia
  ];

  final liveShipments = <String, Rx<LiveShipment>>{
    'SHP-99201': LiveShipment(id: 'SHP-99201', route: routeJapanToKlang, color: Colors.blue, speed: 0.02).obs,
    'SHP-99180': LiveShipment(id: 'SHP-99180', route: routeChinaToSingapore, color: Colors.orange, speed: 0.015).obs,
    'SHP-99155': LiveShipment(id: 'SHP-99155', route: routeIndiaToKlang, color: Colors.purple, speed: 0.025).obs,
  };

  final hasDamageAlert = false.obs;
  Timer? _locationTimer;

  @override
  void onInit() {
    super.onInit();
    _startLocationSimulation();
    checkBackendHealth();
    fetchReports();
  }

  String get baseUrl {
    return Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://127.0.0.1:8000';
  }

  Future<void> checkBackendHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      if (response.statusCode == 200) {
        print('Backend is healthy: ${response.body}');
      }
    } catch (e) {
      print('Backend health check failed: $e');
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String hour = date.hour > 12 ? '${date.hour - 12}' : (date.hour == 0 ? '12' : '${date.hour}');
    String min = date.minute.toString().padLeft(2, '0');
    String amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} - $hour:$min $amPm';
  }

  Future<void> fetchReports() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/reports'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        recentDefects.value = data.map((json) => DefectRecord.fromJson(json)).toList();
        
        totalDefects.value = recentDefects.length;
        pendingDefects.value = recentDefects.where((d) => d.status == 'Pending').length;
        resolvedDefects.value = recentDefects.where((d) => d.status == 'Resolved').length;

        // Build dynamic blockchain data from the reports
        final Map<String, BlockchainShipment> newBlockchainData = {};
        final Set<String> newAvailableShipments = {};
        
        final grouped = <String, List<DefectRecord>>{};
        for (var defect in recentDefects) {
          grouped.putIfAbsent(defect.shipmentId, () => []).add(defect);
        }
        
        for (var entry in grouped.entries) {
          final shipmentId = entry.key;
          final defects = entry.value;
          defects.sort((a, b) => a.date.compareTo(b.date)); // Sort chronologically
          
          final assetId = defects.first.assetId;
          final mainTxHash = '0xd2519218d34eb35c49fa00d737299af689025e70ed0d776d34157cfa188b5671';
          
          final events = <BlockchainEvent>[];
          // Initial event
          events.add(BlockchainEvent(
            title: 'Initial Record Created',
            subtitle: 'Origin Port, Smart Contract Deployed',
            date: _formatDate(defects.first.date.subtract(const Duration(minutes: 30))),
            hash: mainTxHash,
            statusColor: 'blue',
          ));
          
          for (var defect in defects) {
             String color = 'red';
             if (defect.status == 'Resolved') color = 'green';
             else if (defect.severity == 'Low') color = 'orange';

             String subtitle = defect.description.length > 40 
                ? '${defect.description.substring(0, 40)}...' 
                : defect.description;

             events.add(BlockchainEvent(
               title: defect.title,
               subtitle: subtitle,
               date: _formatDate(defect.date),
               hash: defect.evidenceHash.isNotEmpty ? defect.evidenceHash : '0x...',
               statusColor: color,
             ));
          }
          
          events.add(BlockchainEvent(
            title: 'Arriving Record (Pending)',
            subtitle: 'Destination Port',
            date: 'Awaiting Arrival',
            hash: 'Pending...',
            statusColor: 'grey',
            isCompleted: false,
          ));
          
          newBlockchainData[shipmentId] = BlockchainShipment(
            shipmentId: shipmentId,
            assetId: assetId,
            mainTxHash: mainTxHash,
            events: events,
          );
          newAvailableShipments.add(shipmentId);
        }
        
        blockchainData.value = newBlockchainData;
        availableShipments.value = newAvailableShipments.toList();
        
        if (availableShipments.isNotEmpty && !availableShipments.contains(selectedBlockchainShipment.value)) {
          selectedBlockchainShipment.value = availableShipments.first;
        }
      } else {
        print('Error fetching reports: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to fetch reports: $e');
    }
  }

  @override
  void onClose() {
    _locationTimer?.cancel();
    super.onClose();
  }

  void _startLocationSimulation() {
    _locationTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      for (var shipmentRx in liveShipments.values) {
        final shipment = shipmentRx.value;
        if (shipment.currentSegment >= shipment.route.length - 1) {
          // Loop the simulation for demo
          shipment.currentSegment = 0;
          shipment.segmentProgress = 0.0;
          if (shipment.id == 'SHP-99201') hasDamageAlert.value = false;
          shipmentRx.refresh();
          continue;
        }

        final start = shipment.route[shipment.currentSegment];
        final end = shipment.route[shipment.currentSegment + 1];

        shipment.segmentProgress += shipment.speed;

        if (shipment.segmentProgress >= 1.0) {
          shipment.currentSegment++;
          shipment.segmentProgress = 0.0;

          // Trigger alert for Japan route at Thailand (segment 2)
          if (shipment.id == 'SHP-99201' && shipment.currentSegment == 2 && !hasDamageAlert.value) {
            triggerDamageAlert();
          }
        } else {
          // Interpolate
          final lat = start.latitude + (end.latitude - start.latitude) * shipment.segmentProgress;
          final lng = start.longitude + (end.longitude - start.longitude) * shipment.segmentProgress;
          shipment.currentLocation = LatLng(lat, lng);
        }
        shipmentRx.refresh();
      }
    });
  }

  void updateLiveShipmentFilter(String? shipmentId) {
    if (shipmentId != null) {
      selectedLiveShipment.value = shipmentId;
    }
  }

  void triggerDamageAlert() {
    hasDamageAlert.value = true;
  }

  void resolveDamageAlert() {
    hasDamageAlert.value = false;
  }

  // Blockchain Tab State
  final availableShipments = <String>[].obs;
  final selectedBlockchainShipment = ''.obs;

  void updateBlockchainShipment(String? shipmentId) {
    if (shipmentId != null) {
      selectedBlockchainShipment.value = shipmentId;
    }
  }

  final blockchainData = <String, BlockchainShipment>{}.obs;

  // Dummy data for statistics
  final totalDefects = 156.obs;
  final pendingDefects = 23.obs;
  final resolvedDefects = 133.obs;

  // Dummy data for chart (defects per month)
  final monthlyDefects = <double>[12, 19, 15, 25, 22, 30].obs;

  // Recent history fetched from API
  final recentDefects = <DefectRecord>[].obs;

  // Search, Filter, Sort State
  final searchQuery = ''.obs;
  final statusFilter = 'All'.obs;
  final sortOption = 'Newest'.obs;
  final historyShipmentFilter = 'All'.obs;

  void updateSearchQuery(String query) => searchQuery.value = query;
  void updateStatusFilter(String status) => statusFilter.value = status;
  void updateSortOption(String sort) => sortOption.value = sort;
  void updateHistoryShipmentFilter(String shipmentId) => historyShipmentFilter.value = shipmentId;

  List<DefectRecord> get filteredAndSortedDefects {
    var result = recentDefects.toList();

    // 1. Search
    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      result = result.where((d) =>
          d.id.toLowerCase().contains(q) ||
          d.title.toLowerCase().contains(q)).toList();
    }

    // 2. Status Filter
    if (statusFilter.value != 'All') {
      result = result.where((d) => d.status == statusFilter.value).toList();
    }

    // 3. Shipment Filter
    if (historyShipmentFilter.value != 'All') {
      result = result.where((d) => d.shipmentId == historyShipmentFilter.value).toList();
    }

    // 4. Sort
    if (sortOption.value == 'Newest') {
      result.sort((a, b) => b.date.compareTo(a.date));
    } else if (sortOption.value == 'Oldest') {
      result.sort((a, b) => a.date.compareTo(b.date));
    } else if (sortOption.value == 'Severity (High-Low)') {
      int severityValue(String s) {
        switch (s) {
          case 'Critical': return 4;
          case 'High': return 3;
          case 'Medium': return 2;
          case 'Low': return 1;
          default: return 0;
        }
      }
      result.sort((a, b) => severityValue(b.severity).compareTo(severityValue(a.severity)));
    }

    return result;
  }
}
