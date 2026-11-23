part of '../home.dart';

const _defaultAccountId = 'main';
const _allExpenses = 'all-expenses';

enum _EntryKind { expense, income, transfer }

enum _AccountKind {
  cash('Cash', Icons.payments_outlined),
  bank('Bank', Icons.account_balance_outlined),
  credit('Credit card', Icons.credit_card_outlined),
  savings('Savings', Icons.savings_outlined);

  const _AccountKind(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _Account {
  const _Account(this.id, this.name, this.kind, this.opening);

  final String id;
  final String name;
  final _AccountKind kind;
  final int opening;

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'kind': kind.name,
    'opening': opening,
  };

  factory _Account.fromJson(Map<String, dynamic> json) => _Account(
    json['id'] as String,
    json['name'] as String,
    _AccountKind.values.byName(json['kind'] as String),
    json['opening'] as int,
  );
}

class _Goal {
  const _Goal(this.id, this.name, this.target, this.saved, this.due);

  final String id;
  final String name;
  final int target;
  final int saved;
  final DateTime? due;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'target': target,
    'saved': saved,
    'due': due?.toIso8601String(),
  };

  factory _Goal.fromJson(Map<String, dynamic> json) => _Goal(
    json['id'] as String,
    json['name'] as String,
    json['target'] as int,
    json['saved'] as int,
    DateTime.tryParse(json['due'] as String? ?? ''),
  );
}

enum _Frequency {
  once('One time'),
  weekly('Weekly'),
  monthly('Monthly'),
  yearly('Yearly');

  const _Frequency(this.label);
  final String label;
}

class _ScheduledEntry {
  const _ScheduledEntry({
    required this.id,
    required this.template,
    required this.frequency,
    this.occurrence = 0,
  });

  final String id;
  final Transaction template;
  final _Frequency frequency;
  final int occurrence;

  DateTime get due {
    final start = template.date;
    return switch (frequency) {
      _Frequency.once => start,
      _Frequency.weekly => DateTime(
        start.year,
        start.month,
        start.day + 7 * occurrence,
      ),
      _Frequency.monthly => _clampedDate(
        start.year,
        start.month + occurrence,
        start.day,
      ),
      _Frequency.yearly => _clampedDate(
        start.year + occurrence,
        start.month,
        start.day,
      ),
    };
  }

  static DateTime _clampedDate(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, min(day, lastDay));
  }

  _ScheduledEntry get next => _ScheduledEntry(
    id: id,
    template: template,
    frequency: frequency,
    occurrence: occurrence + 1,
  );

  Transaction toTransaction() => Transaction(
    id: 'scheduled-$id-$occurrence',
    description: template.description,
    amount: template.amount,
    isExpense: template.isExpense,
    categoryId: template.categoryId,
    date: due,
    accountId: template.accountId,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'template': template.toJson(),
    'frequency': frequency.name,
    'occurrence': occurrence,
  };

  factory _ScheduledEntry.fromJson(Map<String, dynamic> json) =>
      _ScheduledEntry(
        id: json['id'] as String,
        template: Transaction.fromJson(
          json['template'] as Map<String, dynamic>,
        ),
        frequency: _Frequency.values.byName(json['frequency'] as String),
        occurrence: json['occurrence'] as int,
      );
}

class _Ledger {
  const _Ledger({
    this.transactions = const [],
    this.accounts = const [
      _Account(_defaultAccountId, 'Main account', _AccountKind.cash, 0),
    ],
    this.budgets = const {},
    this.periodBudgets = const {},
    this.goals = const [],
    this.schedule = const [],
  });

  final List<Transaction> transactions;
  final List<_Account> accounts;
  final Map<String, int> budgets;
  final Map<String, Map<String, int>> periodBudgets;
  final List<_Goal> goals;
  final List<_ScheduledEntry> schedule;

  _Ledger copyWith({
    List<Transaction>? transactions,
    List<_Account>? accounts,
    Map<String, int>? budgets,
    Map<String, Map<String, int>>? periodBudgets,
    List<_Goal>? goals,
    List<_ScheduledEntry>? schedule,
  }) => _Ledger(
    transactions: transactions ?? this.transactions,
    accounts: accounts ?? this.accounts,
    budgets: budgets ?? this.budgets,
    periodBudgets: periodBudgets ?? this.periodBudgets,
    goals: goals ?? this.goals,
    schedule: schedule ?? this.schedule,
  );

  Map<String, Object> toJson() => {
    'version': 1,
    'transactions': transactions.map((entry) => entry.toJson()).toList(),
    'accounts': accounts.map((account) => account.toJson()).toList(),
    'budgets': budgets,
    if (periodBudgets.isNotEmpty) 'periodBudgets': periodBudgets,
    'goals': goals.map((goal) => goal.toJson()).toList(),
    'schedule': schedule.map((entry) => entry.toJson()).toList(),
  };

  factory _Ledger.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unsupported ledger version');
    }
    return _Ledger(
      transactions: _readList(json, 'transactions', Transaction.fromJson),
      accounts: _readList(json, 'accounts', _Account.fromJson),
      budgets: Map<String, int>.from(json['budgets'] as Map),
      periodBudgets: {
        for (final entry
            in (json['periodBudgets'] as Map<String, dynamic>? ?? {}).entries)
          entry.key: Map<String, int>.from(entry.value as Map),
      },
      goals: _readList(json, 'goals', _Goal.fromJson),
      schedule: _readList(json, 'schedule', _ScheduledEntry.fromJson),
    );
  }

  String transactionCsv(List<Category> categories, Currency currency) {
    final rows = <List<String>>[
      [
        'Date',
        'Type',
        'Amount',
        'Currency',
        'Category',
        'Account',
        'Destination',
        'Note',
      ],
      for (final entry in [...transactions]
        ..sort((a, b) => b.date.compareTo(a.date)))
        [
          DateFormat('yyyy-MM-dd').format(entry.date),
          entry._kind.name,
          entry.amount.toStringAsFixed(2),
          currency.name,
          categories
                  .where((category) => category.id == entry.categoryId)
                  .firstOrNull
                  ?.name ??
              '',
          _accountName(entry.accountId),
          entry.destinationId == null ? '' : _accountName(entry.destinationId!),
          entry.description ?? '',
        ],
    ];
    return rows.map((row) => row.map(_csvCell).join(',')).join('\r\n');
  }

  String _accountName(String id) =>
      accounts.where((account) => account.id == id).firstOrNull?.name ??
      'Account';

  static final _spreadsheetFormula = RegExp(r'^[\s]*[=+\-@]|^[\t\r\n]');

  static String _csvCell(String value) {
    final unsafe = _spreadsheetFormula.hasMatch(value);
    final escaped = unsafe ? "'$value" : value;
    return '"${escaped.replaceAll('"', '""')}"';
  }

  Map<String, int> balances(DateTime through) {
    final result = {
      for (final account in accounts) account.id: account.opening,
    };
    for (final entry in transactions) {
      if (DateUtils.dateOnly(entry.date).isAfter(through)) continue;
      final amount = _minor(entry.amount);
      result.update(
        entry.accountId,
        (balance) =>
            balance + (entry.isExpense || entry.isTransfer ? -amount : amount),
      );
      if (entry.destinationId case final destination?) {
        result.update(destination, (balance) => balance + amount);
      }
    }
    return result;
  }

  _Ledger record(_ScheduledEntry entry) {
    if (!schedule.contains(entry)) return this;
    final transaction = entry.toTransaction();
    return copyWith(
      transactions: [
        if (!transactions.any((item) => item.id == transaction.id)) transaction,
        ...transactions,
      ],
      schedule: [
        for (final item in schedule)
          if (item != entry)
            item
          else if (item.frequency != _Frequency.once)
            item.next,
      ],
    );
  }
}

List<T> _readList<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) decode,
) => (json[key] as List).cast<Map<String, dynamic>>().map(decode).toList();

int _minor(double amount) => (amount * 100).round();

int? _parseMoney(String value) {
  final match = RegExp(
    r'^(-?)(\d{1,10})(?:[.,](\d{1,2}))?$',
  ).firstMatch(value.trim());
  if (match == null) return null;
  final whole = int.parse(match[2]!);
  final fraction = int.parse((match[3] ?? '').padRight(2, '0'));
  return (whole * 100 + fraction) * (match[1] == '-' ? -1 : 1);
}

String _moneyText(int amount) => (amount / 100).toStringAsFixed(2);

String _identifier() =>
    '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';

bool _inMonth(DateTime date, DateTime month) =>
    date.year == month.year && date.month == month.month;

class _CashFlow {
  _CashFlow(Iterable<Transaction> transactions) {
    for (final entry in transactions) {
      if (entry.isTransfer) continue;
      final amount = _minor(entry.amount);
      if (entry.isExpense) {
        addExpense(entry.categoryId, amount);
      } else {
        income += amount;
      }
    }
  }

  void addExpense(String category, int amount) {
    spent += amount;
    expenseByCategory.update(
      category,
      (value) => value + amount,
      ifAbsent: () => amount,
    );
  }

  int spent = 0;
  int income = 0;
  final expenseByCategory = <String, int>{};
  int get net => income - spent;
}
