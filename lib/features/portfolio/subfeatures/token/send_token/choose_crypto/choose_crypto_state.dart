import 'package:equatable/equatable.dart';
import 'package:mxc_logic/mxc_logic.dart';

class ChooseCryptoState with EquatableMixin {
  List<Token>? tokens;
  List<Token>? filterTokens;
  Account? account;

  @override
  List<Object?> get props => [
        tokens,
        filterTokens,
        account,
      ];
}
