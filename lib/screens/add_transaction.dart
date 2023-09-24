import 'package:fairsplit/models/other_user.dart';
import 'package:fairsplit/screens/print_transaction.dart';
import 'package:flutter/material.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../models/user.dart';
import '../shared/functions.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';
import '../main.dart';
import '../shared/lists.dart';

class SelectTransactionCategoty extends StatelessWidget {
  const SelectTransactionCategoty({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getHeight(context, .58),
      width: getWidth(context, .39),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          alignment: Alignment.center,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  getText('transaction'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                  ),
                ),
              ),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ))
            ],
          ),
          decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              )),
        ),
        const Spacer(),
        ...selectTransactionType
            .map((e) => Column(
                  children: [
                    Card(
                      elevation: 5.0,
                      child: myButton(
                        context,
                        text: e,
                        width: getWidth(context, .15),
                        noIcon: true,
                        color: Colors.white,
                        textColor: Colors.black,
                        onTap: () async {
                          Navigator.pop(context);
                          await createDialog(
                            context,
                            AddTransaction(
                              sourceTab: 'tr',
                              selectedTransactionType: selectTransactionType.indexOf(e),
                            ),
                            dismissable: false,
                          );
                        },
                      ),
                    ),
                    mySizedBox(context),
                  ],
                ))
            .toList(),
        const Spacer(),
      ]),
    );
  }
}

class AddTransaction extends StatefulWidget {
  final int userId;
  final String sourceTab, selectedName, category;
  final String type; // used for loan and deposit transaction
  final double userCapital; // used for users transaction
  final double amount, rest; // used for loan and deposit transaction
  final int selectedTransactionType; //0: specials  1:users 2:loans 3:deposits
  const AddTransaction({
    Key? key,
    this.sourceTab = 'tr',
    this.userId = 0,
    this.selectedName = '',
    this.category = 'caisse',
    this.type = '',
    this.userCapital = 0,
    this.amount = 0,
    this.rest = 0,
    this.selectedTransactionType = 0,
  }) : super(key: key);

  @override
  State<AddTransaction> createState() => _AddTransactionState();
}

class _AddTransactionState extends State<AddTransaction> {
  late String selectedName = '', category = 'caisse', type = 'out', amount = '0', note = '', appBarTitle = '';
  late double caisse,
      reserve,
      reserveProfit,
      donation,
      zakat,
      rest = 0,
      selectedUserCapital = 0; //used to show user capital
  DateTime date = DateTime.now();
  bool isLoading = true;
  int selectedTransactionType = 0;
  String _password = ''; // used for all users Transaction;

  List<User> users = [];
  List<OtherUser> loanUsers = [], depositUsers = [];
  User selectedUser = User();
  OtherUser selectedOtherUser = OtherUser();

  void loadData() async {
    var params = {};
    int counter = 1;
    params['sql$counter'] = 'SELECT * FROM Settings;';
    if ((['tr', 'da'].contains(widget.sourceTab)) && ([1, 4].contains(selectedTransactionType))) {
      counter++;
      params['sql$counter'] = '''SELECT userId,name,capital FROM Users;''';
    }
    if (['tr', 'da'].contains(widget.sourceTab) && ([2, 3].contains(selectedTransactionType))) {
      counter++;
      params['sql$counter'] = '''SELECT userId,name,type,amount,rest FROM OtherUsers;''';
    }
    var res = await sqlQuery(selectUrl, params);

    var dataSettings = res[0][0];
    caisse = double.parse(dataSettings['caisse']);
    reserve = double.parse(dataSettings['reserve']);
    reserveProfit = double.parse(dataSettings['reserveProfit']);
    donation = double.parse(dataSettings['donation']);
    zakat = double.parse(dataSettings['zakat']);

    if (widget.sourceTab == 'da' && selectedTransactionType == 0) {
      //if source tab is dashboard and type is special
      category = widget.category;
    } else if (!['da', 'tr'].contains(widget.sourceTab)) {
      //else if source tab is not dashboard or transaction
      selectedName = widget.selectedName;
      rest = widget.rest;
      if (widget.sourceTab == 'us') {
        selectedUser = User(userId: widget.userId, name: selectedName, capital: widget.userCapital);
        selectedUserCapital = widget.userCapital;
      } else {
        selectedOtherUser = OtherUser(
          userId: widget.userId,
          name: selectedName,
          type: widget.type,
          amount: widget.amount,
          rest: widget.rest,
        );
      }
    } else if (selectedTransactionType != 0) {
      // else if source tab is dashboard or transaction and type is not special
      var dataUsers = res[1];

      if ([1, 4].contains(selectedTransactionType)) {
        for (var element in dataUsers) {
          users.add(User(
              userId: int.parse(element['userId']), name: element['name'], capital: double.parse(element['capital'])));
        }
        users.sort((a, b) => a.name.compareTo(b.name));
      } else {
        for (var element in dataUsers) {
          OtherUser user = OtherUser(
            userId: int.parse(element['userId']),
            name: element['name'],
            type: element['type'],
            amount: double.parse(element['amount']),
            rest: double.parse(element['rest']),
          );
          user.type == 'loan' ? loanUsers.add(user) : depositUsers.add(user);
        }
        loanUsers.sort((a, b) => a.name.compareTo(b.name));
        depositUsers.sort((a, b) => a.name.compareTo(b.name));
      }
    }

    setState(() => isLoading = false);
  }

  void save() async {
    bool _testsChecked = true; //used to test if rest is >= 0 and prevent navigation to main screen
    double _amount = double.parse(amount);
    double _soldeCaisse = caisse;

    if (type == 'out') _amount = _amount * -1;
    if (selectedTransactionType != 4) _soldeCaisse += _amount;

    if (_soldeCaisse < 0) {
      _testsChecked = false;
      snackBar(context, getMessage('soldeCaisseZero'));
    } else {
      if (selectedTransactionType == 0) {
        //special trnasaction
        double _solde = 0;

        switch (category) {
          case 'caisse':
            _solde = caisse + _amount;
            break;
          case 'reserve':
            _solde = reserve + _amount;
            break;
          case 'reserveProfit':
            _solde = reserveProfit + _amount;
            break;
          case 'donation':
            _solde = donation + _amount;
            break;
          case 'zakat':
            _solde = zakat + _amount;
            break;
        }
        if (_solde < 0) {
          _testsChecked = false;
          snackBar(context, getMessage('soldeZero'));
        } else {
          //insert the special transaction
          //update the setting category
          //update the setting caisse
          await sqlQuery(insertUrl, {
            'sql1':
                '''INSERT INTO TransactionSP (reference,year,category,date,type,amount,solde,soldeCaisse,note) VALUES ('${date.year % 100}/${reference.toString().padLeft(4, '0')}' , $currentYear , '$category' , '$date' , '$type' ,${_amount.abs()} , $_solde ,$_soldeCaisse , '$note' );''',
            'sql2':
                '''UPDATE Settings SET $category = $_solde , caisse = $_soldeCaisse , reference = ${reference + 1};''',
          });
          reference++;
        }
      } else if (selectedTransactionType == 4) {
        //all Users transaction

        List<User> moneyUsers = [];
        double _totalUsersCapital = 0, _userAmount = 0, _soldeUser = 0;
        String usersSQL = 'INSERT INTO Users(userId, capital) VALUES ';
        String transactionsSQL =
            'INSERT INTO Transaction (reference,userId,userName,year,date,type,amount,soldeUser,soldeCaisse,note) VALUES ';

        //get money users
        for (var user in users) {
          if (['money', 'both'].contains(user.type) && user.capital != 0) {
            moneyUsers.add(user);
            _totalUsersCapital += user.capital;
          }
        }

        if (type == 'out' && _amount.abs() > _totalUsersCapital) {
          _testsChecked = false;
          snackBar(context, getMessage('amountTotalUserCapital'));
        } else {
          //calculate the amount for each user
          for (var user in moneyUsers) {
            _userAmount = (user.capital * 100 / _totalUsersCapital) * _amount / 100;
            // _soldeCaisse += _userAmount;
            _soldeUser = user.capital + _userAmount;

            usersSQL += '(${user.userId}, $_soldeUser),';
            transactionsSQL +=
                '''('${date.year % 100}/${reference.toString().padLeft(4, '0')}' , ${user.userId},'${user.name}',$currentYear , '$date' , '$type' ,${_userAmount.abs()} ,$_soldeUser, $_soldeCaisse , '$note' ),''';
            reference++;
          }

          usersSQL = usersSQL.substring(0, usersSQL.length - 1);
          usersSQL += ' ON DUPLICATE KEY UPDATE capital = VALUES(capital);';
          transactionsSQL = transactionsSQL.substring(0, transactionsSQL.length - 1);
          transactionsSQL += ';';

          // _soldeCaisse = caisse + _amount; // recalculate solde caisse

          //insert the transactions
          //update the Users capitals
          //update the setting caisse
          await sqlQuery(insertUrl, {
            'sql1': transactionsSQL,
            'sql2': usersSQL,
            'sql3': '''UPDATE Settings SET reference = $reference;''',
            // 'sql3': '''UPDATE Settings SET caisse = $_soldeCaisse ;''',
          });
        }
      } else {
        //other type of transaction that must check the name first
        bool nameWrite = false;
        //check if the name is write
        if (selectedTransactionType == 1) {
          for (var user in users) {
            if (user.name == selectedName) {
              nameWrite = true;
              selectedUser = user;
              break;
            }
          }
        } else if (selectedTransactionType == 2) {
          for (var user in loanUsers) {
            if (user.name == selectedName) {
              nameWrite = true;
              selectedOtherUser = user;
              break;
            }
          }
        } else {
          for (var user in depositUsers) {
            if (user.name == selectedName) {
              nameWrite = true;
              selectedOtherUser = user;
              break;
            }
          }
        }

        if (selectedTransactionType == 1) {
          //user transaction
          //test if name is not empty and name is write or users list is empty in case the user is selected from users tab
          if (selectedName.isNotEmpty && (users.isEmpty || nameWrite)) {
            double _soldeUser = selectedUser.capital + _amount;

            if (_soldeUser < 0) {
              _testsChecked = false;
              snackBar(context, getMessage('capitalZero'));
            } else {
              //insert the transaction
              //update the User capital
              //update the setting caisse
              await sqlQuery(insertUrl, {
                'sql1':
                    '''INSERT INTO Transaction (reference,userId,userName,year,date,type,amount,soldeUser,soldeCaisse,note) VALUES ('${date.year % 100}/${reference.toString().padLeft(4, '0')}' , ${selectedUser.userId},'${selectedUser.name}',$currentYear , '$date' , '$type' ,${_amount.abs()} ,$_soldeUser, $_soldeCaisse , '$note' );''',
                'sql2': '''UPDATE Users SET capital = $_soldeUser WHERE userId = ${selectedUser.userId};''',
                'sql3': '''UPDATE Settings SET caisse = $_soldeCaisse , reference = ${reference + 1};'''
              });
              reference++;
            }
          } else {
            _testsChecked = false;
            snackBar(context, getMessage('checkName'));
          }
        } else if (selectedTransactionType == 2) {
          //locan transaction
          if (selectedName.isNotEmpty && (loanUsers.isEmpty || nameWrite)) {
            double _userAmount = selectedOtherUser.amount;
            if (type == 'out') _userAmount -= _amount;

            double _userRest = selectedOtherUser.rest - _amount;

            if (_userRest < 0) {
              _testsChecked = false;
              snackBar(context, getMessage('restZero'));
            } else {
              //insert the transaction
              //update the User capital
              //update the setting caisse
              await sqlQuery(insertUrl, {
                'sql1':
                    '''INSERT INTO TransactionOthers (reference,userName,category,year,date,type,amount,soldeUser,soldeCaisse,note) VALUES ('${date.year % 100}/${reference.toString().padLeft(4, '0')}' , '${selectedOtherUser.name}', 'loan', $currentYear , '$date' , '$type' ,${_amount.abs()} ,$_userRest, $_soldeCaisse , '$note' );''',
                'sql2':
                    '''UPDATE OtherUsers SET amount = $_userAmount, rest = $_userRest WHERE userId = ${selectedOtherUser.userId};''',
                'sql3': '''UPDATE Settings SET caisse = $_soldeCaisse , reference = ${reference + 1};'''
              });
              reference++;
            }
          } else {
            _testsChecked = false;
            snackBar(context, getMessage('checkName'));
          }
        } else if (selectedTransactionType == 3) {
          //deposit transaction
          if (selectedName.isNotEmpty && (depositUsers.isEmpty || nameWrite)) {
            double _userAmount = selectedOtherUser.amount;
            if (type == 'in') {
              _userAmount += _amount;
            }
            double _userRest = selectedOtherUser.rest + _amount;

            if (_userRest < 0) {
              _testsChecked = false;
              snackBar(context, getMessage('restZero'));
            } else {
              //insert the transaction
              //update the User capital
              //update the setting caisse
              await sqlQuery(insertUrl, {
                'sql1':
                    '''INSERT INTO TransactionOthers (reference,userName,category,year,date,type,amount,soldeUser,soldeCaisse,note) VALUES ('${date.year % 100}/${reference.toString().padLeft(4, '0')}' , '${selectedOtherUser.name}','deposit',$currentYear , '$date' , '$type' ,${_amount.abs()} ,$_userRest, $_soldeCaisse , '$note' );''',
                'sql2':
                    '''UPDATE OtherUsers SET amount = $_userAmount, rest = $_userRest WHERE userId = ${selectedOtherUser.userId};''',
                'sql3': '''UPDATE Settings SET caisse = $_soldeCaisse , reference = ${reference + 1};''',
              });
              reference++;
            }
          } else {
            _testsChecked = false;
            snackBar(context, getMessage('checkName'));
          }
        }
      }
    }
    if (_testsChecked) {
      done(_amount.abs());
    } else {
      setState(() => isLoading = false);
    }
  }

  void done(double amount) async {
    if (selectedTransactionType != 4) {
      await createDialog(
        context,
        dismissable: false,
        // const SelectTransactionCategoty(),
        PrintTransaction(
          source: (selectedTransactionType == 012)
              ? 'special'
              : (selectedTransactionType == 1)
                  ? 'user'
                  : (selectedTransactionType == 2)
                      ? 'loan'
                      : 'deposit',
          type: type,
          reference: '${date.year % 100}/${(reference - 1).toString().padLeft(4, '0')}',
          amount: amount,
          date: myDateFormate.format(date),
        ),
      );
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyApp(index: widget.sourceTab)));
    snackBar(context, getMessage('addTransaction'));
  }

  @override
  void initState() {
    selectedTransactionType = widget.selectedTransactionType;
    appBarTitle = selectedTransactionType == 0
        ? getText('special')
        : selectedTransactionType == 1
            ? getText('user')
            : selectedTransactionType == 2
                ? getText('loan')
                : selectedTransactionType == 3
                    ? getText('deposit')
                    : getText('allUsers');
    loadData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getHeight(context, isAdmin ? 0.52 : 0.47),
      width: getWidth(context, .39),
      child: Column(children: [
        Container(
          alignment: Alignment.center,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  appBarTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                  ),
                ),
              ),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ))
            ],
          ),
          decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              )),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            width: double.infinity,
            decoration: BoxDecoration(
                color: scaffoldColor,
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(20.0),
                  bottomLeft: Radius.circular(20.0),
                )),
            child: isLoading
                ? myProgress()
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        mySizedBox(context),
                        if (selectedTransactionType == 0) // special transaction
                          Row(
                            children: [
                              Expanded(child: myText(getText('category'))),
                              Expanded(
                                flex: 4,
                                child: Container(
                                    alignment: Alignment.centerLeft,
                                    child: myDropDown(
                                      context,
                                      value: category,
                                      width: getWidth(context, .13),
                                      items: compts.entries.map((item) {
                                        return DropdownMenuItem(
                                          value: getKeyFromValue(item.value),
                                          alignment: AlignmentDirectional.center,
                                          child: Text(item.value),
                                        );
                                      }).toList(),
                                      onChanged: widget.sourceTab == 'da'
                                          ? null
                                          : (value) => setState(() => category = value.toString()),
                                    )),
                              ),
                            ],
                          )
                        else if (selectedTransactionType == 1) // users transaction
                          Row(
                            children: [
                              Expanded(child: myText(getText('name'))),
                              Expanded(
                                flex: 4,
                                child: Autocomplete<User>(
                                  displayStringForOption: (user) => user.name,
                                  onSelected: (user) {
                                    setState(() {
                                      selectedName = user.name;
                                      selectedUserCapital = user.capital;
                                    });
                                  },
                                  optionsBuilder: (textEditingValue) => users.where(
                                    (user) => user.name.toLowerCase().contains(textEditingValue.text.toLowerCase()),
                                  ),
                                  fieldViewBuilder: (
                                    context,
                                    textEditingController,
                                    focusNode,
                                    onFieldSubmitted,
                                  ) {
                                    if (widget.selectedName.isNotEmpty) textEditingController.text = selectedName;

                                    return Container(
                                        alignment: Alignment.center,
                                        height: getHeight(context, textFeildHeight),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.all(Radius.circular(12)),
                                        ),
                                        child: TextFormField(
                                          controller: textEditingController,
                                          focusNode: focusNode,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 18.0),
                                          enabled: ['da', 'tr'].contains(widget.sourceTab),
                                          autofocus: true,
                                          decoration: InputDecoration(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            border: const OutlineInputBorder(
                                              borderSide: BorderSide(width: 0.5),
                                              borderRadius: BorderRadius.all(Radius.circular(12)),
                                            ),
                                            suffixIcon: widget.sourceTab != 'tr' || textEditingController.text.isEmpty
                                                ? const SizedBox()
                                                : IconButton(
                                                    onPressed: () => setState(() {
                                                          textEditingController.clear();
                                                          selectedName = '';
                                                        }),
                                                    icon: const Icon(
                                                      Icons.clear,
                                                      size: 20.0,
                                                    )),
                                          ),
                                        ));
                                  },
                                  optionsViewBuilder: (
                                    BuildContext context,
                                    AutocompleteOnSelected<User> onSelected,
                                    Iterable<User> options,
                                  ) {
                                    return Align(
                                      alignment: Alignment.topLeft,
                                      child: Material(
                                        elevation: 8.0,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxHeight: getHeight(context, .2),
                                            maxWidth: getWidth(context, .29),
                                          ),
                                          child: ListView.builder(
                                            padding: EdgeInsets.zero,
                                            shrinkWrap: true,
                                            itemCount: options.length,
                                            itemBuilder: (BuildContext context, int index) {
                                              final User option = options.elementAt(index);
                                              return InkWell(
                                                onTap: () => onSelected(option),
                                                child: Container(
                                                  padding: const EdgeInsets.all(16.0),
                                                  child: myText(option.name),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          )
                        else if (selectedTransactionType == 4) // allUsers Transaction
                          const SizedBox()
                        else // loan and deposit transaction
                          Row(
                            children: [
                              Expanded(child: myText(getText('name'))),
                              Expanded(
                                flex: 4,
                                child: Autocomplete<OtherUser>(
                                  displayStringForOption: (user) => user.name,
                                  onSelected: (user) => setState(() {
                                    selectedName = user.name;
                                    rest = user.rest;
                                  }),
                                  optionsBuilder: (textEditingValue) {
                                    if (selectedTransactionType == 2) {
                                      return loanUsers.where((user) =>
                                          user.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                                    } else {
                                      return depositUsers.where((user) =>
                                          user.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                                    }
                                  },
                                  fieldViewBuilder: (
                                    context,
                                    textEditingController,
                                    focusNode,
                                    onFieldSubmitted,
                                  ) {
                                    if (widget.selectedName.isNotEmpty) textEditingController.text = selectedName;

                                    return Container(
                                        alignment: Alignment.center,
                                        height: getHeight(context, textFeildHeight),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.all(Radius.circular(12)),
                                        ),
                                        child: TextFormField(
                                          controller: textEditingController,
                                          focusNode: focusNode,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 18.0),
                                          enabled: ['da', 'tr'].contains(widget.sourceTab),
                                          autofocus: true,
                                          decoration: InputDecoration(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            border: const OutlineInputBorder(
                                              borderSide: BorderSide(width: 0.5),
                                              borderRadius: BorderRadius.all(Radius.circular(12)),
                                            ),
                                            suffixIcon: widget.sourceTab != 'tr' || textEditingController.text.isEmpty
                                                ? const SizedBox()
                                                : IconButton(
                                                    onPressed: () => setState(() {
                                                          textEditingController.clear();
                                                          selectedName = '';
                                                        }),
                                                    icon: const Icon(Icons.clear, size: 20.0)),
                                          ),
                                        ));
                                  },
                                  optionsViewBuilder: (
                                    BuildContext context,
                                    AutocompleteOnSelected<OtherUser> onSelected,
                                    Iterable<OtherUser> options,
                                  ) {
                                    return Align(
                                      alignment: Alignment.topLeft,
                                      child: Material(
                                        elevation: 8.0,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxHeight: getHeight(context, .2),
                                            maxWidth: getWidth(context, .29),
                                          ),
                                          child: ListView.builder(
                                            padding: EdgeInsets.zero,
                                            shrinkWrap: true,
                                            itemCount: options.length,
                                            itemBuilder: (BuildContext context, int index) {
                                              final OtherUser option = options.elementAt(index);
                                              return InkWell(
                                                onTap: () => onSelected(option),
                                                child: Container(
                                                  padding: const EdgeInsets.all(16.0),
                                                  child: myText(option.name),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        mySizedBox(context),
                        Row(
                          children: [
                            Expanded(child: myText(getText('type'))),
                            Expanded(
                              flex: 4,
                              child: Row(
                                children: [
                                  ToggleSwitch(
                                    minWidth: getWidth(context, .064),
                                    minHeight: getHeight(context, .045),
                                    borderWidth: 1,
                                    initialLabelIndex: type == 'out' ? 0 : 1,
                                    borderColor: const [Colors.grey],
                                    cornerRadius: 12.0,
                                    icons: const [Icons.remove, Icons.add],
                                    activeBgColors: [
                                      [Colors.red[800]!],
                                      [Colors.green[800]!]
                                    ],
                                    activeFgColor: Colors.white,
                                    inactiveBgColor: Colors.white,
                                    inactiveFgColor: Colors.black,
                                    labels: [getText('out'), getText('in')],
                                    onToggle: (index) => setState(() => type = index == 0 ? 'out' : 'in'),
                                  ),
                                  // Container(
                                  //   alignment: Alignment.centerLeft,
                                  //   child: myDropDown(
                                  //     context,
                                  //     value: type,
                                  //     width: getWidth(context, .13),
                                  //     items: transactionsTypes.entries.map((item) {
                                  //       return DropdownMenuItem(
                                  //         value: getKeyFromValue(item.value),
                                  //         alignment: AlignmentDirectional.center,
                                  //         child: Text(item.value),
                                  //       );
                                  //     }).toList(),
                                  //     onChanged: (value) => setState(() => type = value.toString()),
                                  //   ),
                                  // ),
                                  mySizedBox(context),
                                  if (selectedTransactionType != 4 &&
                                      !(selectedTransactionType == 0 && category == 'caisse'))
                                    myText('${getText('caisse')} :   ${myCurrency.format(caisse)}'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        mySizedBox(context),
                        Row(
                          children: [
                            Expanded(child: myText(getText('amount'))),
                            Expanded(
                                flex: 4,
                                child: Row(
                                  children: [
                                    myTextField(
                                      context,
                                      width: getWidth(context, .13),
                                      isNumberOnly: true,
                                      autoFocus: widget.sourceTab != 'tr' || selectedTransactionType == 4,
                                      onChanged: (value) => amount = value,
                                      hint: myCurrency.format(double.parse(amount)),
                                    ),
                                    mySizedBox(context),
                                    InkWell(
                                      onTap: () => setState(() {
                                        switch (selectedTransactionType) {
                                          case 0:
                                            setState(() {
                                              amount = category == 'caisse'
                                                  ? caisse.toString()
                                                  : category == 'reserve'
                                                      ? reserve.toString()
                                                      : category == 'reserveProfit'
                                                          ? reserveProfit.toString()
                                                          : category == 'donation'
                                                              ? donation.toString()
                                                              : zakat.toString();
                                            });
                                            break;
                                          case 1:
                                            setState(() => amount = selectedUserCapital.toString());
                                            break;
                                          case 2:
                                            setState(() => amount = rest.toString());
                                            break;
                                          case 3:
                                            setState(() => amount = rest.toString());
                                            break;
                                        }
                                      }),
                                      child: (selectedTransactionType == 0)
                                          ? myText(
                                              '${getText('solde')} :   ${myCurrency.format(category == 'caisse' ? caisse : category == 'reserve' ? reserve : category == 'reserveProfit' ? reserveProfit : category == 'donation' ? donation : zakat)}')
                                          : (selectedTransactionType == 1)
                                              ? myText(
                                                  '${getText('capital')} :   ${myCurrency.format(selectedUserCapital)}')
                                              : (selectedTransactionType == 4)
                                                  ? const SizedBox()
                                                  : myText('${getText('rest')} :   ${myCurrency.format(rest)}'),
                                    )
                                  ],
                                )),
                          ],
                        ),
                        if (isAdmin) mySizedBox(context),
                        if (isAdmin)
                          Row(
                            children: [
                              Expanded(child: myText(getText('date'))),
                              Expanded(
                                flex: 4,
                                child: Row(
                                  children: [
                                    myTextField(
                                      context,
                                      hint: myDateFormate.format(date),
                                      width: getWidth(context, .10),
                                      enabled: false,
                                      onChanged: ((text) {}),
                                    ),
                                    mySizedBox(context),
                                    IconButton(
                                      icon: Icon(
                                        Icons.calendar_month,
                                        color: primaryColor,
                                      ),
                                      onPressed: () async {
                                        final DateTime? selected = await showDatePicker(
                                          context: context,
                                          initialDate: date,
                                          firstDate: DateTime(currentYear),
                                          lastDate: DateTime.now(),
                                          initialEntryMode: DatePickerEntryMode.input,
                                          locale: const Locale("fr", "FR"),
                                        );
                                        if (selected != null && selected != date) {
                                          setState(
                                            () => date = DateTime(
                                              selected.year,
                                              selected.month,
                                              selected.day,
                                              DateTime.now().hour,
                                              DateTime.now().minute,
                                              DateTime.now().second,
                                            ),
                                          );
                                        }
                                      },
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        if (selectedTransactionType == 4) mySizedBox(context),
                        if (selectedTransactionType == 4)
                          Row(
                            children: [
                              Expanded(child: myText(getText('password'))),
                              Expanded(
                                  flex: 4,
                                  child: Row(
                                    children: [
                                      myTextField(
                                        context,
                                        width: getWidth(context, .13),
                                        onChanged: (text) => _password = text,
                                        isPassword: true,
                                      ),
                                    ],
                                  )),
                            ],
                          ),
                        mySizedBox(context),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                            child: TextFormField(
                              onChanged: ((value) => note = value),
                              style: const TextStyle(fontSize: 22),
                              maxLength: 350,
                              minLines: 4,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: getText('note'),
                                contentPadding: const EdgeInsets.all(8),
                                border: const OutlineInputBorder(
                                  gapPadding: 0,
                                  borderSide: BorderSide(width: 0.5),
                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        mySizedBox(context),
                        myButton(context, onTap: () async {
                          if (amount.isEmpty || amount == '0') {
                            snackBar(context, getMessage('zeroAmount'), duration: 5);
                          } else {
                            setState(() => isLoading = true);
                            if (selectedTransactionType == 4) {
                              var res = await sqlQuery(selectUrl, {
                                'sql1': '''SELECT IF(admin = '$_password',1,0) AS password FROM settings;''',
                              });

                              if (res[0][0]['password'] == '1') {
                                save();
                              } else {
                                setState(() => isLoading = false);
                                snackBar(context, getMessage('wrongPassword'), duration: 1);
                              }
                            } else {
                              save();
                            }
                          }
                        }),
                        mySizedBox(context),
                      ],
                    ),
                  ),
          ),
        ),
      ]),
    );
  }
}
