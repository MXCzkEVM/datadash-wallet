import 'package:clipboard/clipboard.dart';
import 'package:datadashwallet/common/common.dart';
import 'package:datadashwallet/core/src/notification.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mxc_logic/mxc_logic.dart';

import 'firebase_options.dart';
export 'firebase_options.dart';

class AXSFireBase {
  static AXSNotification get axsNotification => AXSNotification();

  static String? firebaseToken;
  static int buildTap = 0;

  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    // If you're going to use other Firebase services in the background, such as Firestore,
    // make sure you call `initializeApp` before using other Firebase services.
    await Firebase.initializeApp(
        name: Config.appName, options: DefaultFirebaseOptions.currentPlatform);
    print(message.data);
    await axsNotification.setupFlutterNotifications();
    // Firebase triggers notifications Itself
    // axsNotification.showFlutterNotification(message);
    print('Handling a background message ${message.messageId}');
  }

  // Listening to the foreground messages
  static void _setupFirebaseMessagingForegroundHandler() async {
    firebaseToken = await FirebaseMessaging.instance.getToken();
    FirebaseMessaging.onMessage.listen(axsNotification.showFlutterNotification);
  }

  // It is assumed that all messages contain a data field with the key 'type'
  static Future<void> setupFirebaseMessageInteraction() async {
    // Get any messages which caused the application to open from
    // a terminated state.
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    // If the message also contains a data property with a "type" of "chat",
    // navigate to a chat screen
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Also handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  static void _handleMessage(RemoteMessage message) {
    // Check what is inside the message object
    RemoteNotification? notification = message.notification;
    //AndroidNotification? android = message.notification?.android;

    print("notification: $notification");
    print("message data: ${message.data}");
  }

  Future<void> setForegroundNotificationPresentationOptions() async {
    return await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Initializes firebaseMessageInteraction (For when user taps on notification) if user grants the permission, Otherwise the local notification & firebaseMessageInteraction are not going to be set.
  static Future<void> initLocalNotificationsAndListeners() async {
    final isPermissionGranted = await _initLocalNotifications();

    if (isPermissionGranted) {
      _setupFirebaseMessagingForegroundHandler();
      _setupBackgroundMessageListener();
    }
  }

  static void _setupBackgroundMessageListener() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Initializes local notifications if permission is granted, Otherwise the local notification is not going to be set.
  static Future<bool> _initLocalNotifications() async {
    final isGranted = await PermissionUtils.initNotificationPermission();
    if (isGranted) {
      axsNotification.setupFlutterNotifications();
    }
    return isGranted;
  }

  static void incrementBuildTap() {
    buildTap++;
    if (buildTap == 10) {
      FlutterClipboard.copy(firebaseToken ?? '');
      buildTap = 0;
    }
  }
}
