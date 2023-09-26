import 'dart:convert';
import 'package:datadashwallet/common/common.dart';
import 'package:datadashwallet/core/core.dart';
import 'package:datadashwallet/features/dapps/subfeatures/open_dapp/widgets/swtich_network_dialog.dart';
import 'package:datadashwallet/features/dapps/subfeatures/open_dapp/widgets/typed_message_dialog.dart';
import 'package:flutter/services.dart';
import 'package:mxc_logic/mxc_logic.dart';
import 'package:web3_provider/web3_provider.dart';
import 'package:web3dart/web3dart.dart';
import 'package:eth_sig_util/util/utils.dart';

import 'open_dapp_state.dart';
import 'widgets/bridge_params.dart';
import 'widgets/transaction_dialog.dart';

final openDAppPageContainer =
    PresenterContainer<OpenDAppPresenter, OpenDAppState>(
        () => OpenDAppPresenter());

class OpenDAppPresenter extends CompletePresenter<OpenDAppState> {
  OpenDAppPresenter() : super(OpenDAppState());

  late final _transactionHistoryUseCase =
      ref.read(transactionHistoryUseCaseProvider);
  late final _chainConfigurationUseCase =
      ref.read(chainConfigurationUseCaseProvider);
  late final _tokenContractUseCase = ref.read(tokenContractUseCaseProvider);
  late final _accountUseCase = ref.read(accountUseCaseProvider);
  late final _authUseCase = ref.read(authUseCaseProvider);

  @override
  void initState() {
    super.initState();

    listen(
      _accountUseCase.account,
      (value) {
        notify(() => state.account = value);
      },
    );

    listen(_chainConfigurationUseCase.selectedNetwork, (value) {
      if (value != null) {
        notify(() => state.network = value);
      }
    });
  }

  @override
  Future<void> dispose() {
    return super.dispose();
  }

  void onWebViewCreated(InAppWebViewController controller) {
    notify(() => state.webviewController = controller);
  }

  Future<EstimatedGasFee?> _estimatedFee(
    String from,
    String to,
    EtherAmount? gasPrice,
    Uint8List? data,
    BigInt? amountOfGas,
  ) async {
    loading = true;
    try {
      final gasFee = await _tokenContractUseCase.estimateGesFee(
          from: from,
          to: to,
          gasPrice: gasPrice,
          data: data,
          amountOfGas: amountOfGas);
      loading = false;

      return gasFee;
    } catch (e, s) {
      addError(e, s);
    } finally {
      loading = false;
    }
  }

  Future<String?> _sendTransaction(String to, EtherAmount amount,
      Uint8List? data, EstimatedGasFee? estimatedGasFee, String url,
      {String? from}) async {
    loading = true;
    try {
      final res = await _tokenContractUseCase.sendTransaction(
          privateKey: state.account!.privateKey,
          to: to,
          from: from,
          amount: amount,
          data: data,
          estimatedGasFee: estimatedGasFee);
      if (!Config.isMxcChains(state.network!.chainId) &&
          Config.isL3Bridge(url)) {
        recordTransaction(res);
      }

      return res;
    } catch (e, s) {
      addError(e, s);
    } finally {
      loading = false;
    }
  }

  String? _signTypedMessage(
    String hexData,
  ) {
    loading = true;
    try {
      final res = _tokenContractUseCase.signTypedMessage(
          privateKey: state.account!.privateKey, data: hexData);
      return res;
    } catch (e, s) {
      addError(e, s);
    } finally {
      loading = false;
    }
  }

  void recordTransaction(String hash) {
    final timeStamp = DateTime.now();
    const txStatus = TransactionStatus.pending;
    const txType = TransactionType.sent;
    final chainId = state.network!.chainId;
    final token = Token(
        chainId: state.network!.chainId,
        logoUri: Config.mxcLogoUri,
        name: Config.mxcName,
        symbol: Config.mxcSymbol,
        // can separate Sepolia & Ethereum
        address: Config.isEthereumMainnet(chainId)
            ? Config.mxcAddressEthereum
            : Config.mxcAddressSepolia);
    final tx = TransactionModel(
      hash: hash,
      timeStamp: timeStamp,
      status: txStatus,
      type: txType,
      value: '0',
      token: token,
    );

    _transactionHistoryUseCase.spyOnTransaction(tx, chainId);
    _transactionHistoryUseCase.updateItemTx(tx, chainId);
  }

  void signTransaction({
    required BridgeParams bridge,
    required VoidCallback cancel,
    required Function(String idHaethClientsh) success,
    required String url,
  }) async {
    final amountEther = EtherAmount.inWei(bridge.value ?? BigInt.zero);
    final amount = amountEther.getValueInUnit(EtherUnit.ether).toString();
    final bridgeData = hexToBytes(bridge.data ?? '');
    EtherAmount? gasPrice;
    double? gasFee;
    EstimatedGasFee? estimatedGasFee;
    BigInt? amountOfGas;

    if (bridge.gasPrice != null) {
      gasPrice = EtherAmount.fromBase10String(EtherUnit.wei, bridge.gasPrice!);
    }

    if (bridge.gas != null) {
      amountOfGas = BigInt.parse(bridge.gas.toString());
      gasPrice = gasPrice ?? await _tokenContractUseCase.getGasPrice();
      final gasPriceDouble =
          gasPrice.getValueInUnit(EtherUnit.ether).toDouble();
      gasFee = gasPriceDouble * amountOfGas.toDouble();

      estimatedGasFee =
          EstimatedGasFee(gasPrice: gasPrice, gas: amountOfGas, gasFee: gasFee);
    } else {
      estimatedGasFee = await _estimatedFee(
          bridge.from!, bridge.to!, gasPrice, bridgeData, amountOfGas);

      if (estimatedGasFee == null) {
        cancel.call();
        return;
      }
    }

    String finalFee = estimatedGasFee.gasFee.toString();

    if (Validation.isExpoNumber(finalFee)) {
      finalFee = '0.000';
    }

    final symbol = state.network!.symbol;

    try {
      final result = await showTransactionDialog(context!,
          title: translate('confirm_transaction')!,
          amount: amount,
          from: bridge.from!,
          to: bridge.to!,
          estimatedFee: finalFee,
          symbol: symbol);

      if (result != null && result) {
        final hash = await _sendTransaction(
            bridge.to!, amountEther, bridgeData, estimatedGasFee, url,
            from: bridge.from);
        if (hash != null) success.call(hash);
      } else {
        cancel.call();
      }
    } catch (e, s) {
      cancel.call();
      addError(e, s);
    }
  }

  Future<bool?> addEthereumChain(
      dynamic id, Map<dynamic, dynamic> params) async {
    final rawChainId = params["object"]["chainId"] as String;
    final chainId = Formatter.hexToDecimal(rawChainId);
    final networks = _chainConfigurationUseCase.networks.value;
    final foundChainIdIndex =
        networks.indexWhere((element) => element.chainId == chainId);

    if (foundChainIdIndex != -1) {
      final foundNetwork = networks[foundChainIdIndex];
      return await showSwitchNetworkDialog(context!,
          fromNetwork: state.network!.label ?? state.network!.web3RpcHttpUrl,
          toNetwork: foundNetwork.label ?? foundNetwork.web3RpcHttpUrl,
          onTap: () {
        switchNetwork(id, foundNetwork, rawChainId);
      });
    } else {
      addError(translate('network_not_found'));
      state.webviewController?.sendError(translate('network_not_found')!, id);
    }
  }

  void signPersonalMessage() {}

  void signTypedMessage({
    required Map<String, dynamic> object,
    required VoidCallback cancel,
    required Function(String hash) success,
  }) async {
    String hexData = object['raw'] as String;
    Map<String, dynamic> data =
        jsonDecode(object['raw'] as String) as Map<String, dynamic>;
    Map<String, dynamic> domain = data['domain'] as Map<String, dynamic>;
    String primaryType = data['primaryType'];
    int chainId = (domain['chainId']) as int;
    String name = domain['name'] as String;

    try {
      final result = await showTypedMessageDialog(context!,
          title: translate('signature_request')!,
          message: data['message'] as Map<String, dynamic>,
          networkName: '$name ($chainId)',
          primaryType: primaryType);

      if (result != null && result) {
        final hash = _signTypedMessage(
          hexData,
        );
        if (hash != null) success.call(hash);
      } else {
        cancel.call();
      }
    } catch (e, s) {
      cancel.call();
      addError(e, s);
    }
  }

  void changeProgress(int progress) => notify(() => state.progress = progress);

  void setAddress(dynamic id) {
    if (state.account != null) {
      final walletAddress = state.account!.address;
      state.webviewController?.setAddress(walletAddress, id);
    }
  }

  void switchNetwork(dynamic id, Network toNetwork, String rawChainId) {
    // "{"id":1692336424091,"name":"switchEthereumChain","object":{"chainId":"0x66eed"},"network":"ethereum"}"
    _chainConfigurationUseCase.switchDefaultNetwork(toNetwork);
    _transactionHistoryUseCase.checkChainAvailability(toNetwork.chainId);
    _authUseCase.resetNetwork(toNetwork);
    notify(() => state.network = toNetwork);

    setChain(id);
  }

  void setChain(int? id) {
    state.webviewController?.setChain(getConfig(), state.network!.chainId, id);
  }

  String getConfig() {
    return """{
              ethereum: {
                chainId: ${state.network!.chainId},
                rpcUrl: "${state.network!.web3RpcHttpUrl}",
                address: "${state.account!.address}",
                isDebug: true,
                networkVersion: "${state.network!.chainId}",
                isMetaMask: true
              }
            }""";
  }

  void copy(List<dynamic> params) {
    Clipboard.setData(ClipboardData(text: params[0]));
  }

  Future<String> paste(List<dynamic> params) async {
    return (await Clipboard.getData('text/plain'))?.text.toString() ?? '';
  }

  void injectCopyHandling() {
    state.webviewController!.evaluateJavascript(
        source:
            'javascript:navigator.clipboard.writeText = (msg) => { return window.flutter_inappwebview?.callHandler("axs-wallet-copy-clipboard", msg); }');
    state.webviewController!.addJavaScriptHandler(
      handlerName: 'axs-wallet-copy-clipboard',
      callback: (args) {
        copy(args);
      },
    );
  }

  void launchAddress(String address) {
    final chainExplorerUrl = state.network!.explorerUrl!;
    final explorerUrl = chainExplorerUrl.endsWith('/')
        ? chainExplorerUrl
        : '$chainExplorerUrl/';

    final addressUrl = '$explorerUrl${Config.addressExplorer(address)}';
    state.webviewController!
        .loadUrl(urlRequest: URLRequest(url: Uri.parse(addressUrl)));
  }

  bool isAddress(String address) {
    try {
      EthereumAddress.fromHex(address);
      return true;
    } catch (e) {
      return false;
    }
  }
}
