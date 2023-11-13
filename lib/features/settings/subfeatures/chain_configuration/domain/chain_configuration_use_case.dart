import 'package:datadashwallet/common/common.dart';
import 'package:datadashwallet/core/core.dart';
import 'package:mxc_logic/mxc_logic.dart';
import 'package:url_launcher/url_launcher.dart';

import 'chain_configuration_repository.dart';

class ChainConfigurationUseCase extends ReactiveUseCase {
  ChainConfigurationUseCase(
    this._repository,
  );

  final ChainConfigurationRepository _repository;

  late final ValueStream<List<Network>> networks =
      reactiveField(_repository.networks);

  late final ValueStream<String?> selectedIpfsGateWay =
      reactiveField(_repository.selectedIpfsGateWay);

  late final ValueStream<List<String>> ipfsGateWayList = reactive([]);

  late final ValueStream<Network?> selectedNetwork = reactive();

  late final ValueStream<Network?> selectedNetworkForDetails = reactive();

  List<Network> getNetworks() => _repository.items;

  String? getIpfsGateWay() => _repository.selectedIpfsGatewayItem;

  void addItem(Network network) {
    _repository.addItem(network);
    update(networks, _repository.items);
  }

  void updateItem(Network network, int index) {
    _repository.updateItem(network, index);
    update(networks, _repository.items);
  }

  void addItems(List<Network> items) {
    _repository.addItems(items);
    update(networks, _repository.items);
  }

  void removeItem(Network network) {
    _repository.removeItem(network);
    update(networks, _repository.items);
  }

  /// If return true then the enabled network props changed
  Network? updateNetworks(List<Network> newNetworkList) {
    Network? selectedNetwork;

    for (int i = 0; i < _repository.items.length; i++) {
      final repoItem = _repository.items[i];

      final index = newNetworkList.indexWhere(
        (element) => element.chainId == repoItem.chainId,
      );

      if (index != -1) {
        // matches
        final toCompareItem = newNetworkList.elementAt(index);
        if (!repoItem.compareWithOther(toCompareItem)) {
          final mergedItem = repoItem.copyWithOther(toCompareItem);
          if (repoItem.enabled) {
            updateSelectedNetwork(mergedItem);
            selectedNetwork = mergedItem;
          }
          _repository.updateItem(mergedItem, i);
        }
      } else {
        // Fixed network does't contain repo Item It means It's deleted
        // But we check If It's not a custom network
        if (repoItem.networkType != NetworkType.custom) {
          _repository.removeItem(repoItem);
        }
      }
    }

    // Adding new networks If available
    for (Network network in newNetworkList) {
      final foundIndex =
          _repository.items.indexWhere((e) => e.chainId == network.chainId);

      if (foundIndex == -1) {
        // Disable the network, Just in case
        _repository.addItem(network.copyWith(enabled: false));
      }
    }

    update(networks, _repository.items);
    return selectedNetwork;
  }

  void changeIpfsGateWay(String newIpfsGateWay) {
    _repository.changeIpfsGateWay(newIpfsGateWay);
    update(selectedIpfsGateWay, _repository.selectedIpfsGatewayItem);
  }

  void updateIpfsGateWayList(List<String> newIpfsGateWayList) {
    update(ipfsGateWayList, newIpfsGateWayList);
  }

  void switchDefaultNetwork(Network newDefault) {
    final currentDefaultItemIndex =
        networks.value.indexWhere((element) => element.enabled == true);
    final newDefaultItemIndex = networks.value
        .indexWhere((element) => element.chainId == newDefault.chainId);

    if (currentDefaultItemIndex != -1 &&
        newDefaultItemIndex != -1 &&
        currentDefaultItemIndex != newDefaultItemIndex) {
      final currentDefault =
          networks.value[currentDefaultItemIndex].copyWith(enabled: false);
      newDefault = newDefault.copyWith(enabled: true, isAdded: true);

      updateItem(newDefault, newDefaultItemIndex);
      updateItem(currentDefault, currentDefaultItemIndex);

      update(selectedNetwork, newDefault);
    }
  }

  void getCurrentNetwork() {
    final currentNetwork =
        _repository.items.where((item) => item.enabled).first;
    update(selectedNetwork, currentNetwork);
  }

  Network getCurrentNetworkWithoutRefresh() {
    return _repository.items.where((item) => item.enabled).first;
  }

  void refresh() {
    update(networks, networks.value);
    update(selectedNetwork, selectedNetwork.value);
  }

  void updateSelectedNetwork(Network updatedSelectedNetwork) {
    update(selectedNetwork, updatedSelectedNetwork);
  }

  /// only for details of custom network delete network page
  void selectNetworkForDetails(Network network) {
    update(selectedNetworkForDetails, network);
  }

  /// TODO: Make a ur launcher use case
  void launchAddress(String address) async {
    final chainExplorerUrl = selectedNetwork.value!.explorerUrl!;
    final addressExplorer = Urls.addressExplorer(address);
    final launchUri = Formatter.mergeUrl(chainExplorerUrl, addressExplorer);

    if ((await canLaunchUrl(launchUri))) {
      await launchUrl(launchUri, mode: LaunchMode.platformDefault);
    }
  }

  void launchUrlInPlatformDefault(String url) async {
    final launchUri = Uri.parse(url);
    if ((await canLaunchUrl(launchUri))) {
      await launchUrl(launchUri, mode: LaunchMode.platformDefault);
    }
  }
}
