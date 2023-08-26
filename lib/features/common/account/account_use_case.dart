import 'package:datadashwallet/core/core.dart';
import 'package:datadashwallet/features/common/account/account_cache_repository.dart';
import 'package:mxc_logic/mxc_logic.dart';

class AccountUseCase extends ReactiveUseCase {
  AccountUseCase(
    this._repository,
    this._accountCacheRepository,
    this._authenticationStorageRepository,
  );

  final AccountCacheRepository _accountCacheRepository;
  final AuthenticationStorageRepository _authenticationStorageRepository;
  final Web3Repository _repository;

  late final ValueStream<Account?> account =
      reactiveField(_accountCacheRepository.account);
  late final ValueStream<List<Account>> accounts =
      reactiveField(_accountCacheRepository.accounts);

  late final ValueStream<double> xsdConversionRate = reactive(1.0);

  String? getMnemonic() => _authenticationStorageRepository.mnemonic;

  void updateAccount(Account item) {
    _accountCacheRepository.updateAccount(item);
    update(account, item);
  }

  void addAccount(Account item) async {
    _accountCacheRepository.addAccount(item);
    final items = _accountCacheRepository.accountItems;
    update(account, item);
    update(accounts, items);
    getAccountsNames();
  }

  void changeAccount(Account item) {
    update(account, item);
  }

  void resetXsdConversionRate(double value) {
    _accountCacheRepository.setXsdConversionRate(value);
    update(xsdConversionRate, value);
  }

  String getXsdUnit() {
    return xsdConversionRate.value == 1.0 ? 'XSD' : '✗';
  }

  void getAccountsNames() async {
    for (Account account in accounts.value) {
      await getAccountMns(account);
    }
    update(accounts, _accountCacheRepository.accountItems);
    update(account, _accountCacheRepository.accountItem);
  }

  Future<bool> getAccountMns(Account item) async {
    try {
      final result = await _repository.tokenContract.getName(item.address);
      item.mns = result;
      _accountCacheRepository.updateAccount(item);
      return true;
    } catch (e) {
      if (e == 'RangeError: Value not in range: 32') {
        // The username is empty
        item.mns = null;
        _accountCacheRepository.updateAccount(item);
        return true;
      } else {
        return false;
      }
    }
  }
}
