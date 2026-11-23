part of '../home.dart';

// --- Main Page with Navigation (Manages App State) ---

class MainPage extends StatefulWidget {
  const MainPage({
    super.key,
    this.themeMode = ThemeMode.system,
    this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final Future<bool> Function(ThemeMode)? onThemeModeChanged;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  _Destination _destination = _Destination.overview;
  _Tools _tools = _Tools.menu;
  _PlanSection _planSection = _PlanSection.budgets;
  _BudgetPeriod _budgetPeriod = _BudgetPeriod.daily;
  DateTime _budgetDate = DateTime.now();
  DateTime _reportMonth = DateTime.now();
  final _search = TextEditingController();
  String _query = '';
  _EntryKind? _kindFilter;
  final _pendingUndo = <Transaction>{};
  String? _accountFilter;
  String? _categoryFilter;
  DateTimeRange? _activityRange;
  bool _loadError = false;
  _Ledger _ledger = const _Ledger();
  List<Transaction> get _transactions => _ledger.transactions;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Category> _categories = [];
  List<Loan> _loans = [];
  List<FixedDeposit> _fixedDeposits = [];
  double _savingsPot = 0.0;
  // Settings
  Currency _selectedCurrency = Currency.USD;
  bool _includeFixedDepositsInBalance = false;
  bool _includeSavingsInBalance = false;
  String _nickname = "Nickname"; // NEW
  DateTime? _installDate; // NEW
  String? _profileImagePath; // NEW: To store the path of the profile image
  double? _dailyLimit; // NEW: State for daily limit

  bool _isLoading = true; // To show a loading indicator
  final _persistenceService = _PersistenceService();

  Future<void> _loadData() async {
    try {
      final ledger = await _persistenceService.loadLedger();
      final categories = await _persistenceService.loadCategories();
      final loans = await _persistenceService.loadLoans();
      final fixedDeposits = await _persistenceService.loadFixedDeposits();
      final savingsPot = await _persistenceService.loadSavingsPot();
      final settings = await _persistenceService.loadSettings();
      final nickname = await _persistenceService.loadNickname();
      var installDate = await _persistenceService.loadInstallDate();
      final profileImagePath = await _persistenceService.loadProfileImagePath();
      final dailyLimit = await _persistenceService.loadDailyLimit();
      if (installDate == null) {
        installDate = DateTime.now();
        await _persistenceService.saveInstallDate(installDate);
      }
      if (!mounted) return;
      setState(() {
        _ledger = ledger;
        _categories =
            categories.isNotEmpty ? categories : _getDefaultCategories();
        _loans = loans;
        _fixedDeposits = fixedDeposits;
        _savingsPot = savingsPot;
        _selectedCurrency = settings['currency'] ?? Currency.USD;
        _includeFixedDepositsInBalance =
            settings['includeFixedDeposits'] ?? false;
        _includeSavingsInBalance = settings['includeSavings'] ?? false;
        _nickname = nickname;
        _installDate = installDate;
        _profileImagePath = profileImagePath;
        _dailyLimit = dailyLimit;
        _loadError = false;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadError = true);
    }
  }

  List<Category> _getDefaultCategories() {
    return [
      // --- Default Income Categories ---
      Category(
        id: 'salary',
        name: 'Salary',
        color: Colors.green,
        icon: Icons.work_outline_rounded,
        isExpense: false,
      ),
      Category(
        id: 'part_time',
        name: 'Part-time',
        color: Colors.lightGreen,
        icon: Icons.watch_later_outlined,
        isExpense: false,
      ),
      Category(
        id: 'bank',
        name: 'Bank',
        color: Colors.teal,
        icon: Icons.account_balance_rounded,
        isExpense: false,
      ),
      Category(
        id: 'gifts',
        name: 'Gifts',
        color: Colors.pinkAccent,
        icon: Icons.card_giftcard_rounded,
        isExpense: false,
      ),
      Category(
        id: 'other_income',
        name: 'Other Income',
        color: Colors.grey,
        icon: Icons.more_horiz_rounded,
        isExpense: false,
      ),

      // --- Default Expense Categories ---
      Category(
        id: 'food',
        name: 'Food',
        color: Colors.orange,
        icon: Icons.fastfood_rounded,
        isExpense: true,
      ),
      Category(
        id: 'transport',
        name: 'Transport',
        color: Colors.blue,
        icon: Icons.directions_car_rounded,
        isExpense: true,
      ),
      Category(
        id: 'shopping',
        name: 'Shopping',
        color: Colors.pink,
        icon: Icons.shopping_bag_rounded,
        isExpense: true,
      ),
      Category(
        id: 'bills',
        name: 'Bills',
        color: Colors.deepPurple,
        icon: Icons.receipt_long_rounded,
        isExpense: true,
      ),
      Category(
        id: 'entertainment',
        name: 'Entertainment',
        color: Colors.purple,
        icon: Icons.movie_rounded,
        isExpense: true,
      ),
      Category(
        id: 'other_expense',
        name: 'Other',
        color: Colors.grey,
        icon: Icons.category_rounded,
        isExpense: true,
      ),
    ];
  }

  List<Transaction> get _sortedTransactions =>
      [..._transactions]..sort((a, b) => b.date.compareTo(a.date));

  List<_ScheduledEntry> get _sortedSchedule =>
      [..._ledger.schedule]..sort((a, b) => a.due.compareTo(b.due));

  Category? _category(String id) =>
      _categories.where((item) => item.id == id).firstOrNull;
  String _accountName(String id) => _ledger._accountName(id);
  int get _trackedBalance => _ledger
      .balances(DateUtils.dateOnly(DateTime.now()))
      .values
      .fold(0, (sum, amount) => sum + amount);

  String _budgetName(String id) =>
      id == _allExpenses
          ? 'All expenses'
          : _category(id)?.name ?? 'Uncategorized';

  String _money(int amount) => NumberFormat.currency(
    symbol: '$currencySymbol ',
    decimalDigits: 2,
  ).format(amount / 100);

  void _navigate(_Destination destination) => setState(() {
    _destination = destination;
    if (destination == _Destination.tools) _tools = _Tools.menu;
  });

  void _openTools(_Tools tools) => setState(() {
    _destination = _Destination.tools;
    _tools = tools;
  });

  void _searchActivity(String query) => setState(() => _query = query);

  void _clearSearch() {
    _search.clear();
    _searchActivity('');
  }

  void _filterKind(_EntryKind? kind) => setState(() => _kindFilter = kind);

  void _openPlan(_PlanSection section) => setState(() {
    _destination = _Destination.plan;
    _planSection = section;
  });

  void _openBudgets(_BudgetPeriod period) => setState(() {
    _destination = _Destination.plan;
    _planSection = _PlanSection.budgets;
    _budgetPeriod = period;
    _budgetDate = DateTime.now();
  });

  void _selectBudgetPeriod(_BudgetPeriod period) =>
      setState(() => _budgetPeriod = period);

  void _moveBudgetDate(int direction) => setState(() {
    _budgetDate =
        direction == 0
            ? DateTime.now()
            : _budgetPeriod.move(_budgetDate, direction);
  });

  void _moveReport(int months) => setState(() {
    _reportMonth = DateTime(_reportMonth.year, _reportMonth.month + months);
  });

  void _showCategoryActivity(String category, DateTime month) => _openActivity(
    category: category,
    kind: _EntryKind.expense,
    range: DateTimeRange(
      start: DateTime(month.year, month.month),
      end: DateTime(month.year, month.month + 1, 0),
    ),
  );

  void _openActivity({
    String? category,
    _EntryKind? kind,
    DateTimeRange? range,
  }) {
    _search.clear();
    setState(() {
      _query = '';
      _destination = _Destination.activity;
      _kindFilter = kind;
      _accountFilter = null;
      _categoryFilter = category;
      _activityRange = range;
    });
  }

  void _commit(_Ledger ledger) {
    setState(() => _ledger = ledger);
    unawaited(_saveLedger(ledger));
  }

  Future<void> _saveLedger(_Ledger ledger) async {
    try {
      await _persistenceService.saveLedger(ledger);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Couldn’t save your changes on this device.'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _saveLedger(_ledger),
          ),
        ),
      );
    }
  }

  Future<void> _openEntry([Transaction? entry]) => _editEntry(entry: entry);

  Future<void> _editEntry({
    Transaction? entry,
    String? category,
    DateTime? date,
  }) async {
    final result = await _showEditor<Object>(
      context,
      _EntryEditor(
        state: this,
        entry: entry,
        initialCategory: category,
        initialDate: date,
      ),
    );
    if (!mounted) return;
    if (result is Transaction) {
      _commit(
        _ledger.copyWith(
          transactions: [
            if (entry == null) result,
            for (final item in _transactions)
              if (item.id == entry?.id) result else item,
          ],
        ),
      );
    } else if (result == false && entry != null) {
      _deleteTransaction(entry);
    }
  }

  void _deleteTransaction(Transaction transaction) {
    _commit(
      _ledger.copyWith(
        transactions:
            _transactions.where((item) => item.id != transaction.id).toList(),
      ),
    );
    _pendingUndo.add(transaction);
    final notice = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaction deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            if (!_pendingUndo.remove(transaction)) return;
            if (_transactions.any((item) => item.id == transaction.id)) return;
            final fallback =
                _categories
                    .where((item) => item.isExpense == transaction.isExpense)
                    .firstOrNull;
            final restored =
                transaction.isTransfer ||
                        _category(transaction.categoryId) != null
                    ? transaction
                    : transaction.copyWith(categoryId: fallback?.id);
            _commit(
              _ledger.copyWith(transactions: [restored, ..._transactions]),
            );
          },
        ),
      ),
    );
    unawaited(notice.closed.then((_) => _pendingUndo.remove(transaction)));
  }

  Future<void> _editAccount([_Account? account]) async {
    var name = account?.name ?? '';
    var opening = account == null ? '0' : _moneyText(account.opening);
    var kind = account?.kind ?? _AccountKind.cash;
    final isUsed =
        account != null &&
        ([..._transactions, ..._pendingUndo].any(
              (entry) =>
                  entry.accountId == account.id ||
                  entry.destinationId == account.id,
            ) ||
            _ledger.schedule.any(
              (entry) => entry.template.accountId == account.id,
            ));
    final canRemove =
        account != null && account.id != _defaultAccountId && !isUsed;
    final result = await _showEditor<Object>(
      context,
      Builder(
        builder:
            (context) => _Editor(
              title: account == null ? 'Add account' : 'Edit account',
              fields: [
                _NameField(
                  label: 'Account name',
                  initial: name,
                  onChanged: (value) => name = value,
                ),
                _select(
                  label: 'Account type',
                  value: kind,
                  items: _AccountKind.values.map((item) => (item, item.label)),
                  onChanged: (value) => kind = value!,
                ),
                _AmountField(
                  label: 'Opening balance',
                  symbol: currencySymbol,
                  initial: opening,
                  allowZero: true,
                  allowNegative: true,
                  onChanged: (value) => opening = value,
                ),
                Text(
                  'Use a negative opening balance for money you owe.',
                  style: TextStyle(color: context.colors.onSurfaceVariant),
                ),
                if (isUsed)
                  Text(
                    'This account has activity or a schedule.',
                    style: TextStyle(color: context.colors.onSurfaceVariant),
                  ),
              ],
              onSave:
                  () => Navigator.pop(
                    context,
                    _Account(
                      account?.id ?? _identifier(),
                      name.trim(),
                      kind,
                      _parseMoney(opening)!,
                    ),
                  ),
              onRemove: canRemove ? () => Navigator.pop(context, false) : null,
            ),
      ),
    );
    if (!mounted) return;
    if (result is _Account) {
      _commit(
        _ledger.copyWith(
          accounts: [
            for (final item in _ledger.accounts)
              if (item.id == account?.id) result else item,
            if (account == null) result,
          ],
        ),
      );
    } else if (result == false && canRemove) {
      if (_accountFilter == account.id) _accountFilter = null;
      _commit(
        _ledger.copyWith(
          accounts:
              _ledger.accounts.where((item) => item.id != account.id).toList(),
        ),
      );
    }
  }

  Future<void> _editBudget({String? category, String? suggested}) async {
    const custom = 'new-category';
    final period = _budgetPeriod;
    final date = _budgetDate;
    final oneTime = _ledger._budgetBucket(period, date, false);
    final editing = category != null;
    var repeats = editing ? !oneTime.containsKey(category) : true;
    final expenses = _categories.where((item) => item.isExpense).toList();
    final proposals = {
      for (final (id, name, color, icon) in _mealCategories)
        if (_category(id) == null &&
            !expenses.any(
              (item) => item.name.toLowerCase() == name.toLowerCase(),
            ))
          id: Category(
            id: id,
            name: name,
            color: color,
            icon: icon,
            isExpense: true,
          ),
    };
    final choices = [
      (_allExpenses, 'All expenses'),
      for (final item in proposals.values) (item.id, item.name),
      for (final item in expenses) (item.id, item.name),
      (custom, 'Create a category'),
    ];
    var selected = category ?? suggested ?? _allExpenses;
    var name = '';
    final initial = _ledger._budgetBucket(period, date, repeats)[selected];
    var amount = initial == null ? '' : _moneyText(initial);

    final result = await _showEditor<Object>(
      context,
      StatefulBuilder(
        builder: (context, update) {
          final current =
              _ledger._budgetBucket(period, date, repeats)[selected];
          void changeLimit(String id, bool repeat) {
            update(() {
              selected = id;
              repeats = repeat;
              final limit = _ledger._budgetBucket(period, date, repeats)[id];
              amount = limit == null ? '' : _moneyText(limit);
            });
          }

          return _Editor(
            title:
                editing
                    ? 'Edit ${period.label.toLowerCase()} limit'
                    : 'Set ${period.label.toLowerCase()} limit',
            fields: [
              if (editing)
                Text(
                  _budgetName(selected),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                )
              else
                _select(
                  label: 'Budget category',
                  value: selected,
                  items: choices,
                  onChanged: (id) => changeLimit(id!, repeats),
                ),
              if (selected == custom)
                _NameField(
                  label: 'Category name',
                  onChanged: (value) => name = value.trim(),
                  validateName:
                      (name) =>
                          expenses.any(
                                (item) =>
                                    item.name.toLowerCase() ==
                                    name.toLowerCase(),
                              )
                              ? 'Choose a different name. This category exists.'
                              : null,
                ),
              if (!editing)
                _select(
                  label: 'Apply to',
                  value: repeats,
                  items: [
                    (true, 'Every ${period.unit}'),
                    (false, 'Only this ${period.unit}'),
                  ],
                  onChanged: (repeat) => changeLimit(selected, repeat!),
                ),
              _AmountField(
                key: ValueKey((selected, repeats)),
                label: '${period.label} limit',
                symbol: currencySymbol,
                initial: amount,
                onChanged: (value) => amount = value,
              ),
              Text(
                repeats
                    ? 'Repeats every ${period.unit}.'
                    : 'Applies to ${period.dateLabel(date)}.',
                style: TextStyle(color: context.colors.onSurfaceVariant),
              ),
              if (!editing && current != null)
                Text(
                  'Saving updates the existing limit.',
                  style: TextStyle(color: context.colors.onSurfaceVariant),
                ),
            ],
            onSave: () => Navigator.pop(context, _parseMoney(amount)!),
            onRemove: editing ? () => Navigator.pop(context, false) : null,
          );
        },
      ),
    );
    if (!mounted || result == null) return;
    if (result == false) {
      _commit(_ledger.updateBudget(period, date, repeats, selected, null));
      return;
    }

    final newCategory =
        selected == custom
            ? Category(
              id: _identifier(),
              name: name,
              color: const Color(0xFF17604A),
              icon: Icons.category_rounded,
              isExpense: true,
            )
            : proposals[selected];
    if (newCategory != null) {
      final categories = [..._categories, newCategory];
      try {
        await _persistenceService.saveCategories(categories);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Couldn’t save the new category.')),
          );
        }
        return;
      }
      if (!mounted) return;
      _categories = categories;
      selected = newCategory.id;
    }
    _commit(
      _ledger.updateBudget(period, date, repeats, selected, result as int),
    );
  }

  Future<void> _editGoal([_Goal? goal]) async {
    var name = goal?.name ?? '';
    var target = goal == null ? '' : _moneyText(goal.target);
    var saved = goal == null ? '0' : _moneyText(goal.saved);
    var due = goal?.due;
    final result = await _showEditor<Object>(
      context,
      StatefulBuilder(
        builder:
            (context, update) => _Editor(
              title: goal == null ? 'Add savings goal' : 'Edit savings goal',
              fields: [
                _NameField(
                  label: 'Goal name',
                  initial: name,
                  onChanged: (value) => name = value,
                ),
                _AmountField(
                  label: 'Target amount',
                  symbol: currencySymbol,
                  initial: target,
                  onChanged: (value) => target = value,
                ),
                _AmountField(
                  label: 'Amount set aside',
                  symbol: currencySymbol,
                  initial: saved,
                  allowZero: true,
                  onChanged: (value) => saved = value,
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.flag_outlined),
                      label: Text(
                        due == null
                            ? 'Add target date'
                            : DateFormat.yMMMd().format(due!),
                      ),
                      onPressed: () async {
                        final now = DateUtils.dateOnly(DateTime.now());
                        final date = await showDatePicker(
                          context: context,
                          initialDate: due ?? now,
                          firstDate: DateTime(1900),
                          lastDate: DateTime(now.year + 50, 12, 31),
                        );
                        if (date != null && context.mounted)
                          update(() => due = date);
                      },
                    ),
                    if (due != null)
                      TextButton(
                        onPressed: () => update(() => due = null),
                        child: const Text('Clear date'),
                      ),
                  ],
                ),
                Text(
                  'Goal progress is tracked separately from account balances.',
                  style: TextStyle(color: context.colors.onSurfaceVariant),
                ),
              ],
              onSave:
                  () => Navigator.pop(
                    context,
                    _Goal(
                      goal?.id ?? _identifier(),
                      name.trim(),
                      _parseMoney(target)!,
                      _parseMoney(saved)!,
                      due,
                    ),
                  ),
              onRemove:
                  goal == null ? null : () => Navigator.pop(context, false),
            ),
      ),
    );
    if (!mounted || result == null) return;
    _commit(
      _ledger.copyWith(
        goals: [
          for (final item in _ledger.goals)
            if (item.id != goal?.id) item else if (result is _Goal) result,
          if (goal == null && result is _Goal) result,
        ],
      ),
    );
  }

  Future<void> _openSchedule([_ScheduledEntry? entry]) async {
    final result = await _showEditor<Object>(
      context,
      _EntryEditor(state: this, schedule: entry, scheduling: true),
    );
    if (!mounted || result == null) return;
    _commit(
      _ledger.copyWith(
        schedule: [
          for (final item in _ledger.schedule)
            if (item.id != entry?.id)
              item
            else if (result is _ScheduledEntry)
              result,
          if (entry == null && result is _ScheduledEntry) result,
        ],
      ),
    );
  }

  Future<void> _scheduleActions(_ScheduledEntry entry, bool due) async {
    final record = await _showEditor<bool>(
      context,
      Builder(
        builder:
            (context) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (due)
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Record transaction'),
                  ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit schedule'),
                ),
              ],
            ),
      ),
    );
    if (!mounted) return;
    if (record == true) {
      _commit(_ledger.record(entry));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transaction recorded')));
    } else if (record == false) {
      await _openSchedule(entry);
    }
  }

  bool get _hasActivityFilters =>
      _accountFilter != null ||
      _categoryFilter != null ||
      _activityRange != null;

  Future<void> _filterActivity() async {
    var account = _accountFilter ?? '';
    var category = _categoryFilter ?? '';
    var range = _activityRange;
    final result = await _showEditor<(String, String, DateTimeRange?)>(
      context,
      StatefulBuilder(
        builder:
            (context, update) => _Editor(
              title: 'Filter activity',
              fields: [
                _select(
                  label: 'Account',
                  value: account,
                  items: [
                    ('', 'All accounts'),
                    for (final item in _ledger.accounts) (item.id, item.name),
                  ],
                  onChanged: (value) => account = value!,
                ),
                _select(
                  label: 'Category',
                  value: category,
                  items: [
                    ('', 'All categories'),
                    for (final item in _categories) (item.id, item.name),
                  ],
                  onChanged: (value) => category = value!,
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.date_range_outlined),
                      label: Text(
                        range == null
                            ? 'All dates'
                            : '${DateFormat.MMMd().format(range!.start)} – ${DateFormat.MMMd().format(range!.end)}',
                      ),
                      onPressed: () async {
                        final today = DateUtils.dateOnly(DateTime.now());
                        final selected = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(1900),
                          lastDate: today,
                          initialDateRange: range,
                        );
                        if (context.mounted && selected != null)
                          update(() => range = selected);
                      },
                    ),
                    if (range != null)
                      TextButton(
                        onPressed: () => update(() => range = null),
                        child: const Text('Clear dates'),
                      ),
                  ],
                ),
              ],
              onSave: () => Navigator.pop(context, (account, category, range)),
            ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _accountFilter = result.$1.isEmpty ? null : result.$1;
      _categoryFilter = result.$2.isEmpty ? null : result.$2;
      _activityRange = result.$3;
    });
  }

  Future<void> _exportCsv() async {
    final csv = _ledger.transactionCsv(_categories, _selectedCurrency);
    const filename = 'money-flow-transactions.csv';
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final cache = await getTemporaryDirectory();
        final exports = await Directory(
          '${cache.path}/exports',
        ).create(recursive: true);
        final folder = await exports.createTemp('transactions-');
        final file = await File(
          '${folder.path}/$filename',
        ).writeAsString(csv, flush: true);
        await const MethodChannel(
          'com.lekshan.moneyflow/export',
        ).invokeMethod<void>('shareCsv', file.path);
      } else {
        final documents = await getApplicationDocumentsDirectory();
        await File(
          '${documents.path}/$filename',
        ).writeAsString(csv, flush: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CSV saved in the app’s documents folder.'),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn’t export the transactions.')),
        );
      }
    }
  }

  // MODIFIED: Added isExpense parameter
  void _addCategory(String name, Color color, IconData icon, bool isExpense) {
    setState(() {
      _categories.add(
        Category(
          id: DateTime.now().toIso8601String(),
          name: name,
          color: color,
          icon: icon,
          isExpense: isExpense,
        ),
      );
    });
    _persistenceService.saveCategories(_categories);
  }

  void _updateCategory(Category category) {
    setState(() {
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
      }
    });
    _persistenceService.saveCategories(_categories);
  }

  void _deleteCategory(String id) {
    final category = _category(id);
    if (category == null) return;
    final alternatives = _categories.where(
      (item) => item.id != id && item.isExpense == category.isExpense,
    );
    final replacement =
        alternatives
            .where((item) => item.name.toLowerCase().startsWith('other'))
            .firstOrNull ??
        alternatives.firstOrNull;
    if (replacement == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keep at least one category of each type.'),
        ),
      );
      return;
    }
    _categories.removeWhere((item) => item.id == id);
    if (_categoryFilter == id) _categoryFilter = null;
    final budgets = {..._ledger.budgets}..remove(id);
    final periodBudgets = <String, Map<String, int>>{
      for (final bucket in _ledger.periodBudgets.entries)
        if (bucket.value.keys.any((category) => category != id))
          bucket.key: {...bucket.value}..remove(id),
    };
    _commit(
      _ledger.copyWith(
        transactions: [
          for (final entry in _transactions)
            if (entry.categoryId == id)
              entry.copyWith(categoryId: replacement.id)
            else
              entry,
        ],
        budgets: budgets,
        periodBudgets: periodBudgets,
        schedule: [
          for (final entry in _ledger.schedule)
            if (entry.template.categoryId == id)
              _ScheduledEntry(
                id: entry.id,
                template: entry.template.copyWith(categoryId: replacement.id),
                frequency: entry.frequency,
                occurrence: entry.occurrence,
              )
            else
              entry,
        ],
      ),
    );
    _persistenceService.saveCategories(_categories);
  }

  void _changeCurrency(Currency newCurrency) {
    setState(() {
      _selectedCurrency = newCurrency;
    });
    _saveSettings();
  }

  void _addFixedDeposit(FixedDeposit deposit) {
    setState(() {
      _fixedDeposits.add(deposit);
    });
    _persistenceService.saveFixedDeposits(_fixedDeposits);
  }

  void _addToSavingsPot(double amount) {
    setState(() {
      _savingsPot += amount;
    });
    _persistenceService.saveSavingsPot(_savingsPot);
  }

  void _addLoan(Loan loan) {
    setState(() {
      _loans.insert(0, loan);
    });
    _persistenceService.saveLoans(_loans);
  }

  void _toggleLoanStatus(Loan loan) {
    setState(() {
      final index = _loans.indexWhere((l) => l.id == loan.id);
      if (index != -1) {
        if (_loans[index].isPaid) {
          _loans[index].paidAmount = 0.0;
        } else {
          _loans[index].paidAmount = _loans[index].amount;
        }
      }
    });
    _persistenceService.saveLoans(_loans);
  }

  // NEW: Handle partial payments
  void _addLoanPayment(String loanId, double paymentAmount) {
    setState(() {
      final index = _loans.indexWhere((l) => l.id == loanId);
      if (index != -1) {
        _loans[index].paidAmount += paymentAmount;
        if (_loans[index].paidAmount > _loans[index].amount) {
          _loans[index].paidAmount = _loans[index].amount; // Cap at max
        }
      }
    });
    _persistenceService.saveLoans(_loans);
  }

  void _deleteLoan(String loanId) {
    setState(() {
      final index = _loans.indexWhere((l) => l.id == loanId);
      if (index != -1) {
        _loans[index].isDeleted = true;
        _loans[index].deletedDate = DateTime.now();
      }
    });
    _persistenceService.saveLoans(_loans);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Loan moved to Recycle Bin')));
  }

  void _restoreLoan(String loanId) {
    setState(() {
      final index = _loans.indexWhere((l) => l.id == loanId);
      if (index != -1) {
        _loans[index].isDeleted = false;
        _loans[index].deletedDate = null;
      }
    });
    _persistenceService.saveLoans(_loans);
  }

  void _permanentlyDeleteLoan(String loanId) {
    setState(() {
      _loans.removeWhere((l) => l.id == loanId);
    });
    _persistenceService.saveLoans(_loans);
  }

  void _saveSettings() {
    _persistenceService.saveSettings(
      currency: _selectedCurrency,
      includeFixedDeposits: _includeFixedDepositsInBalance,
      includeSavings: _includeSavingsInBalance,
    );
  }

  // --- NEW: Nickname, Profile Image, and Reset Handlers ---
  void _updateNickname(String newNickname) {
    setState(() {
      _nickname = newNickname;
    });
    _persistenceService.saveNickname(newNickname);
  }

  // NEW: Method to handle updating the profile image path
  void _updateProfileImage(String path) {
    setState(() {
      _profileImagePath = path;
    });
    _persistenceService.saveProfileImagePath(path);
  }

  // NEW: Method to handle updating the daily limit
  void _updateDailyLimit(double? limit) {
    setState(() {
      _dailyLimit = limit;
    });
    _persistenceService.saveDailyLimit(limit ?? 0.0);
  }

  Future<void> _resetTransactions() async {
    _commit(_ledger.copyWith(transactions: []));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transactions have been reset.')),
    );
  }

  Future<void> _resetDays() async {
    final newInstallDate = DateTime.now();
    setState(() => _installDate = newInstallDate);
    await _persistenceService.saveInstallDate(newInstallDate);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usage days have been reset.')),
    );
  }

  Future<void> _factoryReset() async {
    setState(() => _isLoading = true);
    try {
      await _persistenceService.clearAllData();
      if (!mounted) return;
      _query = '';
      _search.clear();
      _kindFilter = null;
      _pendingUndo.clear();
      ScaffoldMessenger.of(context).clearSnackBars();
      _accountFilter = null;
      _categoryFilter = null;
      _activityRange = null;
      await _loadData();
      if (mounted && !_loadError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('App has been reset to factory defaults.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _loadError = true);
    }
  }

  String get currencySymbol {
    switch (_selectedCurrency) {
      case Currency.USD:
        return '\$';
      case Currency.INR:
        return '₹';
      case Currency.AUD:
        return 'A\$';
      case Currency.EUR:
        return '€';
      case Currency.LKR:
        return 'Rs';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Couldn’t load your data.'),
              TextButton(
                onPressed: () {
                  setState(() => _loadError = false);
                  _loadData();
                },
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final inTool = _destination == _Destination.tools && _tools != _Tools.menu;
    return PopScope(
      canPop: !inTool,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && inTool) _openTools(_Tools.menu);
      },
      child: Scaffold(
        body: switch (_destination) {
          _Destination.overview => _Overview(state: this),
          _Destination.activity => _Activity(state: this),
          _Destination.plan => _Planning(state: this),
          _Destination.insights => _Insights(state: this),
          _Destination.tools => _buildTools(),
        },
        floatingActionButton:
            _destination == _Destination.overview ||
                    _destination == _Destination.activity
                ? FloatingActionButton(
                  onPressed: _openEntry,
                  tooltip: 'Add transaction',
                  child: const Icon(Icons.add_rounded),
                )
                : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _destination.index,
          onDestinationSelected:
              (index) => _navigate(_Destination.values[index]),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: 'Overview',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Activity',
            ),
            NavigationDestination(
              icon: Icon(Icons.track_changes_outlined),
              selectedIcon: Icon(Icons.track_changes_rounded),
              label: 'Plan',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Insights',
            ),
            NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
          ],
        ),
      ),
    );
  }

  Widget _buildTools() {
    final financialEntries =
        _transactions.where((entry) => !entry.isTransfer).toList();
    return switch (_tools) {
      _Tools.menu => _ToolsMenu(state: this),
      _Tools.wallet => WalletPage(
        trackedBalance: _trackedBalance / 100,
        transactions: financialEntries,
        currencySymbol: currencySymbol,
        fixedDeposits: _fixedDeposits,
        savingsPot: _savingsPot,
        onAddFixedDeposit: _addFixedDeposit,
        onAddToSavings: _addToSavingsPot,
        includeFixedDeposits: _includeFixedDepositsInBalance,
        includeSavings: _includeSavingsInBalance,
        onEditTransaction: _openEntry,
        onDeleteTransaction: _deleteTransaction,
        categories: _categories,
      ),
      _Tools.reports => StatsPage(
        transactions: financialEntries,
        currencySymbol: currencySymbol,
        categories: _categories,
      ),
      _Tools.loans => BudgetPage(
        currencySymbol: currencySymbol,
        loans: _loans,
        onAddLoan: _addLoan,
        onToggleLoanStatus: _toggleLoanStatus,
        onAddLoanPayment: _addLoanPayment,
        onDeleteLoan: _deleteLoan,
        onRestoreLoan: _restoreLoan,
        onPermanentlyDeleteLoan: _permanentlyDeleteLoan,
      ),
      _Tools.settings => ProfilePage(
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
        selectedCurrency: _selectedCurrency,
        onCurrencyChanged: _changeCurrency,
        transactionCount: _transactions.length,
        includeFixedDeposits: _includeFixedDepositsInBalance,
        includeSavings: _includeSavingsInBalance,
        onIncludeFixedDepositsChanged: (value) {
          setState(() => _includeFixedDepositsInBalance = value);
          _saveSettings();
        },
        onIncludeSavingsChanged: (value) {
          setState(() => _includeSavingsInBalance = value);
          _saveSettings();
        },
        categories: _categories,
        onAddCategory: _addCategory,
        onUpdateCategory: _updateCategory,
        onDeleteCategory: _deleteCategory,
        nickname: _nickname,
        installDate: _installDate,
        onNicknameChanged: _updateNickname,
        onResetTransactions: _resetTransactions,
        onResetDays: _resetDays,
        onFactoryReset: _factoryReset,
        profileImagePath: _profileImagePath,
        onProfileImageChanged: _updateProfileImage,
        dailyLimit: _dailyLimit,
        onDailyLimitChanged: _updateDailyLimit,
      ),
    };
  }
}
