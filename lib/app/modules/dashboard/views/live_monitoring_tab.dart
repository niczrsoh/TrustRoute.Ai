import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/dashboard_controller.dart';

class LiveMonitoringTab extends GetView<DashboardController> {
  const LiveMonitoringTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Obx(() {
          final filter = controller.selectedLiveShipment.value;
          final shipmentsToDisplay = filter == 'All'
              ? controller.liveShipments.values.map((rx) => rx.value).toList()
              : [controller.liveShipments[filter]!.value];

          return FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(15.0, 105.0), // Center roughly on SE Asia
              initialZoom: 4.0, 
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.trust_route',
              ),
              PolylineLayer(
                polylines: shipmentsToDisplay.map((s) => Polyline(
                  points: s.route,
                  color: s.color.withOpacity(0.5),
                  strokeWidth: 4.0,
                  useStrokeWidthInMeter: true,
                  gradientColors: [s.color, s.color, s.color],
                )).toList(),
              ),
              MarkerLayer(
                markers: [
                  // Ports for all displayed shipments
                  ...shipmentsToDisplay.expand((s) => [
                    Marker(point: s.route.first, width: 30, height: 30, child: Icon(Icons.location_city, color: s.color)),
                    Marker(point: s.route.last, width: 30, height: 30, child: Icon(Icons.flag, color: s.color)),
                  ]),
                  // Ships
                  ...shipmentsToDisplay.map((s) => Marker(
                    point: s.currentLocation,
                    width: 60, height: 60,
                    child: Icon(Icons.directions_boat, color: s.color, size: 40),
                  )),
                ],
              ),
            ],
          );
        }),
        
        // Filter Dropdown Overlay
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Obx(() => DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: controller.selectedLiveShipment.value,
                items: ['All', ...controller.liveShipments.keys].map((String id) {
                  return DropdownMenuItem(
                    value: id,
                    child: Row(
                      children: [
                        if (id != 'All') Icon(Icons.circle, color: controller.liveShipments[id]!.value.color, size: 12),
                        if (id != 'All') const SizedBox(width: 8),
                        Text(id == 'All' ? 'All Shipments' : 'Shipment: $id', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: controller.updateLiveShipmentFilter,
              ),
            )),
          ),
        ),

        // Damage Alert Overlay
        Obx(() {
          if (controller.hasDamageAlert.value) {
            return Positioned(
              top: 70,
              left: 20,
              right: 20,
              child: _BlinkingWarningAlert(
                onResolve: controller.resolveDamageAlert,
              ),
            );
          }
          return const SizedBox.shrink();
        }),

        // Manual trigger for demo purposes
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            heroTag: 'simulate_damage',
            backgroundColor: Colors.red,
            onPressed: controller.triggerDamageAlert,
            child: const Icon(Icons.warning, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _BlinkingWarningAlert extends StatefulWidget {
  final VoidCallback onResolve;
  const _BlinkingWarningAlert({Key? key, required this.onResolve}) : super(key: key);

  @override
  __BlinkingWarningAlertState createState() => __BlinkingWarningAlertState();
}

class __BlinkingWarningAlertState extends State<_BlinkingWarningAlert> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'DAMAGE ALERT: THAILAND PORT',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Container seal broken. Reporting defect...',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: widget.onResolve,
            ),
          ],
        ),
      ),
    );
  }
}
