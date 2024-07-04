import 'dart:async';
import 'dart:typed_data';

import 'package:datadashwallet/common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:mxc_logic/mxc_logic.dart';

import 'package:datadashwallet/core/core.dart';
import 'package:datadashwallet/features/settings/subfeatures/chain_configuration/domain/chain_configuration_use_case.dart';

import '../../bluetooth.dart';

final bluetoothServiceUUID =
    Guid.fromString('0000fff0-0000-1000-8000-00805f9b34fb');
final bluetoothCharacteristicUUID =
    Guid.fromString('0000fff6-0000-1000-8000-00805f9b34fb');
final bluetoothCharacteristicNotificationUUID =
    Guid.fromString('0000fff7-0000-1000-8000-00805f9b34fb');

class BlueberryRingUseCase extends ReactiveUseCase {
  BlueberryRingUseCase(this._repository, this._chainConfigurationUseCase,
      this._bluetoothUseCase) {
    // initBlueberryRingUseCase();
  }

  final Web3Repository _repository;
  final ChainConfigurationUseCase _chainConfigurationUseCase;
  final BluetoothUseCase _bluetoothUseCase;


  late final ValueStream<ScanResult?> selectedBlueberryRing = reactive(null);
  late final ValueStream<BluetoothCharacteristic?> blueberryRingCharacteristic =
      reactive(null);
  late final ValueStream<BluetoothCharacteristic?>
      blueberryRinCharacteristicNotifications = reactive(null);

  late final ValueStream<BluetoothAdapterState> bluetoothStatus =
      reactive(BluetoothAdapterState.off);

  //   if (state.selectedScanResult != null) {
  //   responseDevice = BluetoothDevice.getBluetoothDeviceFromScanResult(
  //       state.selectedScanResult!);
  // }

  void initBlueberryRingSelectedActions() {
    selectedBlueberryRing.listen((event) {
      if (event != null) {
        // Blueberry ring is selected
      }
    });
  }

  Future<void> getBlueberryRingContextless() async {
    // if (bluetoothStatus.value == BluetoothAdapterState.off || bluetoothStatus.value = BluetoothAdapterState.unauthorized)
    // TODO: bluetooth should be on before bg notifications
    // TODO: We will need te user to select which blueberry ring wants to get notificaitons from
    _bluetoothUseCase.startScanning(
      withServices: [bluetoothServiceUUID],
    );

    await Future.delayed(const Duration(seconds: 2), () async {
      final scanResults = _bluetoothUseCase.scanResults.value;
      if (scanResults.isNotEmpty) {
        // only one scan results
        final scanResult = scanResults.first;
        update(selectedBlueberryRing, scanResult);
      } else {
        throw 'Error: Unable to locate blueberry ring';
      }
    });

    _bluetoothUseCase.stopScanner();
  }

  // Sets the selectedBlueberryRing
  Future<void> getBlueberryRingsNearby(BuildContext context) async {
    _bluetoothUseCase.startScanning(
      withServices: [bluetoothServiceUUID],
    );

    await Future.delayed(const Duration(seconds: 3), () async {
      final scanResults = _bluetoothUseCase.scanResults.value;
      if (scanResults.length > 1 || scanResults.isEmpty) {
        // We need to let the user to choose If two or more devices of rings are available and even If empty maybe let the user to wait
        final scanResult = await showBlueberryRingsBottomSheet(
          context,
        );
        if (scanResult != null) {
          update(selectedBlueberryRing, scanResult);
        }
      } else {
        // only one scan results
        final scanResult = scanResults.first;
        update(selectedBlueberryRing, scanResult);
      }
    });

    _bluetoothUseCase.stopScanner();
  }

  Future<void> connectToBlueberryRing() async {
    await selectedBlueberryRing.value!.device.connect();
  }

  Future<BluetoothService> getBlueberryRingBluetoothService() async {
    return await _getBlueberryRingPrimaryService(bluetoothServiceUUID);
  }

  /// This function will check the blueberry ring, connection 
  Future<T> checkEstablishment<T>(Future<T> Function() func) async {
    final isBlueberryRingAvailable = selectedBlueberryRing.value != null;

    if (!isBlueberryRingAvailable) {
      await getBlueberryRingContextless();
    }

    bool isBlueberryRingConnected =
        selectedBlueberryRing.value?.device.isConnected ?? false;

    if (!isBlueberryRingConnected) {
      await selectedBlueberryRing.value?.device.connect();
      isBlueberryRingConnected =
          selectedBlueberryRing.value?.device.isConnected ?? false;
      if (!isBlueberryRingConnected) {
        throw 'Error: Unable to connect to the bluetooth device';
      }
    }

    final isBlueberryRingCharacteristicAvailable = blueberryRingCharacteristic.value != null;
    if (!isBlueberryRingCharacteristicAvailable) {
      await getBlueberryRingCharacteristic();
    }

    return await func();
  }

  Future<int> readLevel() async {
    final command = BlueberryCommands.readLevel();
    await blueberryRingCharacteristic.value?.write(command);
    final value = await blueberryRingCharacteristic.value?.read();
    return BlueberryResolves.readLevel(Uint8List.fromList(value!));
  }

  Future<String> readVersion() async {
    final command = BlueberryCommands.readVersion();
    await blueberryRingCharacteristic.value?.write(command);
    final value = await blueberryRingCharacteristic.value?.read();
    return BlueberryResolves.readVersion(Uint8List.fromList(value!));
  }

  Future<Uint8List> readTime() async {
    final command = BlueberryCommands.readTime();
    await blueberryRingCharacteristic.value?.write(command);
    final value = await blueberryRingCharacteristic.value?.read();
    return BlueberryResolves.readTime(Uint8List.fromList(value!));
  }

  Future<List<PeriodicSleepData>> readSleep() async {
    final command = BlueberryCommands.readSleep();
    await blueberryRingCharacteristic.value?.write(command);
    final value = await blueberryRingCharacteristic.value?.read();
    return BlueberryResolves.readSleep(Uint8List.fromList(value!));
  }

  Future<List<BloodOxygensData>> readBloodOxygens() async {
    final command = BlueberryCommands.readBloodOxygens();
    await blueberryRingCharacteristic.value?.write(command);
    final value = await blueberryRingCharacteristic.value?.read();
    return BlueberryResolves.readBloodOxygens(Uint8List.fromList(value!));
  }

  Future<List<StepsData>> readSteps() async {
    final command = BlueberryCommands.readSteps();
    await blueberryRingCharacteristic.value?.write(command);
    final value = await blueberryRingCharacteristic.value?.read();
    return BlueberryResolves.readSteps(Uint8List.fromList(value!));
  }

  Future<List<HeartRateData>> readHeartRate() async {
    final command = BlueberryCommands.readHeartRates();
    await blueberryRingCharacteristic.value?.write(command);
    final value = await blueberryRingCharacteristic.value?.read();
    return BlueberryResolves.readHeartRates(Uint8List.fromList(value!));
  }

  Future<BluetoothCharacteristic> getBlueberryRingCharacteristic() async {
    final service = await getBlueberryRingBluetoothService();
    final resp = await _getBlueberryRingCharacteristic(
        service, bluetoothCharacteristicUUID);
    update(blueberryRingCharacteristic, resp);
    return resp;
  }

  Future<BluetoothCharacteristic>
      getBlueberryRingCharacteristicNotifications() async {
    final service = await getBlueberryRingBluetoothService();
    final resp = await _getBlueberryRingCharacteristic(
        service, bluetoothCharacteristicNotificationUUID);
    update(blueberryRinCharacteristicNotifications, resp);
    return resp;
  }

  Future<void> startBlueberryRingCharacteristicNotifications() async {
    final characteristicNotifications =
        await getBlueberryRingCharacteristicNotifications();
    await characteristicNotifications.setNotifyValue(true);
    characteristicNotifications.onValueReceived.listen((event) {});
    final value = characteristicNotifications.read();
  }

  Future<BluetoothService> _getBlueberryRingPrimaryService(
    Guid serviceUUID,
  ) async {
    return await BluePlusBluetoothUtils.getPrimaryService(
      selectedBlueberryRing.value!,
      serviceUUID,
    );
  }

  Future<BluetoothCharacteristic> _getBlueberryRingCharacteristic(
    BluetoothService service,
    Guid characteristicUUID,
  ) async {
    return BluePlusBluetoothUtils.getCharacteristicWithService(
      service,
      characteristicUUID,
    );
  }
}
