import 'package:datadashwallet/common/common.dart';
import 'package:datadashwallet/core/core.dart';
import 'package:mxc_logic/mxc_logic.dart';
import 'package:web3dart/web3dart.dart';

class TransactionsHistoryUseCase extends ReactiveUseCase {
  TransactionsHistoryUseCase(this._repository, this._web3Repository);

  final Web3Repository _web3Repository;

  final TransactionsHistoryRepository _repository;

  late final ValueStream<List<TransactionModel>> transactionsHistory =
      reactiveField(_repository.transactionsHistory);

  List<TransactionModel> getTransactionsHistory() => _repository.items;

  List<String> updatingTxList = [];

  void updateItem(
    TransactionModel item,
  ) {
    final index = transactionsHistory.value.indexWhere(
      (element) => element.hash == item.hash,
    );

    if (index == -1) {
      _repository.addItem(item, index);
    } else {
      _repository.updateItem(
        item,
        index,
      );
    }

    update(transactionsHistory, _repository.items);
  }

  void removeAll() {
    _repository.removeAll();
    update(transactionsHistory, _repository.items);
  }

  void removeItem(TransactionModel item) {
    _repository.removeItem(item);
    update(transactionsHistory, _repository.items);
  }

  void spyOnTransaction(
    TransactionModel item,
  ) {
    if (!updatingTxList.contains(item.hash)) {
      updatingTxList.add(item.hash);
      final stream = _web3Repository.tokenContract.spyTransaction(item.hash);
      stream.onData((succeeded) {
        if (succeeded) {
          final updatedItem = item.copyWith(status: TransactionStatus.done);
          updateItem(
            updatedItem,
          );
          updatingTxList.remove(item.hash);
          stream.cancel();
        }
      });
    }
  }

  void checkForPendingTransactions(int chainId) {
    if (!Config.isMxcChains(chainId)) {
      final txList = transactionsHistory.value;
      final pendingTxList = txList
          .where((element) => element.status == TransactionStatus.pending);
      for (TransactionModel pendingTx in pendingTxList) {
        spyOnTransaction(
          pendingTx,
        );
      }
    }
  }

  void spyOnUnknownTransaction(
      String hash, String address, Token token, int chainId) async {
    TransactionInformation? receipt;

    receipt = await _web3Repository.tokenContract
        .getTransactionByHashCustomChain(hash);

    if (receipt != null) {
      final tx = TransactionModel.fromTransaction(receipt, address, token);
      spyOnTransaction(tx);
      updateItem(
        tx,
      );
    }
  }
}
