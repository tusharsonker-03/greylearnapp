import 'package:flutter/foundation.dart';

class DeepLinkGate {
  // true => deep link ne control le liya; Splash/auto-nav ko skip/cancel karo
  static final ValueNotifier<bool> tookControl = ValueNotifier<bool>(false);

  static void markHandled() {
    if (!tookControl.value) tookControl.value = true;
  }
}
