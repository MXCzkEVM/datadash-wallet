import 'package:datadashwallet/common/common.dart';
import 'package:datadashwallet/core/core.dart';
import 'package:mxc_logic/mxc_logic.dart';
import '../entity/transaction_history_model.dart';
import 'transactions_repository.dart';
import 'package:web3dart/web3dart.dart';

class TransactionsHistoryUseCase extends ReactiveUseCase {
  TransactionsHistoryUseCase(this._repository, this._web3Repository);

  final Web3Repository _web3Repository;

  final TransactionsHistoryRepository _repository;

  late final ValueStream<List<TransactionHistoryModel>> transactionsHistory =
      reactiveField(_repository.transactionsHistory);

  List<TransactionHistoryModel> getTransactionsHistory() => _repository.items;

  List<String> updatingTxList = [];

  void addItem(TransactionHistoryModel item) {
    _repository.addItem(item);
    update(transactionsHistory, _repository.items);
  }

  void updateItem(TransactionHistoryModel item, int index) {
    _repository.updateItem(item, index);
    update(transactionsHistory, _repository.items);
  }

  void updateItemTx(TransactionModel item, int selectedNetworkChainId) {
    final txHistory = transactionsHistory.value
        .firstWhere((element) => element.chainId == selectedNetworkChainId);

    final index = transactionsHistory.value.indexOf(txHistory);
    final txIndex = txHistory.txList.indexWhere(
      (element) => element.hash == item.hash,
    );

    if (txIndex == -1) {
      _repository.addItemTx(item, index);
    } else {
      _repository.updateItemTx(item, index, txIndex);
    }

    update(transactionsHistory, _repository.items);
  }

  void removeAll() {
    _repository.removeAll();
    update(transactionsHistory, _repository.items);
  }

  void removeItem(TransactionHistoryModel item) {
    _repository.removeItem(item);
    update(transactionsHistory, _repository.items);
  }

  void spyOnTransaction(TransactionModel item, int chainId) {
    if (!updatingTxList.contains(item.hash)) {
      updatingTxList.add(item.hash);
      final stream = _web3Repository.tokenContract.spyTransaction(item.hash);
      stream.onData((succeeded) {
        if (succeeded) {
          final updatedItem = item.copyWith(status: TransactionStatus.done);
          updateItemTx(updatedItem, chainId);
          updatingTxList.remove(item.hash);
          stream.cancel();
        }
      });
    }
  }

  void checkForPendingTransactions(int chainId) {
    if (!Config.isMxcChains(chainId)) {
      final index = transactionsHistory.value
          .indexWhere((element) => element.chainId == chainId);

      if (index != -1) {
        final chainTx = transactionsHistory.value[index];
        final pendingTxList = chainTx.txList
            .where((element) => element.status == TransactionStatus.pending);
        for (TransactionModel pendingTx in pendingTxList) {
          spyOnTransaction(pendingTx, chainId);
        }
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
      spyOnTransaction(tx, chainId);
      updateItemTx(tx, chainId);
    }
  }

  void checkChainAvailability(int chainId) {
    final index = transactionsHistory.value
        .indexWhere((element) => element.chainId == chainId);

    if (index == -1) {
      addItem(TransactionHistoryModel(chainId: chainId, txList: []));
      return;
    }
    update(transactionsHistory, _repository.items);
  }
}
