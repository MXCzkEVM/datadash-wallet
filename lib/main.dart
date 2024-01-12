import 'dart:async';
import 'dart:convert';
import 'package:datadashwallet/app/logger.dart';
import 'package:datadashwallet/common/common.dart';
import 'package:datadashwallet/core/core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:mxc_logic/mxc_logic.dart';
import 'package:http/http.dart';

import 'app/app.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  print(message.data);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AXSNotification().setupFlutterNotifications();
  // Firebase triggers notifications Itself
  // axsNotification.showFlutterNotification(message);
  print('Handling a background message ${message.messageId}');
}

@pragma(
    'vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
void callbackDispatcher(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    // This task has exceeded its allowed running-time.
    // You must stop what you're doing and immediately .finish(taskId)
    print("[BackgroundFetch] Headless task timed-out: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }
  callbackDispatcherForeGround(taskId);
}

// Foreground
void callbackDispatcherForeGround(String taskId) async {
  await loadProviders();

  final container = ProviderContainer();
  final authUseCase = container.read(authUseCaseProvider);
  final chainConfigurationUseCase =
      container.read(chainConfigurationUseCaseProvider);
  final accountUseCase = container.read(accountUseCaseProvider);
  final backgroundFetchConfigUseCase =
      container.read(backgroundFetchConfigUseCaseProvider);

  final selectedNetwork =
      chainConfigurationUseCase.getCurrentNetworkWithoutRefresh();
  PeriodicalCallData periodicalCallData =
      backgroundFetchConfigUseCase.periodicalCallData.value;
  final chainId = selectedNetwork.chainId;

  final isLoggedIn = authUseCase.loggedIn;
  final account = accountUseCase.account.value;
  final lowBalanceLimit = periodicalCallData.lowBalanceLimit;
  final expectedTransactionFee = periodicalCallData.expectedTransactionFee;
  final lowBalanceLimitEnabled = periodicalCallData.lowBalanceLimitEnabled;
  final expectedTransactionFeeEnabled =
      periodicalCallData.expectedTransactionFeeEnabled;
  final lastEpoch = periodicalCallData.lasEpoch;
  final expectedEpochOccurrence = periodicalCallData.expectedEpochOccurrence;
  final expectedEpochOccurrenceEnabled =
      periodicalCallData.expectedEpochOccurrenceEnabled;

  // Make sure user is logged in
  if (isLoggedIn && Config.isMxcChains(chainId)) {
    AXSNotification().setupFlutterNotifications(shouldInitFirebase: false);

    if (lowBalanceLimitEnabled) {
      backgroundFetchConfigUseCase.checkLowBalance(account!, lowBalanceLimit);
    }

    if (expectedTransactionFeeEnabled) {
      backgroundFetchConfigUseCase.checkTransactionFee(expectedTransactionFee);
    }

    if (expectedEpochOccurrenceEnabled) {
      periodicalCallData = await backgroundFetchConfigUseCase.checkEpochOccur(
          periodicalCallData, lastEpoch, expectedEpochOccurrence);
    }

    backgroundFetchConfigUseCase.updateItem(periodicalCallData);
  } else {
    // terminate background fetch
    BackgroundFetch.stop(taskId);
  }
  BackgroundFetch.finish(taskId);
}

void main() {
  var onError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    onError?.call(details);
    reportErrorAndLog(details);
  };

  runZoned(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      await dotenv.load(fileName: 'assets/.env');
      await initLogs();
      await loadProviders();

      final container = ProviderContainer();
      final authUseCase = container.read(authUseCaseProvider);
      final isLoggedIn = authUseCase.loggedIn;

      await Biometric.load();

      final appVersionUseCase = container.read(appVersionUseCaseProvider);
      await appVersionUseCase.checkLatestVersion();

      final initializationUseCase = container.read(chainsUseCaseProvider);
      initializationUseCase.updateChains();

      runApp(
        UncontrolledProviderScope(
          container: container,
          child: AxsWallet(
            isLoggedIn: isLoggedIn,
          ),
        ),
      );
    },
    zoneSpecification: ZoneSpecification(
      print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
        collectLog(line);
        parent.print(zone, line);
      },
      handleUncaughtError: (Zone self, ZoneDelegate parent, Zone zone,
          Object error, StackTrace stackTrace) {
        reportErrorAndLog(
            FlutterErrorDetails(exception: error, stack: stackTrace));
        parent.print(zone, '${error.toString()} $stackTrace');
      },
    ),
  );
}
