List<String> monthsOfYear = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

Map<String, String> usersTypes = {
  'money': getText('money'),
  'effort': getText('effort'),
  'both': getText('both'),
};

Map<String, String> usersTypesSearch = {
  'tout': getText('tout'),
  'money': getText('money'),
  'effort': getText('effort'),
  'both': getText('both'),
};

Map<String, String> otherUsersTypes = {
  'deposit': getText('deposit'),
  'loan': getText('loan'),
};

Map<String, String> otherUsersTypesSearch = {
  'tout': getText('tout'),
  'loan': getText('loan'),
  'deposit': getText('deposit'),
};

Map<String, String> transactionsTypes = {
  'in': getText('in'),
  'out': getText('out'),
};

Map<String, String> transactionsTypesSearch = {
  'tout': getText('tout'),
  'in': getText('in'),
  'out': getText('out'),
};

Map<String, String> unitsTypesSearch = {
  'tout': getText('tout'),
  'intern': getText('intern'),
  'extern': getText('extern'),
};

List<String> selectTransactionType = [
  getText('special'),
  getText('user'),
  getText('loan'),
  getText('deposit'),
  getText('allUsers'),
];

Map<String, String> compts = {
  'caisse': getText('caisse'),
  'reserve': getText('reserve'),
  'reserveProfit': getText('reserveProfit'),
  'donation': getText('donation'),
  'zakat': getText('zakat'),
};

Map<String, String> comptsSearch = {
  'tout': getText('tout'),
  'caisse': getText('caisse'),
  'reserve': getText('reserve'),
  'reserveProfit': getText('reserveProfit'),
  'donation': getText('donation'),
  'zakat': getText('zakat'),
};

Map<String, String> transactionsCategorys = {
  'caisse': getText('caisse'),
  'users': getText('users'),
  'loans': getText('loans'),
  'deposits': getText('deposits'),
  'specials': getText('specials'),
};

Map<String, String> constans = {
  'tout': 'Tout',
  'global': 'Global',
  'money': 'Money',
  'effort': 'Effort',
  'both': 'Both',
  'in': 'Entrie',
  'out': 'Sortie',
  'capital': 'Capital',
  'capitalUsers': 'Capital Users',
  'capitalUnits': 'Capital Units',
  'caisse': 'Caisse',
  'reserve': 'Reserve',
  'donation': 'Donation',
  'zakat': 'Zakat',
  'units': 'Units',
  'users': 'Users',
  'user': 'User',
  'otherUsers': 'Other Users',
  'otherUser': 'Other User',
  'specials': 'Specials',
  'special': 'Special',
  'dashboard': 'Dashboard',
  'transaction': 'Transaction',
  'profitHistory': 'Profit History',
  'userHistory': 'User History',
  'unitHistory': 'Unit History',
  'consultation': 'Consultation',
  'category': 'Category',
  'name': 'Name',
  'amount': 'Amount',
  'type': 'Type',
  'date': 'Date',
  'note': 'Note',
  'save': 'Save',
  'unit': 'Unit',
  'thresholdFounding': 'Threshold Founding',
  'threshold': 'Threshold',
  'founding': 'Founding',
  'joinDate': 'Join Date',
  'phone': 'Phone',
  'percentage': 'Percentage',
  'evaluation': 'Evaluation',
  'confirm': 'Confirm',
  'add': 'Add',
  'newUnit': 'New Unit',
  'newTransaction': 'New Transaction',
  'newUser': 'New User',
  'listOfUnit': 'List of Unit',
  'year': 'Year',
  'soldeUser': 'Solde User',
  'soldeCaisse': 'Solde Caisse',
  'solde': 'Solde',
  'search': 'Search ...',
  'from': 'From',
  'to': 'To',
  'rawProfit': 'Raw Profit',
  'netProfit': 'Net Profit',
  'profitability': 'Profitability',
  'unitProfitability': 'Unit Profitability',
  'startCapital': 'Start Capital',
  'initialCapital': 'Initial Capital',
  'weightedCapital': 'Weighted Capital',
  'total': 'Total',
  'totalIn': 'Total Entrie',
  'totalOut': 'Total Sortie',
  'totalLoan': 'Total Laon',
  'totalDeposit': 'Total Deposit',
  'moneyProfit': 'Money Profit',
  'thresholdProfit': 'Threshold Profit',
  'foundingProfit': 'Founding Profit',
  'effortProfit': 'Effort Profit',
  'totalProfit': 'Total Profit',
  'emptyList': 'No Data To Show!!',
  'deleteConfirmation': 'Delete Confirmation',
  'intern': 'Intern',
  'extern': 'Extern',
  'totalCapital': 'Total Capital',
  'count': 'Count',
  'deposit': 'Deposit',
  'deposits': 'Deposits',
  'loan': 'Loan',
  'rest': 'Rest',
  'loans': 'Loans',
  'source': 'Source',
  'password': 'Password',
  'info': 'Information',
  'effortUnit': 'Effort Unit',
  'effortGlobal': 'Effort Global',
  'month': 'Month',
  'profit': 'Profit',
  'reserveIsPartner': 'Reserve Is Partner',
  'reserveProfit': 'Reserve Profit',
  'true': 'True',
  'false': 'False',
  'allUsers': 'All Users',
  'moneyExtern': 'Money Extern',
  'reference': 'Reference',
  'unitsProfitability': 'Units Profitability',
};

Map<String, String> messages = {
  'wrongPassword': 'Wrong Password!!',
  'addUser': 'User added successfully',
  'updateUser': 'User updated successfully',
  'deleteUser': 'User deleted successfully',
  'deleteUserConfirmation':
      'Are you sure you want to delete this user, once deleted all related information will be deleted as well',
  'deleteOtherUserConfirmation': 'Are you sure you want to delete this user!!',
  'deleteUnitConfitmation':
      'Are you sure you want to delete this unit, once deleted all related information will be deleted as well',
  'addUnit': 'Unit added successfully',
  'updateUnit': 'Unit updated successfully',
  'deleteUnit': 'Unit deleted successfully',
  'addTransaction': 'Transaction added successfully',
  'emptyName': 'Name can not be empty!!!',
  'existName': 'Name already exist!!!',
  'deleteItem': 'Are you sure you want to delete this item',
  'checkData': 'Check your data!!!',
  'zeroValue': 'Value can not be zero!!',
  'zeroAmount': 'Amount can not be zero!!!',
  'restZero': 'Rest must be >= 0',
  'capitalZero': 'Capital must be >= 0',
  'soldeZero': 'Solde must be >= 0',
  'soldeCaisseZero': 'Solde Caisse must be >= 0',
  'checkName': 'Check The Name',
  'amountTotalUserCapital': 'amount > total users capitals',
};

String getText(String key) => constans[key] ?? '';

String getMessage(String key) => messages[key] ?? '';

String getKeyFromValue(String value) {
  return constans.keys.firstWhere((key) => constans[key] == value, orElse: () => '');
}
