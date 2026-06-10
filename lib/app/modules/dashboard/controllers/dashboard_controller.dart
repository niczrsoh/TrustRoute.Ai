import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

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
  });
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
  final availableShipments = <String>['SHP-99201', 'SHP-99180', 'SHP-99155'].obs;
  final selectedBlockchainShipment = 'SHP-99201'.obs;

  void updateBlockchainShipment(String? shipmentId) {
    if (shipmentId != null) {
      selectedBlockchainShipment.value = shipmentId;
    }
  }

  final blockchainData = <String, BlockchainShipment>{
    'SHP-99201': BlockchainShipment(
      shipmentId: 'SHP-99201',
      assetId: 'CNT-5501X',
      mainTxHash: '0x7de6692666c01f2a9a1efa2bc9e0db4bb6f5add39dc53700a1f392a898bbef54',
      events: [
        BlockchainEvent(title: 'Initial Record Created', subtitle: 'Origin Port, Smart Contract Deployed', date: 'Jun 8, 2026 - 10:00 AM', hash: '0x1a2b...c3d4', statusColor: 'blue'),
        BlockchainEvent(title: 'Damaged Record (Defect)', subtitle: 'Transit Checkpoint - Container Seal Broken', date: 'Jun 10, 2026 - 01:15 PM', hash: '0x8f3c...9a12b', statusColor: 'red'),
        BlockchainEvent(title: 'Arriving Record (Pending)', subtitle: 'Destination Port', date: 'Awaiting Arrival', hash: 'Pending...', statusColor: 'grey', isCompleted: false),
      ],
    ),
    'SHP-99180': BlockchainShipment(
      shipmentId: 'SHP-99180',
      assetId: 'REF-3029B',
      mainTxHash: '0xabc1234567890def1234567890abcdef12345678',
      events: [
        BlockchainEvent(title: 'Initial Record Created', subtitle: 'Origin Port, Smart Contract Deployed', date: 'Jun 7, 2026 - 09:00 AM', hash: '0x99bb...11aa', statusColor: 'blue'),
        BlockchainEvent(title: 'Temperature Exceeded', subtitle: 'North-South Expressway KM 255', date: 'Jun 9, 2026 - 11:20 AM', hash: '0x44dd...22ee', statusColor: 'red'),
        BlockchainEvent(title: 'Resolved Record', subtitle: 'Maintenance Facility', date: 'Jun 9, 2026 - 04:00 PM', hash: '0x77ff...33cc', statusColor: 'green'),
        BlockchainEvent(title: 'Arrived', subtitle: 'Destination Port', date: 'Jun 10, 2026 - 08:00 AM', hash: '0x1122...3344', statusColor: 'blue'),
      ],
    ),
    'SHP-99155': BlockchainShipment(
      shipmentId: 'SHP-99155',
      assetId: 'PLT-8800A',
      mainTxHash: '0xdef1234567890abc1234567890def1234567890a',
      events: [
        BlockchainEvent(title: 'Initial Record Created', subtitle: 'Origin Port, Smart Contract Deployed', date: 'Jun 6, 2026 - 08:00 AM', hash: '0x1234...abcd', statusColor: 'blue'),
        BlockchainEvent(title: 'Packaging Damage', subtitle: 'Shah Alam Distribution Center', date: 'Jun 8, 2026 - 02:30 PM', hash: '0x5678...efgh', statusColor: 'red'),
        BlockchainEvent(title: 'Arriving Record (Pending)', subtitle: 'Destination Port', date: 'Awaiting Arrival', hash: 'Pending...', statusColor: 'grey', isCompleted: false),
      ],
    ),
  };

  // Dummy data for statistics
  final totalDefects = 156.obs;
  final pendingDefects = 23.obs;
  final resolvedDefects = 133.obs;

  // Dummy data for chart (defects per month)
  final monthlyDefects = <double>[12, 19, 15, 25, 22, 30].obs;

  // Dummy data for recent history
  final recentDefects = <DefectRecord>[
    DefectRecord(
      id: 'DEF-1042',
      title: 'Container Seal Broken',
      status: 'Pending',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      severity: 'High',
      shipmentId: 'SHP-99201',
      assetId: 'CNT-5501X',
      locationName: 'Port Klang Checkpoint Alpha',
      latitude: 3.0014,
      longitude: 101.3934,
    ),
    DefectRecord(
      id: 'DEF-1041',
      title: 'Temperature Exceeded Limit',
      status: 'Resolved',
      date: DateTime.now().subtract(const Duration(days: 1)),
      severity: 'Critical',
      shipmentId: 'SHP-99180',
      assetId: 'REF-3029B',
      locationName: 'North-South Expressway KM 255',
      latitude: 2.7663,
      longitude: 101.9546,
    ),
    DefectRecord(
      id: 'DEF-1040',
      title: 'Packaging Damage',
      status: 'Pending',
      date: DateTime.now().subtract(const Duration(days: 2)),
      severity: 'Medium',
      shipmentId: 'SHP-99155',
      assetId: 'PLT-8800A',
      locationName: 'Shah Alam Distribution Center',
      latitude: 3.0733,
      longitude: 101.5185,
    ),
    DefectRecord(
      id: 'DEF-1039',
      title: 'Missing Label',
      status: 'Resolved',
      date: DateTime.now().subtract(const Duration(days: 3)),
      severity: 'Low',
      shipmentId: 'SHP-99102',
      assetId: 'PLT-8805A',
      locationName: 'Penang Port Terminal',
      latitude: 5.4141,
      longitude: 100.3288,
    ),
  ].obs;

  // Search, Filter, Sort State
  final searchQuery = ''.obs;
  final statusFilter = 'All'.obs;
  final sortOption = 'Newest'.obs;

  void updateSearchQuery(String query) => searchQuery.value = query;
  void updateStatusFilter(String status) => statusFilter.value = status;
  void updateSortOption(String sort) => sortOption.value = sort;

  List<DefectRecord> get filteredAndSortedDefects {
    var result = recentDefects.toList();

    // 1. Search
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      result = result.where((defect) {
        return defect.title.toLowerCase().contains(query) ||
               defect.id.toLowerCase().contains(query) ||
               defect.shipmentId.toLowerCase().contains(query) ||
               defect.assetId.toLowerCase().contains(query);
      }).toList();
    }

    // 2. Filter by Status
    if (statusFilter.value != 'All') {
      result = result.where((defect) => defect.status == statusFilter.value).toList();
    }

    // 3. Sort
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
