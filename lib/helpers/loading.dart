import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class Loading {
  Loading() {
    EasyLoading.instance
      ..displayDuration = const Duration(milliseconds: 2000)
      // ..indicatorType = EasyLoadingIndicatorType.cubeGrid
      ..indicatorType = EasyLoadingIndicatorType.ripple
      ..contentPadding = const EdgeInsets.all(15)
      ..loadingStyle = EasyLoadingStyle.custom
      ..indicatorSize = 40
      ..lineWidth = 2
      ..radius = 15
      ..backgroundColor = Colors.blue
      ..indicatorColor = Colors.white
      ..progressColor = Colors.white
      ..textColor = Colors.white
      ..maskColor = Colors.transparent
      ..maskType = EasyLoadingMaskType.custom
      ..userInteractions = true
      ..dismissOnTap = false;
  }

  static void show([String? text]) {
    EasyLoading.instance.userInteractions = false;
    EasyLoading.show(status: text);
  }

  static void toast({
    required String text,
    Duration? duration,
  }) {
    EasyLoading.showToast(
      text,
      dismissOnTap: true,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  static void dismiss() {
    EasyLoading.instance.userInteractions = true;
    EasyLoading.dismiss();
  }
}
