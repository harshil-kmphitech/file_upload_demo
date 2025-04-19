import 'dart:io';

import 'package:fluttertoast/fluttertoast.dart';

import 'package:file_upload_demo/helpers/all.dart';

class Utils {
  bool isValueEmpty(String? val) {
    if (val == null || val.isEmpty || val == "null" || val == "" || val == "NULL") {
      return true;
    } else {
      return false;
    }
  }

  void showToast({
    bool? isError,
    Color? textColor,
    Color? backgroundColor,
    required String message,
  }) {
    Fluttertoast.cancel();

    if (isError ?? false) {
      textColor = Colors.white;
      backgroundColor = Colors.grey;
    }

    Fluttertoast.showToast(
      msg: message,
      gravity: ToastGravity.BOTTOM,
      toastLength: Toast.LENGTH_LONG,
      textColor: textColor ?? Colors.white,
      backgroundColor: backgroundColor ?? Colors.blue,
      timeInSecForIosWeb: 3,
    );
  }

  String getDeviceType() => Platform.isAndroid ? "android" : "iOS";
}

void printSuccess(String text) {
  if (kDebugMode) {
    if (Platform.isAndroid) {
      debugPrint('\x1B[32m$text\x1B[0m');
    } else {
      debugPrint(text);
    }
  }
}

void printWarning(String text) {
  if (kDebugMode) {
    if (Platform.isAndroid) {
      debugPrint('\x1B[33m$text\x1B[0m');
    } else {
      debugPrint(text);
    }
  }
}

void printAction(String text) {
  if (kDebugMode) {
    if (Platform.isAndroid) {
      debugPrint('\x1B[94m$text\x1B[0m');
    } else {
      debugPrint(text);
    }
  }
}

void printError(String text) {
  if (kDebugMode) {
    if (Platform.isAndroid) {
      debugPrint('\x1B[91m$text\x1B[0m');
    } else {
      debugPrint(text);
    }
  }
}
