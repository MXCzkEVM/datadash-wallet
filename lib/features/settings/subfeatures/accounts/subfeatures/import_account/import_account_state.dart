import 'package:equatable/equatable.dart';
import 'package:mxc_logic/mxc_logic.dart';

class ImportAccountState with EquatableMixin {
  bool ableToSave = false;
  bool isLoading = false;
  List<Account> accounts = [];

  @override
  List<Object?> get props => [ableToSave, isLoading, accounts];
}
