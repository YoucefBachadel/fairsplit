import 'package:flutter/material.dart';

class Filter with ChangeNotifier {
  String _transactionCategory = 'caisse', _compt = 'tout', _search = '', _loanDeposit = 'tout';

  String get transactionCategory => _transactionCategory;
  String get compt => _compt;
  String get search => _search;
  String get loanDeposit => _loanDeposit;

  void change({String transactionCategory = '', compt = '', search = '', loanDeposit = ''}) {
    if (transactionCategory != '') _transactionCategory = transactionCategory;
    if (compt != '') _compt = compt;
    if (search != '') _search = search;
    if (loanDeposit != '') _loanDeposit = loanDeposit;
    notifyListeners();
  }

  void reset() {
    _transactionCategory = 'caisse';
    _compt = 'tout';
    _search = '';
    _loanDeposit = 'tout';
    notifyListeners();
  }

  void resetFilter() {
    _compt = 'tout';
    _search = '';
    _loanDeposit = 'tout';
    notifyListeners();
  }
}
