import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mxc_logic/mxc_logic.dart';

class WalletState with EquatableMixin {
  int currentIndex = 0;

  String walletBalance = "0.0";

  List<TransactionModel>? txList;

  bool isTxListLoading = true;

  List<Token> tokensList = [];

  String? walletAddress;

  bool hideBalance = false;

  List<FlSpot> balanceSpots = [];

  double chartMaxAmount = 1.0;

  double chartMinAmount = 0.0;

  double? changeIndicator;

  double xsdConversionRate = 2.0;

  List<String> embeddedTweets = [];

  StreamSubscription<dynamic>? subscription;

  Network? network;

  double maxTweetViewHeight = 620;

  @override
  List<Object?> get props => [
        currentIndex,
        walletBalance,
        txList,
        isTxListLoading,
        tokensList,
        walletAddress,
        hideBalance,
        chartMaxAmount,
        chartMinAmount,
        balanceSpots,
        embeddedTweets,
        xsdConversionRate,
        network,
        maxTweetViewHeight
      ];
}
