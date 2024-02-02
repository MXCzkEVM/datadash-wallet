import 'package:background_fetch/background_fetch.dart';
import 'package:datadashwallet/core/core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mxc_logic/mxc_logic.dart';

class NotificationsService {
  @pragma(
      'vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
  static void callbackDispatcher(HeadlessTask task) async {
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
  static void callbackDispatcherForeGround(String taskId) async {
    try {
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
      final expectedEpochOccurrence =
          periodicalCallData.expectedEpochOccurrence;
      final expectedEpochOccurrenceEnabled =
          periodicalCallData.expectedEpochOccurrenceEnabled;
      final serviceEnabled = periodicalCallData.serviceEnabled;

      // Make sure user is logged in
      if (isLoggedIn && Config.isMxcChains(chainId) && serviceEnabled) {
        AXSNotification().setupFlutterNotifications(shouldInitFirebase: false);

        if (lowBalanceLimitEnabled) {
          await backgroundFetchConfigUseCase.checkLowBalance(
              account!, lowBalanceLimit);
        }

        if (expectedTransactionFeeEnabled) {
          await backgroundFetchConfigUseCase
              .checkTransactionFee(expectedTransactionFee);
        }

        if (expectedEpochOccurrenceEnabled) {
          periodicalCallData =
              await backgroundFetchConfigUseCase.checkEpochOccur(
                  periodicalCallData,
                  lastEpoch,
                  expectedEpochOccurrence,
                  chainId);
        }

        backgroundFetchConfigUseCase.updateItem(periodicalCallData);
        BackgroundFetch.finish(taskId);
      } else {
        // terminate background fetch
        BackgroundFetch.stop(taskId);
      }
    } catch (e) {
      BackgroundFetch.finish(taskId);
    }
  }
}