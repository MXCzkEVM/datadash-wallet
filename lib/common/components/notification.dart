import 'package:datadashwallet/core/core.dart';

showNotification(String title, String? text) {
  MoonchainWalletNotification().showNotification(title, text);
}

showLowPriorityNotification(String title, String? text) {
  MoonchainWalletNotification().showLowPriorityNotification(title, text);
}
