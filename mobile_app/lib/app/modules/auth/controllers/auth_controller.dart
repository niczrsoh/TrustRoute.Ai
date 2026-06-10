import 'package:get/get.dart';

class AuthController extends GetxController {
  final isObscure = true.obs;
  final isLoading = false.obs;

  void togglePasswordVisibility() {
    isObscure.value = !isObscure.value;
  }

  void login() async {
    isLoading.value = true;
    // Mock API delay
    await Future.delayed(Duration(seconds: 2));
    isLoading.value = false;
    
    // Navigate to dashboard
    Get.offAllNamed('/dashboard');
  }
}
