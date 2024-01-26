import 'package:background_fetch/background_fetch.dart';
import 'package:datadashwallet/core/core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mxc_logic/mxc_logic.dart';

class DAppHooksService {
  @pragma(
      'vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
  static void dappHooksServiceCallBackDispatcher(HeadlessTask task) async {
    String taskId = task.taskId;
    bool isTimeout = task.timeout;
    if (isTimeout) {
      // This task has exceeded its allowed running-time.
      // You must stop what you're doing and immediately .finish(taskId)
      print("[BackgroundFetch] Headless task timed-out: $taskId");
      BackgroundFetch.finish(taskId);
      return;
    }
    dappHooksServiceCallBackDispatcherForeground(taskId);
  }

  static void dappHooksServiceCallBackDispatcherForeground(
      String taskId) async {
    try {
      await loadProviders();

      final container = ProviderContainer();
      final authUseCase = container.read(authUseCaseProvider);
      final chainConfigurationUseCase =
          container.read(chainConfigurationUseCaseProvider);
      final accountUseCase = container.read(accountUseCaseProvider);
      // final backgroundFetchConfigUseCase =
      //     container.read(backgroundFetchConfigUseCaseProvider);
      final dAppHooksUseCase = container.read(dAppHooksUseCaseProvider);

      final selectedNetwork =
          chainConfigurationUseCase.getCurrentNetworkWithoutRefresh();
      DAppHooksModel dappHooksData = dAppHooksUseCase.dappHooksData.value;
      final chainId = selectedNetwork.chainId;

      final isLoggedIn = authUseCase.loggedIn;
      final account = accountUseCase.account.value;
      final serviceEnabled = dappHooksData.enabled;
      final wifiHooksEnabled = dappHooksData.wifiHooks.enabled;

      // Make sure user is logged in
      if (isLoggedIn && Config.isMxcChains(chainId) && serviceEnabled) {
        AXSNotification().setupFlutterNotifications(shouldInitFirebase: false);

        if (wifiHooksEnabled) {
          await dAppHooksUseCase.sendWifiInfo(
            account!,
          );
        }

        dAppHooksUseCase.updateItem(dappHooksData);
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
