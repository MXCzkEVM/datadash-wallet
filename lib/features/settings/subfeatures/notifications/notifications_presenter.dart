import 'dart:io';
import 'package:app_settings/app_settings.dart';
import 'package:datadashwallet/common/common.dart';
import 'package:datadashwallet/features/settings/subfeatures/notifications/widgets/background_fetch_dialog.dart';
import 'package:datadashwallet/features/settings/subfeatures/notifications/widgets/bg_notifications_frequency_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:datadashwallet/core/core.dart';
import 'package:background_fetch/background_fetch.dart' as bgFetch;
import 'package:mxc_logic/mxc_logic.dart';
import '../../../../main.dart';
import 'notifications_state.dart';

final notificationsContainer =
    PresenterContainer<NotificationsPresenter, NotificationsState>(
        () => NotificationsPresenter());

class NotificationsPresenter extends CompletePresenter<NotificationsState>
    with WidgetsBindingObserver {
  NotificationsPresenter() : super(NotificationsState()) {
    WidgetsBinding.instance.addObserver(this);
  }

  late final backgroundFetchConfigUseCase =
      ref.read(backgroundFetchConfigUseCaseProvider);
  late final _chainConfigurationUseCase =
      ref.read(chainConfigurationUseCaseProvider);

  // this is used to show the bg fetch dialog
  bool noneEnabled = true;

  final TextEditingController lowBalanceController = TextEditingController();
  final TextEditingController transactionFeeController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    checkNotificationsStatus();

    listen(backgroundFetchConfigUseCase.periodicalCallData, (value) {
      checkPeriodicalCallDataChange(value);
    });

    listen(_chainConfigurationUseCase.selectedNetwork, (value) {
      notify(() => state.network = value);
    });

    lowBalanceController.addListener(onLowBalanceChange);
    transactionFeeController.addListener(onTransactionFeeChange);
  }

  void onLowBalanceChange() {
    state.formKey.currentState!.validate();
  }

  void onTransactionFeeChange() {
    state.formKey.currentState!.validate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // If user went to settings to change notifications state
    if (state == AppLifecycleState.resumed) {
      checkNotificationsStatus();
    }
  }

  void changeNotificationsState(bool shouldEnable) {
    if (shouldEnable) {
      turnNotificationsOn();
    } else {
      turnNotificationsOff();
    }
  }

  void turnNotificationsOn() async {
    final isGranted = await PermissionUtils.initNotificationPermission();
    if (isGranted) {
      // change state
      notify(() => state.isNotificationsEnabled = isGranted);
    } else {
      // Looks like the notification is blocked permanently
      // send to settings
      openNotificationSettings();
    }
  }

  void turnNotificationsOff() {
    openNotificationSettings();
  }

  void openNotificationSettings() {
    if (Platform.isAndroid) {
      AppSettings.openAppSettings(
          type: AppSettingsType.notification, asAnotherTask: false);
    } else {
      // IOS
      AppSettings.openAppSettings(
        type: AppSettingsType.settings,
      );
    }
  }

  void checkNotificationsStatus() async {
    final isGranted = await PermissionUtils.checkNotificationPermission();
    if (state.isNotificationsEnabled == false && isGranted == true) {
      await AXSFireBase.initializeFirebase();
      AXSFireBase.initLocalNotificationsAndListeners();
    }
    notify(() => state.isNotificationsEnabled = isGranted);
  }

  void enableLowBalanceLimit(bool value) {
    // showBackgroundFetchAlertDialog(context: context!);
    showBGNotificationsFrequencyDialog(context!,
        onTap: handleFrequencyChange,
        selectedFrequency: getPeriodicalCallDurationFromInt(
            state.periodicalCallData!.duration));
    // final newPeriodicalCallData =
    //     state.periodicalCallData!.copyWith(lowBalanceLimitEnabled: value);
    // backgroundFetchConfigUseCase.updateItem(newPeriodicalCallData);
  }

  void enableExpectedGasPrice(bool value) {
    final newPeriodicalCallData =
        state.periodicalCallData!.copyWith(expectedGasPriceEnabled: value);
    backgroundFetchConfigUseCase.updateItem(newPeriodicalCallData);
  }

  void enableExpectedEpochQuantity(bool value) {
    final newPeriodicalCallData = state.periodicalCallData!
        .copyWith(expectedEpochOccurrenceEnabled: value);
    backgroundFetchConfigUseCase.updateItem(newPeriodicalCallData);
  }

  void selectEpochOccur(int value) {
    final newPeriodicalCallData =
        state.periodicalCallData!.copyWith(expectedEpochOccurrence: value);
    backgroundFetchConfigUseCase.updateItem(newPeriodicalCallData);
  }

  void handleFrequencyChange(PeriodicalCallDuration duration) {
    final newPeriodicalCallData =
        state.periodicalCallData!.copyWith(duration: duration.toMinutes());
    backgroundFetchConfigUseCase.updateItem(newPeriodicalCallData);
  }

  void checkPeriodicalCallDataChange(
      PeriodicalCallData newPeriodicalCallData) async {
    bool newNoneEnabled =
        !(newPeriodicalCallData.expectedEpochOccurrenceEnabled ||
            newPeriodicalCallData.expectedGasPriceEnabled ||
            newPeriodicalCallData.lowBalanceLimitEnabled);

    if (state.periodicalCallData != null) {
      if (isServicesEnabledStatusChanged(
                  newPeriodicalCallData, state.periodicalCallData!) &&
              hasAnyServiceBeenEnabled(
                  newPeriodicalCallData, state.periodicalCallData!) ||
          hasDurationChanged(
              newPeriodicalCallData, state.periodicalCallData!)) {}

      // none enabled means stopped || was stopped
      if (newNoneEnabled == true) {
        await stopBGFetch();
      }
      // If none was enabled & now one is enabled => Start BG service
      // Other wise It was enabled so start BG service in case It's not running
      else if (noneEnabled == true && newNoneEnabled == false) {
        startBGFetch(newPeriodicalCallData.duration);
      }
    }
    noneEnabled = newNoneEnabled;
    notify(() => state.periodicalCallData = newPeriodicalCallData);
  }

  // Detect If change was about service enable status not amount change because amount changes won't effect the service & will be loaded from DB.
  bool isServicesEnabledStatusChanged(PeriodicalCallData newPeriodicalCallData,
      PeriodicalCallData periodicalCallData) {
    return newPeriodicalCallData.expectedGasPriceEnabled !=
            periodicalCallData.expectedGasPriceEnabled ||
        newPeriodicalCallData.lowBalanceLimitEnabled !=
            periodicalCallData.lowBalanceLimitEnabled ||
        newPeriodicalCallData.expectedEpochOccurrenceEnabled !=
            periodicalCallData.expectedEpochOccurrenceEnabled;
  }

  // There is a chance where user disables any service so in this case we don't want to run BG fetch service init again.
  bool hasAnyServiceBeenEnabled(PeriodicalCallData newPeriodicalCallData,
      PeriodicalCallData periodicalCallData) {
    return (newPeriodicalCallData.expectedGasPriceEnabled == true &&
            periodicalCallData.expectedGasPriceEnabled == false) &&
        (newPeriodicalCallData.lowBalanceLimitEnabled == true &&
            periodicalCallData.lowBalanceLimitEnabled == false) &&
        (newPeriodicalCallData.expectedEpochOccurrenceEnabled == true &&
            periodicalCallData.expectedEpochOccurrenceEnabled == false);
  }

  bool hasDurationChanged(PeriodicalCallData newPeriodicalCallData,
      PeriodicalCallData periodicalCallData) {
    return newPeriodicalCallData.duration != periodicalCallData.duration;
  }

  // delay is in minutes
  void startBGFetch(int delay) async {
    try {
      // Stop If any is running
      await stopBGFetch();

      final configurationState = await bgFetch.BackgroundFetch.configure(
          bgFetch.BackgroundFetchConfig(
              minimumFetchInterval: 15,
              stopOnTerminate: false,
              enableHeadless: true,
              startOnBoot: true,
              requiresBatteryNotLow: false,
              requiresCharging: false,
              requiresStorageNotLow: false,
              requiresDeviceIdle: false,
              requiredNetworkType: bgFetch.NetworkType.ANY),
          callbackDispatcherForeGround);
      // Android Only
      final backgroundFetchState =
          await bgFetch.BackgroundFetch.registerHeadlessTask(
              callbackDispatcher);

      final scheduleState =
          await bgFetch.BackgroundFetch.scheduleTask(bgFetch.TaskConfig(
        taskId: Config.axsPeriodicalTask,
        delay: delay * 60 * 1000,
        periodic: true,
        requiresNetworkConnectivity: true,
        startOnBoot: true,
        stopOnTerminate: false,
        requiredNetworkType: bgFetch.NetworkType.ANY,
      ));

      if (scheduleState &&
              configurationState == bgFetch.BackgroundFetch.STATUS_AVAILABLE ||
          configurationState == bgFetch.BackgroundFetch.STATUS_RESTRICTED &&
              (Platform.isAndroid ? backgroundFetchState : true)) {
        showBGFetchSuccessSnackBar();
      } else {
        showBGFetchFailureSnackBar();
      }
    } catch (e) {
      showBGFetchFailureSnackBar();
    }
  }

  Future<int> stopBGFetch() async {
    return await bgFetch.BackgroundFetch.stop(Config.axsPeriodicalTask);
  }

  void showBGFetchFailureSnackBar() {
    showSnackBar(
        context: context!,
        content: translate('unable_to_launch_background_notification_service')!,
        type: SnackBarType.fail);
  }

  void showBGFetchSuccessSnackBar() {
    showSnackBar(
        context: context!,
        content: translate(
            'Background_notifications_service_launched_successfully')!);
  }

  @override
  Future<void> dispose() {
    WidgetsBinding.instance.removeObserver(this);
    return super.dispose();
  }
}
