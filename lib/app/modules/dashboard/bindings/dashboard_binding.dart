import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../defect_report/controllers/defect_report_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(
      () => DashboardController(),
    );
    Get.lazyPut<DefectReportController>(
      () => DefectReportController(),
    );
  }
}
