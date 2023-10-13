import 'package:datadashwallet/common/components/components.dart';
import 'package:datadashwallet/common/config.dart';
import 'package:datadashwallet/common/utils/formatter.dart';
import 'package:datadashwallet/core/core.dart';
import 'package:datadashwallet/features/wallet/wallet.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:mxc_logic/mxc_logic.dart';
import 'package:url_launcher/url_launcher.dart';
import 'wallet_page_state.dart';

final walletContainer =
    PresenterContainer<WalletPresenter, WalletState>(() => WalletPresenter());

class WalletPresenter extends CompletePresenter<WalletState> {
  WalletPresenter() : super(WalletState());

  late final _chainConfigurationUseCase =
      ref.read(chainConfigurationUseCaseProvider);
  late final _accountUserCase = ref.read(accountUseCaseProvider);
  late final _tokenContractUseCase = ref.read(tokenContractUseCaseProvider);
  late final _tweetsUseCase = ref.read(tweetsUseCaseProvider);
  late final _customTokenUseCase = ref.read(customTokensUseCaseProvider);
  late final _balanceUseCase = ref.read(balanceHistoryUseCaseProvider);
  late final _transactionHistoryUseCase =
      ref.read(transactionHistoryUseCaseProvider);

  @override
  void initState() {
    super.initState();

    getMXCTweets();
    _transactionHistoryUseCase.checkForPendingTransactions(
        _chainConfigurationUseCase.getCurrentNetworkWithoutRefresh().chainId);

    listen(_chainConfigurationUseCase.selectedNetwork, (value) {
      if (value != null) {
        state.network = value;
        if (state.walletAddress != null) {
          initializeWalletPage();
        }
      }
    });

    listen(_accountUserCase.account, (value) {
      if (value != null) {
        notify(() => state.walletAddress = value.address);
        initializeWalletPage();
      }
    });

    listen(_transactionHistoryUseCase.transactionsHistory, (value) {
      if (state.network != null) {
        if (!Config.isMxcChains(state.network!.chainId)) {
          getCustomChainsTransactions(value);
        }
      }
    });

    listen(_accountUserCase.xsdConversionRate, (value) {
      notify(() => state.xsdConversionRate = value);
    });

    listen(_balanceUseCase.balanceHistory, (newBalanceHistory) {
      if (newBalanceHistory.isNotEmpty) {
        generateChartData(newBalanceHistory);
      }
    });

    listen(_tokenContractUseCase.tokensList, (newTokenList) {
      if (newTokenList.isNotEmpty) {
        state.tokensList.clear();
        state.tokensList.addAll(newTokenList);
      }
    });

    listen(_tokenContractUseCase.totalBalanceInXsd, (newValue) {
      notify(() => state.walletBalance = newValue.toString());
      _balanceUseCase
          .addItem(BalanceData(timeStamp: DateTime.now(), balance: newValue));
    });

    listen(_customTokenUseCase.tokens, (customTokens) {
      _tokenContractUseCase.addCustomTokens(
          customTokens,
          state.walletAddress ?? _accountUserCase.account.value!.address,
          Config.isMxcChains(state.network!.chainId) ||
              Config.isEthereumMainnet(state.network!.chainId));
      initializeBalancePanelAndTokens();
    });
  }

  @override
  Future<void> dispose() async {
    if (state.subscription != null) state.subscription!.cancel();
    super.dispose();
  }

  changeIndex(newIndex) {
    notify(() => state.currentIndex = newIndex);
  }

  Future<void> initializeWalletPage() async {
    createSubscriptions();
    getTransactions();
  }

  void createSubscriptions() async {
    if (state.subscription == null && state.network!.web3WebSocketUrl != null) {
      if (state.network!.web3WebSocketUrl!.isNotEmpty) {
        final subscription = await _tokenContractUseCase.subscribeToBalance(
          "addresses:${state.walletAddress}".toLowerCase(),
        );

        if (subscription == null) {
          createSubscriptions();
        }

        subscription!.doOnError(
          (object, trace) {
            createSubscriptions();
          },
        );

        state.subscription = subscription.listen((event) {
          if (!mounted) return;
          switch (event.event.value as String) {
            // coin transfer pending tx token transfer - coin transfer
            case 'pending_transaction':
              final newTx = WannseeTransactionModel.fromJson(
                  json.encode(event.payload['transactions'][0]));
              if (newTx.value != null) {
                notify(() => state.txList!.insert(
                    0,
                    TransactionModel.fromMXCTransaction(
                        newTx, state.walletAddress!)));
              }
              break;
            // coin transfer done
            case 'transaction':
              final newTx = WannseeTransactionModel.fromJson(
                  json.encode(event.payload['transactions'][0]));
              if (newTx.value != null) {
                // We will filter token_transfer tx because It is also received from token_transfer event
                if (newTx.txTypes != null &&
                    !(newTx.txTypes!.contains('token_transfer'))) {
                  final itemIndex = state.txList!
                      .indexWhere((txItem) => txItem.hash == newTx.hash);
                  // checking for if the transaction is found.
                  if (itemIndex != -1) {
                    notify(() => state.txList!.replaceRange(
                            itemIndex, itemIndex + 1, [
                          TransactionModel.fromMXCTransaction(
                              newTx, state.walletAddress!)
                        ]));
                  } else {
                    // we must have missed the pending tx
                    notify(() => state.txList!.insert(
                        0,
                        TransactionModel.fromMXCTransaction(
                            newTx, state.walletAddress!)));
                  }
                }
              }
              break;
            // token transfer pending
            case 'token_transfer':
              final newTx = TokenTransfer.fromJson(
                  json.encode(event.payload['token_transfers'][0]));
              if (newTx.txHash != null) {
                // Sender will get pending tx
                // Receiver won't get pending tx
                final itemIndex = state.txList!
                    .indexWhere((txItem) => txItem.hash == newTx.txHash);
                // checking for if the transaction is found.
                if (itemIndex != -1) {
                  notify(() =>
                      state.txList!.replaceRange(itemIndex, itemIndex + 1, [
                        TransactionModel.fromMXCTransaction(
                            WannseeTransactionModel(tokenTransfers: [newTx]),
                            state.walletAddress!)
                      ]));
                } else {
                  // we must have missed the token transfer pending tx
                  notify(() => state.txList!.insert(
                        0,
                        TransactionModel.fromMXCTransaction(
                            WannseeTransactionModel(tokenTransfers: [newTx]),
                            state.walletAddress!),
                      ));
                }
              }
              break;
            // new balance
            case 'balance':
              final wannseeBalanceEvent =
                  WannseeBalanceModel.fromJson(event.payload);
              getWalletTokensBalance(null, true);
              break;
            default:
          }
        });
      }
    }
  }

  void getTransactions() async {
    if (Config.isMxcChains(state.network!.chainId)) {
      getMXCTransactions();
    } else {
      getCustomChainsTransactions(null);
    }
  }

  void getCustomChainsTransactions(List<TransactionModel>? txHistory) {
    txHistory =
        txHistory ?? _transactionHistoryUseCase.getTransactionsHistory();

    if (state.network != null) {
      final chainTxHistory = txHistory;

      notify(() => state.txList = chainTxHistory);
    }
  }

  void getMXCTransactions() async {
    // final walletAddress = await _walletUserCase.getPublicAddress();
    // transactions list contains all the kind of transactions
    // It's going to be filtered to only have native coin transfer
    await _tokenContractUseCase
        .getTransactionsByAddress(state.walletAddress!)
        .then((newTransactionsList) async {
      // token transfer list contains only one kind transaction which is token transfer
      final newTokenTransfersList = await _tokenContractUseCase
          .getTokenTransfersByAddress(state.walletAddress!);

      if (newTokenTransfersList != null && newTransactionsList != null) {
        // loading over and we have the data
        state.isTxListLoading = false;
        // merge
        if (newTransactionsList.items != null) {
          newTransactionsList = newTransactionsList.copyWith(
              items: newTransactionsList.items!.where((element) {
            if (element.txTypes != null) {
              return element.txTypes!
                  .any((element) => element == 'coin_transfer');
            } else {
              return false;
            }
          }).toList());
        }

        if (newTokenTransfersList.items != null) {
          for (int i = 0; i < newTokenTransfersList.items!.length; i++) {
            final item = newTokenTransfersList.items![i];
            newTransactionsList.items!
                .add(WannseeTransactionModel(tokenTransfers: [item]));
          }
          if (newTransactionsList.items!.isNotEmpty) {
            newTransactionsList.items!.sort((a, b) {
              if (b.timestamp == null && a.timestamp == null) {
                // both token transfer
                return b.tokenTransfers![0].timestamp!
                    .compareTo(a.tokenTransfers![0].timestamp!);
              } else if (b.timestamp != null && a.timestamp != null) {
                // both coin transfer
                return b.timestamp!.compareTo(a.timestamp!);
              } else if (b.timestamp == null) {
                // b is token transfer
                return b.tokenTransfers![0].timestamp!.compareTo(a.timestamp!);
              } else {
                // a is token transfer
                return b.timestamp!.compareTo(a.tokenTransfers![0].timestamp!);
              }
            });
          }

          if (newTransactionsList.items!.length > 6) {
            newTransactionsList = newTransactionsList.copyWith(
                items: newTransactionsList.items!.sublist(0, 6));
          }

          final finalTxList = newTransactionsList.items!
              .map((e) =>
                  TransactionModel.fromMXCTransaction(e, state.walletAddress!))
              .toList();

          finalTxList.removeWhere(
            (element) => element.hash == "Unknown",
          );

          notify(() => state.txList = finalTxList);
        }
      } else {
        // looks like error
        state.isTxListLoading = false;
      }
    });
  }

  initializeBalancePanelAndTokens() {
    getDefaultTokens().then((tokenList) => getWalletTokensBalance(
        tokenList,
        Config.isMxcChains(state.network!.chainId) ||
            Config.isEthereumMainnet(state.network!.chainId)));
  }

  Future<List<Token>> getDefaultTokens() async {
    return await _tokenContractUseCase.getDefaultTokens(state.walletAddress!);
  }

  void changeHideBalanceState() {
    notify(() => state.hideBalance = !state.hideBalance);
  }

  void viewTransaction(String txHash) async {
    final chainExplorerUrl = state.network!.explorerUrl!;
    final txExplorer = Config.txExplorer(txHash);
    final launchUri = Formatter.mergeUrl(chainExplorerUrl, txExplorer);

    if ((await canLaunchUrl(launchUri))) {
      await launchUrl(launchUri, mode: LaunchMode.platformDefault);
    }
  }

  void getViewOtherTransactionsLink() async {
    final chainExplorerUrl = state.network!.explorerUrl!;
    final address = state.walletAddress!;
    final addressExplorer = Config.addressExplorer(address);
    final launchUri =
        Formatter.mergeUrl(chainExplorerUrl, addressExplorer);

    if ((await canLaunchUrl(launchUri))) {
      await launchUrl(launchUri, mode: LaunchMode.platformDefault);
    }
  }

  void generateChartData(List<BalanceData> balanceData) {
    final List<FlSpot> newBalanceSpots = [];
    double newMaxValue = 0.0;

    final sampleBalance = balanceData[0].balance;
    final allSame =
        balanceData.every((element) => element.balance == sampleBalance);

    if (allSame == true) {
      // we have only one day data
      final balance = balanceData[0].balance;
      newMaxValue = balance * 2.0;
    }

    for (int i = 0; i < balanceData.length; i++) {
      final data = balanceData.elementAt(i);

      final balance = data.balance;
      if (newMaxValue < balance) {
        newMaxValue = balance;
      }

      if ((i + 1) == balanceData.length) {
        // last data
        // fill the list
        newBalanceSpots.addAll(List.generate(
            7 - newBalanceSpots.length,
            (index) =>
                FlSpot((newBalanceSpots.length + index).toDouble(), balance)));
      } else {
        final nextData = balanceData.elementAt(i + 1);
        final sevenDaysBefore =
            DateTime.now().subtract(const Duration(days: 7));

        if (i == 0) {
          final difference = data.timeStamp.difference(sevenDaysBefore).inDays;
          if (!difference.isNegative) {
            newBalanceSpots.addAll(List.generate(
                difference,
                (index) => FlSpot(
                    (newBalanceSpots.length + index).toDouble(), balance)));
          }
        }

        final timeGap = nextData.timeStamp
            .difference(
              data.timeStamp,
            )
            .inDays;

        newBalanceSpots.addAll(List.generate(
            timeGap,
            (index) =>
                FlSpot((newBalanceSpots.length + index).toDouble(), balance)));
      }
    }

    if (newBalanceSpots.isNotEmpty) {
      if (newBalanceSpots.length < 7) {
        final lastBalance = newBalanceSpots[newBalanceSpots.length - 1].y;
        final endingBalances = List.generate(
            7 - newBalanceSpots.length,
            (index) => FlSpot(
                (newBalanceSpots.length + index).toDouble(), lastBalance));
        newBalanceSpots.addAll(endingBalances);
      }
      state.balanceSpots.clear();
      notify(() => state.balanceSpots.addAll(newBalanceSpots));
      notify(() => state.chartMaxAmount = newMaxValue);
      calculateTheChange();
    }
  }

  void calculateTheChange() {
    try {
      final yesterdayBalance = state.balanceSpots[5].y;

      final balanceDifference =
          double.parse(state.walletBalance) - yesterdayBalance;

      if (balanceDifference == 0) {
        notify(() => state.changeIndicator = 0);
      } else {
        notify(() =>
            state.changeIndicator = balanceDifference * 100 / yesterdayBalance);
      }
    } catch (e) {
      addError(e.toString());
    }
  }

  void getMXCTweets() async {
    try {
      final defaultTweets = await _tweetsUseCase.getDefaultTweets();

      notify(() => state.embeddedTweets = defaultTweets.tweets!);
    } catch (e) {
      addError(e.toString());
    }
  }

  void getWalletTokensBalance(
      List<Token>? tokenList, bool shouldGetPrice) async {
    _tokenContractUseCase.getTokensBalance(
        tokenList, state.walletAddress!, shouldGetPrice);
  }

  void checkMaxTweetHeight(double height) {
    if (height >= state.maxTweetViewHeight - 120) {
      notify(() => state.maxTweetViewHeight = height + 120);
    }
  }
}
