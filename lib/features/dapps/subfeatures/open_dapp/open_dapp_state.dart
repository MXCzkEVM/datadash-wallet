import 'package:equatable/equatable.dart';
import 'package:mxc_logic/mxc_logic.dart';
import 'package:web3_provider/web3_provider.dart';

class OpenDAppState with EquatableMixin {
  Account? account;
  InAppWebViewController? webviewController;
  int progress = 0;
  Network? network;

  @override
  List<Object?> get props => [
        account,
        webviewController,
        progress,
        network,
      ];
}
