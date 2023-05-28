import 'package:flutter/material.dart';

class TransactionsFilter with ChangeNotifier {
  String _transactionCategory = 'caisse', _compt = 'tout', _search = '';

  String get transactionCategory => _transactionCategory;
  String get compt => _compt;
  String get search => _search;

  void change({String transactionCategory = '', compt = '', search = ''}) {
    if (transactionCategory != '') _transactionCategory = transactionCategory;
    if (compt != '') _compt = compt;
    if (search != '') _search = search;
    notifyListeners();
  }

  void reset() {
    _transactionCategory = 'caisse';
    _compt = 'tout';
    _search = '';
    notifyListeners();
  }

  void resetFilter() {
    _compt = 'tout';
    _search = '';
    notifyListeners();
  }
}
