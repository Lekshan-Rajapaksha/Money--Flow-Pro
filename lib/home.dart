import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io'; // NEW: For File operations
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';// NEW: For picking images from gallery

// A registry of all IconData that may be stored/loaded from JSON.
// This const map lets Flutter's tree-shaker know at compile time which
// icons the app can use, avoiding the "non-constant IconData" build error.
const Map<int, IconData> _kIconRegistry = {
  // income icons
  0xf02c6: Icons.work_outline_rounded,
  0xf4b1: Icons.watch_later_outlined,
  0xf51f: Icons.account_balance_rounded,
  0xf61a: Icons.card_giftcard_rounded,
  0xf8d9: Icons.more_horiz_rounded,
  // expense icons
  0xf736: Icons.fastfood_rounded,
  0xf016f: Icons.shopping_bag_rounded,
  0xf6b3: Icons.directions_car_rounded,
  0xf00e1: Icons.receipt_long_rounded,
  0xf8e7: Icons.movie_rounded,
  0xf624: Icons.category_rounded,
  // extra palette icons
  0xf7f5: Icons.home_rounded,
  0xf7df: Icons.health_and_safety_rounded,
  0xf012e: Icons.school_rounded,
  0xf0077: Icons.pets_rounded,
  0xf0078: Icons.phone_android_rounded,
  0xf773: Icons.flight_takeoff_rounded,
  0xf767: Icons.fitness_center_rounded,
  0xf8ed: Icons.music_note_rounded,
  0xf02c7: Icons.work_rounded,
  0xf02a3: Icons.watch_later_rounded,
  // misc icons used in the app
  0xf520: Icons.account_balance_wallet_rounded,
  0xe553: Icons.savings,
  0xf336: Icons.savings_outlined,
  0xe040: Icons.account_balance,
  0xf0071: Icons.person_rounded,
  0xe491: Icons.person,
  0xe402: Icons.more_horiz,
};

/// Returns the [IconData] for the given [codePoint].
/// Falls back to [Icons.category_rounded] if the code is not in the registry.
IconData _iconFromCodePoint(int codePoint) =>
    _kIconRegistry[codePoint] ?? Icons.category_rounded;

/// Represents a user-defined category for transactions.
class Category {
  final String id;
  String name;
  Color color;
  IconData icon;
  final bool isExpense; // NEW: Differentiates between income and expense

  Category({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.isExpense,
  });

  // Methods for JSON serialization for local storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color.value,
    'icon_code': icon.codePoint,
    'icon_font_family': icon.fontFamily,
    'icon_font_package': icon.fontPackage,
    'isExpense': isExpense, // NEW
  };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'],
    name: json['name'],
    color: Color(json['color']),
    icon: _iconFromCodePoint(json['icon_code'] as int),
    isExpense: json['isExpense'] ?? true, // NEW: Default to true for backward compatibility
  );
}



/// Represents a single financial transaction.
class Transaction {
  final String id; // Added for unique identification
  final String? description; // MODIFIED: Made optional
  final double amount;
  final bool isExpense;
  final String categoryId; // Changed from Enum to String ID
  final DateTime date;

  Transaction({
    this.description,
    required this.amount,
    required this.isExpense,
    required this.categoryId,
    required this.date,
    String? id, // Allow passing an ID for persistence
  }) : id = id ?? DateTime.now().toIso8601String() + Random().nextDouble().toString();

  // Copy constructor for editing
  Transaction copyWith({
    String? description,
    double? amount,
    bool? isExpense,
    String? categoryId,
    DateTime? date,
  }) {
    return Transaction(
      id: id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      isExpense: isExpense ?? this.isExpense,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
    );
  }

  // Methods for JSON serialization for local storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'amount': amount,
    'isExpense': isExpense,
    'categoryId': categoryId,
    'date': date.toIso8601String(),
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'],
    description: json['description'],
    amount: json['amount'],
    isExpense: json['isExpense'],
    categoryId: json['categoryId'],
    date: DateTime.parse(json['date']),
  );
}


/// Represents a loan, either given or taken.
class Loan {
  final String id;
  final String personName;
  final double amount;
  final String? reason;
  final LoanType type;
  final DateTime date;
  bool isPaid;
  bool isDeleted; // For recycle bin
  DateTime? deletedDate; // To track when it was deleted

  Loan({
    required this.personName,
    required this.amount,
    this.reason,
    required this.type,
    required this.date,
    this.isPaid = false,
    this.isDeleted = false,
    this.deletedDate,
    String? id,
  }) : id = id ?? DateTime.now().toIso8601String() + Random().nextDouble().toString();

  Loan copyWith({
    String? personName,
    double? amount,
    String? reason,
    LoanType? type,
    DateTime? date,
    bool? isPaid,
    bool? isDeleted,
    DateTime? deletedDate,
  }) {
    return Loan(
      id: id,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      type: type ?? this.type,
      date: date ?? this.date,
      isPaid: isPaid ?? this.isPaid,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedDate: deletedDate ?? this.deletedDate,
    );
  }

  // Methods for JSON serialization for local storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'personName': personName,
    'amount': amount,
    'reason': reason,
    'type': type.name,
    'date': date.toIso8601String(),
    'isPaid': isPaid,
    'isDeleted': isDeleted,
    'deletedDate': deletedDate?.toIso8601String(),
  };

  factory Loan.fromJson(Map<String, dynamic> json) => Loan(
    id: json['id'],
    personName: json['personName'],
    amount: json['amount'],
    reason: json['reason'],
    type: LoanType.values.byName(json['type']),
    date: DateTime.parse(json['date']),
    isPaid: json['isPaid'],
    isDeleted: json['isDeleted'],
    deletedDate: json['deletedDate'] != null ? DateTime.parse(json['deletedDate']) : null,
  );
}


/// Represents a single fixed deposit investment.
class FixedDeposit {
  final double amount;
  final DateTime maturityDate;

  FixedDeposit({required this.amount, required this.maturityDate});

  // Methods for JSON serialization for local storage
  Map<String, dynamic> toJson() => {
    'amount': amount,
    'maturityDate': maturityDate.toIso8601String(),
  };

  factory FixedDeposit.fromJson(Map<String, dynamic> json) => FixedDeposit(
    amount: json['amount'],
    maturityDate: DateTime.parse(json['maturityDate']),
  );
}

/// Enum for different currencies.
enum Currency { USD, INR, AUD, EUR, LKR }

/// Enum for loan types.
enum LoanType { given, taken }


// --- Main App Widget ---

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance App',
      theme: ThemeData(
          primarySwatch: Colors.indigo,
          fontFamily: 'Inter',
          scaffoldBackgroundColor: const Color(0xFFF4F6FA),
          appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF4F6FA),
              foregroundColor: Colors.black87,
              elevation: 0,
              titleTextStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87
              )
          )
      ),
      home: const MainPage(),
    );
  }
}


// --- Main Page with Navigation (Manages App State) ---

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // --- App-wide State Variables ---
  int _selectedIndex = 2; // Start on the revamped Budget/Loans page
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _loadData();
  }

  // Data lists
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  List<Loan> _loans = [];
  List<FixedDeposit> _fixedDeposits = [];
  double _savingsPot = 0.0;
  double _homeChartMaxY = 2000.0; // NEW: State for Home page chart limit

  // Settings
  Currency _selectedCurrency = Currency.USD;
  bool _includeFixedDepositsInBalance = false;
  bool _includeSavingsInBalance = false;
  String _nickname = "Nickname"; // NEW
  DateTime? _installDate; // NEW
  String? _profileImagePath; // NEW: To store the path of the profile image


  bool _isLoading = true; // To show a loading indicator
  final PersistenceService _persistenceService = PersistenceService();


  Future<void> _loadData() async {
    final transactions = await _persistenceService.loadTransactions();
    final categories = await _persistenceService.loadCategories();
    final loans = await _persistenceService.loadLoans();
    final fixedDeposits = await _persistenceService.loadFixedDeposits();
    final savingsPot = await _persistenceService.loadSavingsPot();
    final settings = await _persistenceService.loadSettings();
    final nickname = await _persistenceService.loadNickname();
    DateTime? installDate = await _persistenceService.loadInstallDate();
    final profileImagePath = await _persistenceService.loadProfileImagePath(); // NEW

    // NEW: If install date doesn't exist, it's the first launch. Set and save it.
    if (installDate == null) {
      installDate = DateTime.now();
      await _persistenceService.saveInstallDate(installDate);
    }


    setState(() {
      _transactions = transactions;
      // If no categories are saved, initialize with defaults
      _categories = categories.isNotEmpty ? categories : _getDefaultCategories();
      _loans = loans;
      _fixedDeposits = fixedDeposits;
      _savingsPot = savingsPot;
      _selectedCurrency = settings['currency'] ?? Currency.USD;
      _includeFixedDepositsInBalance = settings['includeFixedDeposits'] ?? false;
      _includeSavingsInBalance = settings['includeSavings'] ?? false;
      _nickname = nickname;
      _installDate = installDate;
      _profileImagePath = profileImagePath; // NEW
      _isLoading = false;
    });
  }

  List<Category> _getDefaultCategories() {
    return [
      // --- Default Income Categories ---
      Category(id: 'salary', name: 'Salary', color: Colors.green, icon: Icons.work_outline_rounded, isExpense: false),
      Category(id: 'part_time', name: 'Part-time', color: Colors.lightGreen, icon: Icons.watch_later_outlined, isExpense: false),
      Category(id: 'bank', name: 'Bank', color: Colors.teal, icon: Icons.account_balance_rounded, isExpense: false),
      Category(id: 'gifts', name: 'Gifts', color: Colors.pinkAccent, icon: Icons.card_giftcard_rounded, isExpense: false),
      Category(id: 'other_income', name: 'Other Income', color: Colors.grey, icon: Icons.more_horiz_rounded, isExpense: false),

      // --- Default Expense Categories ---
      Category(id: 'food', name: 'Food', color: Colors.orange, icon: Icons.fastfood_rounded, isExpense: true),
      Category(id: 'transport', name: 'Transport', color: Colors.blue, icon: Icons.directions_car_rounded, isExpense: true),
      Category(id: 'shopping', name: 'Shopping', color: Colors.pink, icon: Icons.shopping_bag_rounded, isExpense: true),
      Category(id: 'bills', name: 'Bills', color: Colors.deepPurple, icon: Icons.receipt_long_rounded, isExpense: true),
      Category(id: 'entertainment', name: 'Entertainment', color: Colors.purple, icon: Icons.movie_rounded, isExpense: true),
      Category(id: 'other_expense', name: 'Other', color: Colors.grey, icon: Icons.category_rounded, isExpense: true),
    ];
  }


  // --- Methods to update state ---
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _addTransaction(Transaction transaction) {
    setState(() {
      _transactions.insert(0, transaction);
    });
    _persistenceService.saveTransactions(_transactions);
  }

  void _editTransaction(Transaction oldTransaction, Transaction newTransaction) {
    setState(() {
      final index = _transactions.indexWhere((t) => t.id == oldTransaction.id);
      if (index != -1) {
        _transactions[index] = newTransaction;
      }
    });
    _persistenceService.saveTransactions(_transactions);
  }


  void _deleteTransaction(Transaction transaction) {
    final transactionIndex = _transactions.indexOf(transaction);
    setState(() {
      _transactions.remove(transaction);
    });
    _persistenceService.saveTransactions(_transactions);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaction deleted'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              _transactions.insert(transactionIndex, transaction);
            });
            _persistenceService.saveTransactions(_transactions);
          },
        ),
      ),
    );
  }

  // MODIFIED: Added isExpense parameter
  void _addCategory(String name, Color color, IconData icon, bool isExpense) {
    setState(() {
      _categories.add(Category(
        id: DateTime.now().toIso8601String(),
        name: name,
        color: color,
        icon: icon,
        isExpense: isExpense,
      ));
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
    setState(() {
      final categoryToDelete = _categories.firstWhere((c) => c.id == id);
      // Determine the correct "Other" category to move transactions to
      final defaultCategory = _categories.firstWhere(
            (c) => (c.isExpense == categoryToDelete.isExpense) && (c.name.toLowerCase().contains('other')),
        orElse: () => _categories.first,
      );

      // Re-assign transactions from the deleted category
      _transactions.where((t) => t.categoryId == id).forEach((t) {
        final index = _transactions.indexOf(t);
        _transactions[index] = t.copyWith(categoryId: defaultCategory.id);
      });

      // Remove the category
      _categories.removeWhere((c) => c.id == id);
    });
    _persistenceService.saveCategories(_categories);
    _persistenceService.saveTransactions(_transactions);
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

  void _toggleLoanStatus(String loanId) {
    setState(() {
      final index = _loans.indexWhere((l) => l.id == loanId);
      if (index != -1) {
        _loans[index].isPaid = !_loans[index].isPaid;
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Loan moved to Recycle Bin')),
    );
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

  // NEW: Method to handle updating the home page chart limit
  void _updateHomeChartMaxY(double newValue) {
    setState(() {
      _homeChartMaxY = newValue;
    });
  }

  Future<void> _resetTransactions() async {
    setState(() {
      _transactions = [];
    });
    await _persistenceService.clearTransactions();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transactions have been reset.')),
    );
  }

  Future<void> _resetDays() async {
    final newInstallDate = DateTime.now();
    setState(() {
      _installDate = newInstallDate;
    });
    await _persistenceService.saveInstallDate(newInstallDate);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usage days have been reset.')),
    );
  }

  Future<void> _factoryReset() async {
    await _persistenceService.clearAllData();
    // After clearing everything, reload the app state to get defaults
    setState(() {
      _isLoading = true;
    });
    await _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('App has been reset to factory defaults.')),
    );
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          StatsPage(transactions: _transactions, currencySymbol: currencySymbol, categories: _categories),
          WalletPage(
            transactions: _transactions,
            currencySymbol: currencySymbol,
            fixedDeposits: _fixedDeposits,
            savingsPot: _savingsPot,
            onAddFixedDeposit: _addFixedDeposit,
            onAddToSavings: _addToSavingsPot,
            includeFixedDeposits: _includeFixedDepositsInBalance,
            includeSavings: _includeSavingsInBalance,
            onEditTransaction: (transaction) => _showAddTransactionModal(context, transaction: transaction),
            onDeleteTransaction: _deleteTransaction,
            categories: _categories,
          ),
          HomePage(
            key: ValueKey(_transactions.length),
            transactions: _transactions,
            currencySymbol: currencySymbol,
            categories: _categories,
            selectedChartMaxY: _homeChartMaxY, // MODIFIED: Pass state down
            onChartMaxYChanged: _updateHomeChartMaxY, // MODIFIED: Pass callback down
          ),
          BudgetPage(
            currencySymbol: currencySymbol,
            loans: _loans,
            onAddLoan: _addLoan,
            onToggleLoanStatus: _toggleLoanStatus,
            onDeleteLoan: _deleteLoan,
            onRestoreLoan: _restoreLoan,
            onPermanentlyDeleteLoan: _permanentlyDeleteLoan,
          ),
          ProfilePage(
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
            profileImagePath: _profileImagePath, // NEW
            onProfileImageChanged: _updateProfileImage, // NEW
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        onAddTapped: () => _showAddTransactionModal(context),
      ),
    );
  }

  void _showAddTransactionModal(BuildContext context, {Transaction? transaction}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: AddTransactionForm(
            transactionToEdit: transaction,
            onAddTransaction: (newTransaction) {
              if (transaction != null) {
                _editTransaction(transaction, newTransaction);
              } else {
                _addTransaction(newTransaction);
              }
            },
            categories: _categories,
            currencySymbol: currencySymbol,
          ),
        ).animate().slide(begin: const Offset(0, 1), duration: 300.ms, curve: Curves.easeOut);
      },
    );
  }
}

// --- Home Page Widget (REVAMPED with Weekly Stats) ---

// A data class to hold prepared weekly chart data
class WeeklyChartData {
  final List<double> expenses;
  final List<double> incomes;
  final DateTime startDate;
  final DateTime endDate;

  WeeklyChartData({
    required this.expenses,
    required this.incomes,
    required this.startDate,
    required this.endDate,
  });
}

class HomePage extends StatefulWidget {
  final List<Transaction> transactions;
  final String currencySymbol;
  final List<Category> categories;
  final double selectedChartMaxY; // NEW: Receive state from parent
  final Function(double) onChartMaxYChanged; // NEW: Receive callback from parent

  const HomePage({
    super.key,
    required this.transactions,
    required this.currencySymbol,
    required this.categories,
    required this.selectedChartMaxY,
    required this.onChartMaxYChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // --- State Variables ---
  late PageController _chartPageController;
  final int _totalWeeksToShow = 52; // Show data for the last year
  List<WeeklyChartData> _weeklyData = [];
  int _currentWeekIndex = 0;

  bool _isShowingExpensesChart = true;
  // double _selectedChartMaxY = 2000; // REMOVED: State is now managed by MainPage
  final List<double> _chartMaxYOptions = [
    500, 1000, 2000, 5000, 10000, 20000
  ];

  @override
  void initState() {
    super.initState();
    _prepareWeeklyData();
    // Initialize the controller to show the latest week first
    _currentWeekIndex = _weeklyData.isNotEmpty ? _weeklyData.length - 1 : 0;
    _chartPageController = PageController(initialPage: _currentWeekIndex);
  }

  @override
  void dispose() {
    _chartPageController.dispose();
    super.dispose();
  }

  // --- Data Preparation ---
  void _prepareWeeklyData() {
    final List<WeeklyChartData> preparedData = [];
    final now = DateTime.now();

    for (int i = 0; i < _totalWeeksToShow; i++) {
      final dayOfWeek = now.weekday;
      final daysToSubtract = dayOfWeek - 1 + (i * 7);
      final weekStartDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract));
      final weekEndDate = weekStartDate.add(const Duration(days: 6));

      final weekTransactions = widget.transactions.where((t) {
        final transactionDate = DateTime(t.date.year, t.date.month, t.date.day);
        return !transactionDate.isBefore(weekStartDate) && !transactionDate.isAfter(weekEndDate);
      }).toList();

      List<double> weeklyExpenses = List.filled(7, 0.0);
      List<double> weeklyIncomes = List.filled(7, 0.0);

      for (var t in weekTransactions) {
        final dayIndex = t.date.weekday - 1;
        if (t.isExpense) {
          weeklyExpenses[dayIndex] += t.amount;
        } else {
          weeklyIncomes[dayIndex] += t.amount;
        }
      }

      preparedData.add(WeeklyChartData(
        expenses: weeklyExpenses,
        incomes: weeklyIncomes,
        startDate: weekStartDate,
        endDate: weekEndDate,
      ));
    }

    _weeklyData = preparedData.reversed.toList();
    _currentWeekIndex = _weeklyData.isNotEmpty ? _weeklyData.length - 1 : 0;
  }

  // --- Getters for calculated values ---

  // NEW: Getters specifically for the current week's data for top cards
  List<Transaction> get _currentWeekTransactions {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return widget.transactions.where((t) {
      final transactionDate = DateTime(t.date.year, t.date.month, t.date.day);
      return !transactionDate.isBefore(startOfWeek) && !transactionDate.isAfter(endOfWeek);
    }).toList();
  }

  double get _currentWeekIncome => _currentWeekTransactions
      .where((t) => !t.isExpense)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get _currentWeekExpenses => _currentWeekTransactions
      .where((t) => t.isExpense)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get _currentWeekSavings => _currentWeekIncome - _currentWeekExpenses;


  Category _getCategoryById(String id) {
    return widget.categories.firstWhere((cat) => cat.id == id,
        orElse: () => widget.categories.firstWhere((c) => c.name.toLowerCase() == 'other'));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                _buildSavingsCard(),
                const SizedBox(height: 16),
                _buildIncomeExpenseRow(),
                const SizedBox(height: 24),
                _buildWeeklyChartCard(),
                const SizedBox(height: 24),
                _buildSectionHeader("Recent Transactions"),
                const SizedBox(height: 8),
                _buildTransactionsList(),
              ],
            ).animate().fadeIn(duration: 500.ms),
          ),
        ),
      ),
    );
  }

  // --- Builder Widgets ---

  Widget _buildSavingsCard() {
    return CustomCard(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo, Colors.indigo.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // UPDATED LABEL
            const Text("This Week's Net Savings",
                style: TextStyle(fontSize: 18, color: Colors.white70)),
            const SizedBox(height: 10),
            Text(
              // UPDATED VALUE
              '${widget.currencySymbol}${_currentWeekSavings.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: -1.0, duration: 600.ms, curve: Curves.easeOut).fadeIn();
  }

  Widget _buildIncomeExpenseRow() {
    return Row(
      children: [
        Expanded(
          child: CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.greenAccent,
                    child: Icon(Icons.arrow_downward, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // UPDATED LABEL
                      const Text('Income', style: TextStyle(color: Colors.grey)),
                      Text(
                        // UPDATED VALUE
                        '${widget.currencySymbol}${_currentWeekIncome.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.arrow_upward, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // UPDATED LABEL
                      const Text('Expenses',
                          style: TextStyle(color: Colors.grey)),
                      Text(
                        // UPDATED VALUE
                        '${widget.currencySymbol}${_currentWeekExpenses.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate(delay: 100.ms).slideY(begin: 0.5, duration: 600.ms, curve: Curves.easeOut).fadeIn();
  }

  Widget _buildWeeklyChartCard() {
    if (_weeklyData.isEmpty) {
      return const CustomCard(child: SizedBox(height: 250, child: Center(child: Text("No chart data"))));
    }

    final currentWeek = _weeklyData[_currentWeekIndex];
    String dateRangeTitle =
        '${DateFormat.MMMd().format(currentWeek.startDate)} - ${DateFormat.MMMd().format(currentWeek.endDate)}';
    if (currentWeek.startDate.year != currentWeek.endDate.year) {
      dateRangeTitle =
      '${DateFormat.yMMMd().format(currentWeek.startDate)} - ${DateFormat.yMMMd().format(currentWeek.endDate)}';
    }


    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        _isShowingExpensesChart
                            ? "Weekly Expenses"
                            : "Weekly Income",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(dateRangeTitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                _buildChartTypeToggle(),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _chartPageController,
                itemCount: _weeklyData.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentWeekIndex = index;
                  });
                },
                itemBuilder: (context, pageIndex) {
                  final weekData = _weeklyData[pageIndex];
                  final chartData = _isShowingExpensesChart ? weekData.expenses : weekData.incomes;
                  final barColor = _isShowingExpensesChart ? Colors.indigo.shade300 : Colors.green.shade300;
                  final trackColor = Colors.grey.shade200;

                  return BarChart(
                    BarChartData(
                      maxY: widget.selectedChartMaxY * 1.1, // MODIFIED: Use property from widget
                      alignment: BarChartAlignment.spaceAround,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${widget.currencySymbol}${rod.toY.toStringAsFixed(0)}',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return Text('${widget.currencySymbol} 0', style: const TextStyle(color: Colors.grey, fontSize: 10));
                              if (value == widget.selectedChartMaxY * 0.25 || value == widget.selectedChartMaxY * 0.5 || value == widget.selectedChartMaxY * 0.75 || value == widget.selectedChartMaxY) {
                                return Text(
                                  '${widget.currencySymbol} ${value.toInt()}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const style = TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold);
                              String text;
                              switch (value.toInt()) {
                                case 0: text = 'Mon'; break;
                                case 1: text = 'Tue'; break;
                                case 2: text = 'Wed'; break;
                                case 3: text = 'Thu'; break;
                                case 4: text = 'Fri'; break;
                                case 5: text = 'Sat'; break;
                                case 6: text = 'Sun'; break;
                                default: text = ''; break;
                              }
                              return Text(text, style: style);
                            },
                            reservedSize: 28,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      barGroups: chartData.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                                toY: entry.value,
                                color: barColor,
                                width: 16,
                                borderRadius: const BorderRadius.all(Radius.circular(6)),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: widget.selectedChartMaxY, // MODIFIED: Use property from widget
                                  color: trackColor,
                                )
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    duration: 500.ms,
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Daily Limit:", style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 10),
                DropdownButton<double>(
                  value: widget.selectedChartMaxY, // MODIFIED: Use property from widget
                  underline: Container(), // Hides the default underline
                  items: _chartMaxYOptions.map((double value) {
                    return DropdownMenuItem<double>(
                      value: value,
                      child: Text('${widget.currencySymbol}${value.toInt()}'),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      widget.onChartMaxYChanged(newValue); // MODIFIED: Call callback from widget
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: 400.ms).slideY(begin: 0.5, duration: 500.ms, curve: Curves.easeOut).fadeIn();
  }

  Widget _buildChartTypeToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isShowingExpensesChart = !_isShowingExpensesChart;
        });
      },
      child: Container(
        width: 100,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: _isShowingExpensesChart ? 0 : 50,
              right: _isShowingExpensesChart ? 50 : 0,
              child: Container(
                width: 50,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color:
                      _isShowingExpensesChart ? Colors.white : Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Icon(
                      Icons.arrow_downward_rounded,
                      color:
                      !_isShowingExpensesChart ? Colors.white : Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    ).animate(delay: 600.ms).fadeIn();
  }

  Widget _buildTransactionsList() {
    if (widget.transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_rounded, size: 60, color: Colors.grey),
              SizedBox(height: 10),
              Text("No transactions yet.", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    // Sort transactions by date descending to show the most recent first
    final sortedTransactions = List<Transaction>.from(widget.transactions);
    sortedTransactions.sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: sortedTransactions.take(5).map((transaction) { // Show only latest 5
        final category = _getCategoryById(transaction.categoryId);
        return TransactionTile(
          transaction: transaction,
          icon: category.icon,
          color: category.color,
          currencySymbol: widget.currencySymbol,
          onEdit: () {}, // Placeholder
        );
      }).toList(),
    ).animate(delay: 100.ms).slideX(begin: -0.5, duration: 600.ms, curve: Curves.easeOut).fadeIn();
  }
}

// --- Stats Page Widget (MODIFIED) ---
enum StatsPeriod { weekly, monthly, yearly }
enum StatsType { expense, income, comparison } // ADDED comparison type

// Data class for the new comparison chart
class ComparisonChartData {
  final List<String> labels;
  final List<double> incomes;
  final List<double> expenses;
  final double maxY;

  ComparisonChartData({
    required this.labels,
    required this.incomes,
    required this.expenses,
    required this.maxY,
  });
}

class StatsPage extends StatefulWidget {
  final List<Transaction> transactions;
  final String currencySymbol;
  final List<Category> categories;

  const StatsPage({super.key, required this.transactions, required this.currencySymbol, required this.categories});

  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  StatsPeriod _selectedPeriod = StatsPeriod.monthly;
  StatsType _selectedType = StatsType.comparison; // Default to comparison view
  int _touchedIndex = -1;

  Category _getCategoryById(String id) {
    return widget.categories.firstWhere((cat) => cat.id == id,
        orElse: () => widget.categories.firstWhere((c) => c.name.toLowerCase() == 'other'));
  }

  // Helper to normalize a date to midnight
  DateTime _normalizeDate(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  List<Transaction> _getFilteredTransactionsForType(StatsType type) {
    final now = DateTime.now();
    final today = _normalizeDate(now);

    return widget.transactions.where((t) {
      final isTypeMatch = (type == StatsType.expense) ? t.isExpense : !t.isExpense;
      if (!isTypeMatch) return false;

      final transactionDate = _normalizeDate(t.date);

      switch (_selectedPeriod) {
        case StatsPeriod.weekly:
          final weekStart = today.subtract(Duration(days: now.weekday - 1));
          final weekEnd = weekStart.add(const Duration(days: 6));
          return !transactionDate.isBefore(weekStart) && !transactionDate.isAfter(weekEnd);
        case StatsPeriod.monthly:
          return transactionDate.year == now.year && transactionDate.month == now.month;
        case StatsPeriod.yearly:
          return transactionDate.year == now.year;
        default:
          return false;
      }
    }).toList();
  }

  // --- NEW: Data preparation for Comparison Chart ---
  ComparisonChartData _prepareComparisonData() {
    final now = DateTime.now();
    final today = _normalizeDate(now);
    List<Transaction> transactions = widget.transactions;
    List<String> labels = [];
    List<double> incomes = [];
    List<double> expenses = [];

    switch (_selectedPeriod) {
      case StatsPeriod.weekly:
        labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        incomes = List.filled(7, 0.0);
        expenses = List.filled(7, 0.0);
        final weekStart = today.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        final weeklyTransactions = transactions.where((t) {
          final tDate = _normalizeDate(t.date);
          return !tDate.isBefore(weekStart) && !tDate.isAfter(weekEnd);
        });

        for (var t in weeklyTransactions) {
          final dayIndex = t.date.weekday - 1;
          if (t.isExpense) {
            expenses[dayIndex] += t.amount;
          } else {
            incomes[dayIndex] += t.amount;
          }
        }
        break;

      case StatsPeriod.monthly:
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        labels = List.generate(daysInMonth, (i) => (i + 1).toString());
        incomes = List.filled(daysInMonth, 0.0);
        expenses = List.filled(daysInMonth, 0.0);
        final monthlyTransactions = transactions.where((t) => t.date.year == now.year && t.date.month == now.month);

        for (var t in monthlyTransactions) {
          final dayIndex = t.date.day - 1;
          if (t.isExpense) {
            expenses[dayIndex] += t.amount;
          } else {
            incomes[dayIndex] += t.amount;
          }
        }
        break;

      case StatsPeriod.yearly:
        labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        incomes = List.filled(12, 0.0);
        expenses = List.filled(12, 0.0);
        final yearlyTransactions = transactions.where((t) => t.date.year == now.year);

        for (var t in yearlyTransactions) {
          final monthIndex = t.date.month - 1;
          if (t.isExpense) {
            expenses[monthIndex] += t.amount;
          } else {
            incomes[monthIndex] += t.amount;
          }
        }
        break;
    }

    final maxIncome = incomes.isEmpty ? 0.0 : incomes.reduce(max);
    final maxExpense = expenses.isEmpty ? 0.0 : expenses.reduce(max);
    final maxY = max(maxIncome, maxExpense) * 1.2;

    return ComparisonChartData(
      labels: labels,
      incomes: incomes,
      expenses: expenses,
      maxY: maxY == 0 ? 100 : maxY, // Set a default max Y if no data
    );
  }

  @override
  Widget build(BuildContext context) {
    // This is only needed for the old donut chart view
    final transactionsForChart = _getFilteredTransactionsForType(
        _selectedType == StatsType.expense ? StatsType.expense : StatsType.income
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: 20),
            _buildTypeSelector(),
            const SizedBox(height: 24),
            // --- MODIFIED: Conditional rendering for charts ---
            AnimatedSwitcher(
              duration: 400.ms,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: _buildChartContent(transactionsForChart),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms),
      ),
    );
  }

  Widget _buildChartContent(List<Transaction> transactionsForChart) {
    if (_selectedType == StatsType.comparison) {
      return _buildComparisonChartCard();
    } else if (transactionsForChart.isEmpty) {
      return _buildEmptyState();
    } else {
      return Column(
        key: ValueKey('$_selectedType-$_selectedPeriod-data'),
        children: [
          _buildDonutChartCard(transactionsForChart),
          const SizedBox(height: 24),
          _buildCategoryStatsList(transactionsForChart),
        ],
      );
    }
  }


  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: StatsPeriod.values.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = period),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isSelected
                      ? [BoxShadow(color: Colors.grey.withAlpha(50), spreadRadius: 1, blurRadius: 5)]
                      : [],
                ),
                child: Center(
                  child: Text(
                    period.name.capitalize(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.indigo : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- MODIFIED: Type selector with 3 options ---
  Widget _buildTypeSelector() {
    return Row(
      children: [
        _buildTypeSelectorButton(StatsType.expense, 'Expense', Colors.redAccent),
        const SizedBox(width: 12),
        _buildTypeSelectorButton(StatsType.comparison, 'Comparison', Colors.indigo),
        const SizedBox(width: 12),
        _buildTypeSelectorButton(StatsType.income, 'Income', Colors.green),
      ],
    );
  }

  Widget _buildTypeSelectorButton(StatsType type, String label, Color color) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withAlpha(25) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 50.0),
      child: Column(
        children: [
          Icon(Icons.data_usage_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            "No data available for this period.",
            style: TextStyle(color: Colors.grey, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --- NEW: Comparison Chart Widget ---
  Widget _buildComparisonChartCard() {
    final chartData = _prepareComparisonData();

    if (chartData.incomes.every((d) => d == 0) && chartData.expenses.every((d) => d == 0)) {
      return _buildEmptyState();
    }

    return CustomCard(
      key: const ValueKey('comparison-chart'),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              '${_selectedPeriod.name.capitalize()} Overview',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  maxY: chartData.maxY,
                  alignment: BarChartAlignment.spaceBetween,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final type = rodIndex == 0 ? 'Income' : 'Expense';
                        return BarTooltipItem(
                          '$type\n${widget.currencySymbol}${rod.toY.toStringAsFixed(0)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value == chartData.maxY) return const Text('');
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= chartData.labels.length) return const Text('');

                          String text = chartData.labels[index];
                          // For monthly view, only show labels for every 5 days to avoid clutter
                          if (_selectedPeriod == StatsPeriod.monthly) {
                            if ((index + 1) % 5 != 1 && index != 0) {
                              return const Text('');
                            }
                          }
                          return Text(text, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold));
                        },
                        reservedSize: 28,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => const FlLine(color: Colors.black12, strokeWidth: 1),
                  ),
                  barGroups: List.generate(chartData.labels.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: chartData.incomes[index],
                          color: Colors.green,
                          width: 2,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: chartData.expenses[index],
                          color: Colors.blue,
                          width: 2,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
                duration: 500.ms,
                curve: Curves.easeInOut,
              ),
            ),
            const SizedBox(height: 12),
            _buildChartLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(Colors.green, 'Income'),
        const SizedBox(width: 20),
        _buildLegendItem(Colors.blue, 'Expense'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  Widget _buildDonutChartCard(List<Transaction> transactions) {
    final dataMap = <String, double>{};
    for (var t in transactions) {
      dataMap.update(t.categoryId, (value) => value + t.amount, ifAbsent: () => t.amount);
    }

    final totalValue = dataMap.values.fold(0.0, (sum, item) => sum + item);

    return CustomCard(
      key: const ValueKey('donut-chart'),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
                  sections: List.generate(dataMap.length, (i) {
                    final isTouched = i == _touchedIndex;
                    final categoryId = dataMap.keys.elementAt(i);
                    final category = _getCategoryById(categoryId);
                    final value = dataMap.values.elementAt(i);
                    return PieChartSectionData(
                      color: category.color,
                      value: value,
                      title: '',
                      radius: isTouched ? 25.0 : 20.0,
                    );
                  }),
                ),
                duration: 500.ms,
                curve: Curves.easeInOut,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _selectedType.name.capitalize(),
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  Text(
                    '${widget.currencySymbol}${totalValue.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryStatsList(List<Transaction> transactions) {
    final dataMap = <String, double>{};
    for (var t in transactions) {
      dataMap.update(t.categoryId, (value) => value + t.amount, ifAbsent: () => t.amount);
    }
    final totalValue = dataMap.values.fold(0.0, (sum, item) => sum + item);

    // Sort categories by amount
    final sortedEntries = dataMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Categories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...sortedEntries.map((entry) {
              final category = _getCategoryById(entry.key);
              return CategoryStatItem(
                icon: category.icon,
                color: category.color,
                categoryName: category.name,
                amount: entry.value,
                percentage: totalValue > 0 ? (entry.value / totalValue) : 0,
                currencySymbol: widget.currencySymbol,
              );
            }).toList(),
          ],
        ).animate(delay: 100.ms).fadeIn(duration: 500.ms).slideX(begin: -0.2),
      ),
    );
  }
}

// --- New Reusable Widget for Category Stats ---
class CategoryStatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String categoryName;
  final double amount;
  final double percentage;
  final String currencySymbol;

  const CategoryStatItem({
    super.key,
    required this.icon,
    required this.color,
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withAlpha(25),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(categoryName, style: const TextStyle(fontWeight: FontWeight.w500))),
              Text('${(percentage * 100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: Text(
                  '$currencySymbol${amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percentage),
            duration: 700.ms,
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                backgroundColor: color.withAlpha(50),
                color: color,
                borderRadius: BorderRadius.circular(10),
              );
            },
          ),
        ],
      ),
    );
  }
}


// --- Wallet Page Widget ---
class WalletPage extends StatelessWidget {
  final List<Transaction> transactions;
  final String currencySymbol;
  final List<FixedDeposit> fixedDeposits;
  final double savingsPot;
  final Function(FixedDeposit) onAddFixedDeposit;
  final Function(double) onAddToSavings;
  final bool includeFixedDeposits;
  final bool includeSavings;
  final Function(Transaction) onEditTransaction;
  final Function(Transaction) onDeleteTransaction;
  final List<Category> categories;


  const WalletPage({
    super.key,
    required this.transactions,
    required this.currencySymbol,
    required this.fixedDeposits,
    required this.savingsPot,
    required this.onAddFixedDeposit,
    required this.onAddToSavings,
    required this.includeFixedDeposits,
    required this.includeSavings,
    required this.onEditTransaction,
    required this.onDeleteTransaction,
    required this.categories,
  });

  Map<String, List<Transaction>> _groupTransactionsByDay(List<Transaction> transactions) {
    final groupedTransactions = <String, List<Transaction>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final transaction in transactions) {
      final transactionDate = DateTime(transaction.date.year, transaction.date.month, transaction.date.day);
      String dateKey;
      if (transactionDate == today) {
        dateKey = 'Today';
      } else if (transactionDate == yesterday) {
        dateKey = 'Yesterday';
      } else {
        dateKey = DateFormat.yMMMd().format(transactionDate); // e.g., Aug 19, 2025
      }
      if (groupedTransactions[dateKey] == null) {
        groupedTransactions[dateKey] = [];
      }
      groupedTransactions[dateKey]!.add(transaction);
    }
    return groupedTransactions;
  }


  @override
  Widget build(BuildContext context) {
    final double incomeAndExpenseBalance = transactions.where((t) => !t.isExpense).fold(0.0, (sum, item) => sum + item.amount) -
        transactions.where((t) => t.isExpense).fold(0.0, (sum, item) => sum + item.amount);

    final double totalFixedDeposits = fixedDeposits.fold(0.0, (sum, item) => sum + item.amount);

    double totalBalance = incomeAndExpenseBalance;
    if (includeFixedDeposits) {
      totalBalance += totalFixedDeposits;
    }
    if (includeSavings) {
      totalBalance += savingsPot;
    }

    final groupedTransactions = _groupTransactionsByDay(transactions);
    final dateKeys = groupedTransactions.keys.toList();

    // Sort the date keys chronologically
    dateKeys.sort((a, b) {
      if (a == 'Today') return -1;
      if (b == 'Today') return 1;
      if (a == 'Yesterday') return -1;
      if (b == 'Yesterday') return 1;

      final format = DateFormat.yMMMd();
      try {
        final dateA = format.parse(a);
        final dateB = format.parse(b);
        return dateB.compareTo(dateA); // Descending order for most recent first
      } catch (e) {
        return 0;
      }
    });


    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildBalanceCard(context, totalBalance, transactions, totalFixedDeposits, savingsPot),
          const SizedBox(height: 24),
          _buildAddFundsCard(context),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Recent Transactions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          if (transactions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Text("No transactions yet.", style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...dateKeys.map((dateKey) {
              final transactionsForDay = groupedTransactions[dateKey]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: DailyTransactionSummaryCard(
                  dateKey: dateKey,
                  transactions: transactionsForDay,
                  currencySymbol: currencySymbol,
                  onEditTransaction: onEditTransaction,
                  onDeleteTransaction: onDeleteTransaction,
                  categories: categories,
                ),
              );
            }).toList().animate(interval: 100.ms).fadeIn(duration: 500.ms).slideY(begin: 0.5),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }

  Widget _buildAddFundsCard(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Manage Funds", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.account_balance),
                    label: const Text('Add Deposit'),
                    onPressed: () => _showAddDepositDialog(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber.shade800,
                      side: BorderSide(color: Colors.amber.shade800),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.savings_outlined),
                    label: const Text('Add Savings'),
                    onPressed: () => _showAddSavingsDialog(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blueGrey,
                      side: const BorderSide(color: Colors.blueGrey),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: 400.ms).slideY(begin: 0.5, duration: 400.ms, curve: Curves.easeOut).fadeIn();
  }

  void _showAddSavingsDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.savings_outlined),
            SizedBox(width: 10),
            Text('Add Savings'),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixText: '$currencySymbol ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                onAddToSavings(amount);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddDepositDialog(BuildContext context) {
    final amountController = TextEditingController();
    DateTime? selectedDate = DateTime.now().add(const Duration(days: 365));

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.account_balance),
                  SizedBox(width: 10),
                  Text('Add FD'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '$currencySymbol ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate!,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setDialogState(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Maturity Date',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat.yMd().format(selectedDate!)),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final amount = double.tryParse(amountController.text);
                    if (amount != null && amount > 0 && selectedDate != null) {
                      onAddFixedDeposit(FixedDeposit(amount: amount, maturityDate: selectedDate!));
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Widget _buildBalanceCard(BuildContext context, double balance, List<Transaction> transactions, double totalFixedDeposits, double savingsPot) {
    final double totalIncome = transactions.where((t) => !t.isExpense).fold(0.0, (sum, item) => sum + item.amount);
    final double totalExpense = transactions.where((t) => t.isExpense).fold(0.0, (sum, item) => sum + item.amount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha(100),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL BALANCE', style: TextStyle(color: Colors.white70, letterSpacing: 1.5)),
              Icon(Icons.credit_card, color: Colors.white.withAlpha(200)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$currencySymbol${balance.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBalanceDetail('Income', '$currencySymbol${totalIncome.toStringAsFixed(2)}', Icons.arrow_upward, Colors.greenAccent),
              _buildBalanceDetail('Expense', '$currencySymbol${totalExpense.toStringAsFixed(2)}', Icons.arrow_downward, Colors.redAccent),
            ],
          ),
          if (totalFixedDeposits > 0 || savingsPot > 0) ...[
            const SizedBox(height: 8),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            Row(
              children: [
                if (totalFixedDeposits > 0) ...[
                  const Icon(Icons.account_balance, color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Deposits: $currencySymbol${totalFixedDeposits.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
                if (totalFixedDeposits > 0 && savingsPot > 0) const SizedBox(width: 16),
                if (savingsPot > 0) ...[
                  const Icon(Icons.savings, color: Colors.lightGreenAccent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Savings: $currencySymbol${savingsPot.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ],
            ),
          ]
        ],
      ),
    ).animate().slideY(begin: -1.0, duration: 400.ms, curve: Curves.easeOut).fadeIn();
  }

  Widget _buildBalanceDetail(String title, String amount, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(amount, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

// --- [START] REVAMPED BUDGET PAGE ---
enum LoanSortOption { dateNewest, dateOldest, amountHigh, amountLow }

class BudgetPage extends StatefulWidget {
  final String currencySymbol;
  final List<Loan> loans;
  final Function(Loan) onAddLoan;
  final Function(String) onToggleLoanStatus;
  final Function(String) onDeleteLoan;
  final Function(String) onRestoreLoan;
  final Function(String) onPermanentlyDeleteLoan;

  const BudgetPage({
    super.key,
    required this.currencySymbol,
    required this.loans,
    required this.onAddLoan,
    required this.onToggleLoanStatus,
    required this.onDeleteLoan,
    required this.onRestoreLoan,
    required this.onPermanentlyDeleteLoan,
  });

  @override
  _BudgetPageState createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  int _selectedSegmentIndex = 0;
  late PageController _pageController;
  LoanSortOption _sortOption = LoanSortOption.dateNewest;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<Loan> _sortLoans(List<Loan> loans) {
    loans.sort((a, b) {
      switch (_sortOption) {
        case LoanSortOption.dateNewest:
          return b.date.compareTo(a.date);
        case LoanSortOption.dateOldest:
          return a.date.compareTo(b.date);
        case LoanSortOption.amountHigh:
          return b.amount.compareTo(a.amount);
        case LoanSortOption.amountLow:
          return a.amount.compareTo(b.amount);
      }
    });
    return loans;
  }

  @override
  Widget build(BuildContext context) {
    final double totalGiven = widget.loans
        .where((l) => l.type == LoanType.given && !l.isPaid && !l.isDeleted)
        .fold(0.0, (sum, item) => sum + item.amount);
    final double totalTaken = widget.loans
        .where((l) => l.type == LoanType.taken && !l.isPaid && !l.isDeleted)
        .fold(0.0, (sum, item) => sum + item.amount);

    final activeLoans = _sortLoans(widget.loans.where((l) => !l.isPaid && !l.isDeleted).toList());
    final paidLoans = _sortLoans(widget.loans.where((l) => l.isPaid && !l.isDeleted).toList());
    final deletedLoans = widget.loans.where((l) => l.isDeleted).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Loan Manager'),
        actions: [
          if (_selectedSegmentIndex != 2) _buildSortMenu(),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(totalGiven, totalTaken),
          const SizedBox(height: 20),
          _buildSegmentedControl(),
          const SizedBox(height: 20),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedSegmentIndex = index;
                });
              },
              children: <Widget>[
                _buildLoanList(activeLoans, LoanListType.active),
                _buildLoanList(paidLoans, LoanListType.paid),
                _buildLoanList(deletedLoans, LoanListType.deleted),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLoanDialog(),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("New Loan"),
      ).animate().scale(),
    );
  }

  Widget _buildSortMenu() {
    return PopupMenuButton<LoanSortOption>(
      icon: const Icon(Icons.sort_rounded),
      onSelected: (option) {
        setState(() {
          _sortOption = option;
        });
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<LoanSortOption>>[
        const PopupMenuItem(value: LoanSortOption.dateNewest, child: Text("Sort by Newest")),
        const PopupMenuItem(value: LoanSortOption.dateOldest, child: Text("Sort by Oldest")),
        const PopupMenuItem(value: LoanSortOption.amountHigh, child: Text("Sort by Amount (High)")),
        const PopupMenuItem(value: LoanSortOption.amountLow, child: Text("Sort by Amount (Low)")),
      ],
    );
  }

  Widget _buildHeader(double totalGiven, double totalTaken) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(25),
              blurRadius: 20,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem("You Lent", '${widget.currencySymbol}${totalGiven.toStringAsFixed(2)}', Colors.green),
            const SizedBox(
              height: 50,
              child: VerticalDivider(),
            ),
            _buildStatItem("You Owe", '${widget.currencySymbol}${totalTaken.toStringAsFixed(2)}', Colors.redAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildSegmentedControl() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildSegment("Active", 0),
            _buildSegment("Paid", 1),
            _buildSegment("Recycle Bin", 2),
          ],
        ),
      ),
    );
  }

  Widget _buildSegment(String title, int index) {
    final isSelected = _selectedSegmentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSegmentIndex = index;
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Colors.grey.withAlpha(50),
                blurRadius: 5,
                spreadRadius: 1,
              )
            ]
                : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoanList(List<Loan> loans, LoanListType type) {
    if (loans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'All Clear!',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade800, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'No loans in this category.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: loans.length,
      itemBuilder: (context, index) {
        final loan = loans[index];
        return LoanCard(
          loan: loan,
          currencySymbol: widget.currencySymbol,
          type: type,
          onTogglePaid: () => widget.onToggleLoanStatus(loan.id),
          onDelete: () => widget.onDeleteLoan(loan.id),
          onRestore: () => widget.onRestoreLoan(loan.id),
          onPermanentlyDelete: () => widget.onPermanentlyDeleteLoan(loan.id),
        ).animate(delay: (100 * index).ms).fadeIn(duration: 400.ms).slideX(begin: 0.5);
      },
    );
  }

  void _showAddLoanDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: AddLoanForm(onAddLoan: widget.onAddLoan, currencySymbol: widget.currencySymbol),
        ).animate().slide(begin: const Offset(0, 1), duration: 300.ms, curve: Curves.easeOut);
      },
    );
  }
}

// --- [START] REVAMPED LOAN CARD ---
enum LoanListType { active, paid, deleted }

class LoanCard extends StatelessWidget {
  final Loan loan;
  final String currencySymbol;
  final LoanListType type;
  final VoidCallback? onTogglePaid;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onPermanentlyDelete;

  const LoanCard({
    super.key,
    required this.loan,
    required this.currencySymbol,
    required this.type,
    this.onTogglePaid,
    this.onDelete,
    this.onRestore,
    this.onPermanentlyDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isGiven = loan.type == LoanType.given;
    final color = isGiven ? Colors.green : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isGiven ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loan.personName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$currencySymbol${loan.amount.toStringAsFixed(2)}',
                style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (loan.reason != null && loan.reason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              loan.reason!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Date: ${DateFormat.yMMMd().format(loan.date)}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              _buildActionMenu(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionMenu(BuildContext context) {
    List<PopupMenuEntry<String>> items = [];
    switch (type) {
      case LoanListType.active:
      case LoanListType.paid:
        items.addAll([
          PopupMenuItem(value: 'toggle_paid', child: Text(loan.isPaid ? 'Mark as Unpaid' : 'Mark as Paid')),
          const PopupMenuDivider(),
          const PopupMenuItem(value: 'delete', child: Text('Move to Bin')),
        ]);
        break;
      case LoanListType.deleted:
        items.addAll([
          const PopupMenuItem(value: 'restore', child: Text('Restore Loan')),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'delete_perm',
            child: Text('Delete Permanently', style: TextStyle(color: Colors.redAccent)),
          ),
        ]);
        break;
    }

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz_rounded, color: Colors.grey.shade600),
      onSelected: (value) {
        if (value == 'toggle_paid') onTogglePaid?.call();
        if (value == 'delete') onDelete?.call();
        if (value == 'restore') onRestore?.call();
        if (value == 'delete_perm') onPermanentlyDelete?.call();
      },
      itemBuilder: (context) => items,
    );
  }
}
// --- [END] REVAMPED WIDGETS ---

// --- MODIFIED: Profile Page Widget ---

class ProfilePage extends StatelessWidget {
  final Currency selectedCurrency;
  final Function(Currency) onCurrencyChanged;
  final int transactionCount;
  final bool includeFixedDeposits;
  final bool includeSavings;
  final ValueChanged<bool> onIncludeFixedDepositsChanged;
  final ValueChanged<bool> onIncludeSavingsChanged;
  final List<Category> categories;
  final Function(String, Color, IconData, bool) onAddCategory;
  final Function(Category) onUpdateCategory;
  final Function(String) onDeleteCategory;
  final String nickname;
  final DateTime? installDate;
  final Function(String) onNicknameChanged;
  final VoidCallback onResetTransactions;
  final VoidCallback onResetDays;
  final VoidCallback onFactoryReset;
  final String? profileImagePath; // NEW
  final Function(String) onProfileImageChanged;
  final Uri _url = Uri.parse("https://lexora-f693c.web.app/store.html");// NEW

  ProfilePage({
    super.key,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
    required this.transactionCount,
    required this.includeFixedDeposits,
    required this.includeSavings,
    required this.onIncludeFixedDepositsChanged,
    required this.onIncludeSavingsChanged,
    required this.categories,
    required this.onAddCategory,
    required this.onUpdateCategory,
    required this.onDeleteCategory,
    required this.nickname,
    this.installDate,
    required this.onNicknameChanged,
    required this.onResetTransactions,
    required this.onResetDays,
    required this.onFactoryReset,
    this.profileImagePath, // NEW
    required this.onProfileImageChanged, // NEW
  });

  Future<void> _launchUrl() async {
    if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $_url');
    }
  }

  // NEW: Method to handle picking an image from the gallery
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Pick an image
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // If an image is picked, call the callback to update the state
      onProfileImageChanged(image.path);
    }
  }

  void _showEditNicknameDialog(BuildContext context) {
    final controller = TextEditingController(text: nickname);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Nickname'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter your new nickname'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onNicknameChanged(controller.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // NEW: Calculate total days since app install
    final int totalDays = installDate != null
        ? DateTime.now().difference(installDate!).inDays + 1
        : 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: 20),
            _buildStatsCard(totalDays), // Pass calculated days
            const SizedBox(height: 20),
            _buildPremiumBanner(context),
            const SizedBox(height: 20),
            _buildSettingsList(context),
          ],
        ).animate().fadeIn(duration: 500.ms),
      ),
    );
  }

  // MODIFIED: This widget now displays the profile image
  Widget _buildProfileHeader(BuildContext context) {
    // Determine the background image for the CircleAvatar
    final ImageProvider? backgroundImage = profileImagePath != null
        ? FileImage(File(profileImagePath!))
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          // MODIFIED: Added GestureDetector to change photo
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFFFFF3E0),
              backgroundImage: backgroundImage, // Use the selected image
              // Show the person icon only if no image is selected
              child: backgroundImage == null
                  ? const Icon(Icons.person, size: 50, color: Color(0xFFFDB846))
                  : null,
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
          ),
          const SizedBox(height: 15),
          GestureDetector(
            onTap: () => _showEditNicknameDialog(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  nickname, // Use nickname from state
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Icon(Icons.edit, size: 18, color: Colors.grey.shade600),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(int totalDays) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("Current Streak", "1"),
          _buildStatItem("Total Days", totalDays.toString()), // Use calculated days
          _buildStatItem("Transactions", transactionCount.toString()),
        ],
      ),
    ).animate(delay: 200.ms).slideY(begin: 0.5).fadeIn();
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildPremiumBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFEEA9E), Color(0xFFFDB846)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.safety_check, color: Color(0xFF4A4333)),
            const SizedBox(width: 12),
            const Text(
              "Powered By LEXORA",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF4A4333),
              ),
            ),
            Spacer(),

            Expanded(
              child: GestureDetector(
                onTap: _launchUrl,

                child:
                const Icon(Icons.chevron_right, color: Color(0xFF4A4333)),),),
          ],
        ),
      ),
    ).animate(delay: 400.ms).slideY(begin: 0.5).fadeIn();
  }

  Widget _buildSettingsList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          _buildCurrencySettingItem(context),
          const Divider(height: 30),
          SettingsListItem(
            icon: Icons.account_balance_wallet,
            iconColor: Colors.green,
            title: "Balance Calculation",
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (ctx) => BalanceCalculationSettingsPage(
                  includeFixedDeposits: includeFixedDeposits,
                  includeSavings: includeSavings,
                  onIncludeFixedDepositsChanged: onIncludeFixedDepositsChanged,
                  onIncludeSavingsChanged: onIncludeSavingsChanged,
                ),
              ));
            },
          ),
          SettingsListItem(
            icon: Icons.category,
            iconColor: Colors.blue,
            title: "Category Manager",
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (ctx) => CategoryManagerPage(
                  categories: categories,
                  onAddCategory: onAddCategory,
                  onUpdateCategory: onUpdateCategory,
                  onDeleteCategory: onDeleteCategory,
                ),
              ));
            },
          ),
          // MODIFIED: Changed "Recurring" to "Reset Data"
          SettingsListItem(
            icon: Icons.sync,
            iconColor: Colors.teal,
            title: "Reset Data",
            onTap: () {
              // NEW: Navigate to the new reset page
              Navigator.of(context).push(MaterialPageRoute(
                builder: (ctx) => RecurringSettingsPage(
                  onResetTransactions: onResetTransactions,
                  onResetDays: onResetDays,
                  onFactoryReset: onFactoryReset,
                ),
              ));
            },
          ),

        ],
      ).animate(delay: 600.ms).slideX(begin: -0.5).fadeIn(),
    );
  }

  Widget _buildCurrencySettingItem(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.attach_money, color: Colors.grey),
      ),
      title: const Text("Base Currency", style: TextStyle(fontWeight: FontWeight.w500)),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<Currency>(
          value: selectedCurrency,
          items: Currency.values.map((Currency currency) {
            return DropdownMenuItem<Currency>(
              value: currency,
              child: Text(currency.name),
            );
          }).toList(),
          onChanged: (Currency? newValue) {
            if (newValue != null) {
              onCurrencyChanged(newValue);
            }
          },
        ),
      ),
    );
  }
}

// --- Reusable Widgets ---

/// A custom list item for the settings page
class SettingsListItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const SettingsListItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withAlpha(25),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}


/// A custom card widget with consistent styling
class CustomCard extends StatelessWidget {
  final Widget child;
  const CustomCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A list tile to display a single transaction.
class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final IconData icon;
  final Color color;
  final String currencySymbol;
  final VoidCallback onEdit;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.icon,
    required this.color,
    required this.currencySymbol,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withAlpha(25),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description ?? '', // MODIFIED: Handle optional description
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.jm().format(transaction.date), // Shows time like 5:08 PM
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '${transaction.isExpense ? '-' : '+'}$currencySymbol${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: transaction.isExpense ? Colors.redAccent : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Form widget for adding a new loan.
class AddLoanForm extends StatefulWidget {
  final Function(Loan) onAddLoan;
  final String currencySymbol;
  const AddLoanForm({super.key, required this.onAddLoan, required this.currencySymbol});

  @override
  _AddLoanFormState createState() => _AddLoanFormState();
}

class _AddLoanFormState extends State<AddLoanForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  LoanType _loanType = LoanType.given;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newLoan = Loan(
        personName: _nameController.text,
        amount: double.parse(_amountController.text),
        reason: _reasonController.text,
        type: _loanType,
        date: DateTime.now(),
      );
      widget.onAddLoan(newLoan);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: Text('Add New Loan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _loanType = LoanType.given),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _loanType == LoanType.given ? Colors.green.withAlpha(25) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _loanType == LoanType.given ? Colors.green : Colors.transparent),
                      ),
                      child: Center(child: Text('Given', style: TextStyle(fontWeight: FontWeight.bold, color: _loanType == LoanType.given ? Colors.green : Colors.black54))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _loanType = LoanType.taken),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _loanType == LoanType.taken ? Colors.red.withAlpha(25) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _loanType == LoanType.taken ? Colors.redAccent : Colors.transparent),
                      ),
                      child: Center(child: Text('Taken', style: TextStyle(fontWeight: FontWeight.bold, color: _loanType == LoanType.taken ? Colors.redAccent : Colors.black54))),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: _loanType == LoanType.given ? "To Whom?" : "From Whom?",
              ),
              validator: (v) => v == null || v.isEmpty ? "Please enter a name" : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: "Amount",
                prefixText: '${widget.currencySymbol} ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => v == null || double.tryParse(v) == null ? "Enter a valid amount" : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(labelText: "Reason (Optional)"),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Loan'),
            ),
          ],
        ),
      ),
    );
  }
}


/// Form widget inside the modal bottom sheet.
class AddTransactionForm extends StatefulWidget {
  final Function(Transaction) onAddTransaction;
  final Transaction? transactionToEdit;
  final List<Category> categories;
  final String currencySymbol;

  const AddTransactionForm({
    super.key,
    required this.onAddTransaction,
    this.transactionToEdit,
    required this.categories,
    required this.currencySymbol,
  });

  @override
  _AddTransactionFormState createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isExpense = true;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.transactionToEdit != null) {
      final t = widget.transactionToEdit!;
      _amountController.text = t.amount.toString();
      _descriptionController.text = t.description ?? '';
      _isExpense = t.isExpense;
      _selectedCategoryId = t.categoryId;
      _selectedDate = t.date;
    } else {
      // Default to the first available expense category
      _selectedCategoryId = widget.categories
          .firstWhere((c) => c.isExpense,
          orElse: () => widget.categories.first)
          .id;
    }
  }


  void _submit() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text;

      final newTransaction = widget.transactionToEdit?.copyWith(
        description: description.isNotEmpty ? description : null,
        amount: amount,
        isExpense: _isExpense,
        categoryId: _selectedCategoryId,
        date: _selectedDate,
      ) ?? Transaction(
        description: description.isNotEmpty ? description : null,
        amount: amount,
        isExpense: _isExpense,
        categoryId: _selectedCategoryId!,
        date: _selectedDate,
      );

      widget.onAddTransaction(newTransaction);
      Navigator.of(context).pop();
    }
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate == null) {
        return;
      }
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  void _toggleTransactionType(bool isNowExpense) {
    setState(() {
      if (isNowExpense != _isExpense) {
        _isExpense = isNowExpense;
        // When toggling, set the selected category to the first available one of the new type
        if (_isExpense) {
          _selectedCategoryId = widget.categories.firstWhere((c) => c.isExpense).id;
        } else {
          _selectedCategoryId = widget.categories.firstWhere((c) => !c.isExpense).id;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transactionToEdit != null;
    // Filter categories based on whether it's an expense or income
    final availableCategories = widget.categories.where((c) => c.isExpense == _isExpense).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildTypeToggle(),
              const SizedBox(height: 24),
              TextFormField(
                controller: _amountController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration:
                InputDecoration(labelText: 'Amount', prefixText: '${widget.currencySymbol} '),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: availableCategories.map((category) {
                  return DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  }
                },
                validator: (value) => value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 6),
              // MODIFIED: Description is now optional (validator removed)
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description (Optional)'),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Date: ${DateFormat.yMd().format(_selectedDate)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  TextButton(
                    onPressed: _presentDatePicker,
                    child: const Text('Choose Date'),
                  ),
                ],
              ),
              // MODIFIED: Category selection is now mandatory for both types

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isEditing ? 'Save Changes' : 'Add Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _toggleTransactionType(true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _isExpense
                    ? Colors.redAccent.withAlpha(25)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _isExpense ? Colors.redAccent : Colors.transparent,
                    width: 1.5),
              ),
              child: Center(
                  child: Text('Expense',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isExpense ? Colors.redAccent : Colors.grey))),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _toggleTransactionType(false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: !_isExpense
                    ? Colors.green.withAlpha(25)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: !_isExpense ? Colors.green : Colors.transparent,
                    width: 1.5),
              ),
              child: Center(
                  child: Text('Income',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: !_isExpense ? Colors.green : Colors.grey))),
            ),
          ),
        ),
      ],
    );
  }
}

/// The custom bottom navigation bar.
class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final VoidCallback onAddTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onAddTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(50),
            spreadRadius: 5,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.bar_chart_rounded, "Stats", 0),
          _buildNavItem(Icons.account_balance_wallet_rounded, "Wallet", 1),
          _buildHomeItem(2),
          _buildNavItem(Icons.swap_horiz_rounded, "Loans", 3),
          _buildNavItem(Icons.person_rounded, "Profile", 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.indigo : Colors.grey, size: 28),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.indigo : Colors.grey,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeItem(int index) {
    final bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (isSelected) {
          onAddTapped();
        } else {
          onItemTapped(index);
        }
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.indigo,
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withAlpha(75),
              spreadRadius: 2,
              blurRadius: 10,
            ),
          ],
        ),
        child:
        Icon(isSelected ? Icons.add : Icons.home, color: Colors.white, size: 32),
      ).animate(target: isSelected ? 1 : 0).scale(
        begin: const Offset(1, 1),
        end: const Offset(1.1, 1.1),
        duration: 200.ms,
        curve: Curves.easeInOut,
      ).then().scale(
        begin: const Offset(1.1, 1.1),
        end: const Offset(1, 1),
      ),
    );
  }
}

// --- Collapsible Day Card ---
class DailyTransactionSummaryCard extends StatefulWidget {
  final String dateKey;
  final List<Transaction> transactions;
  final String currencySymbol;
  final Function(Transaction) onEditTransaction;
  final Function(Transaction) onDeleteTransaction;
  final List<Category> categories;

  const DailyTransactionSummaryCard({
    super.key,
    required this.dateKey,
    required this.transactions,
    required this.currencySymbol,
    required this.onEditTransaction,
    required this.onDeleteTransaction,
    required this.categories,
  });

  @override
  _DailyTransactionSummaryCardState createState() => _DailyTransactionSummaryCardState();
}

class _DailyTransactionSummaryCardState extends State<DailyTransactionSummaryCard> {
  bool _isExpanded = false;

  Category _getCategoryById(String id) {
    return widget.categories.firstWhere((cat) => cat.id == id,
        orElse: () => widget.categories.firstWhere((c) => c.name.toLowerCase() == 'other'));
  }


  @override
  Widget build(BuildContext context) {
    final double dailyIncome = widget.transactions
        .where((t) => !t.isExpense)
        .fold(0.0, (sum, item) => sum + item.amount);
    final double dailyExpense = widget.transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, item) => sum + item.amount);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: _isExpanded ? Radius.zero : const Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.dateKey,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (dailyIncome > 0)
                        Text(
                          '+${widget.currencySymbol}${dailyIncome.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      if (dailyExpense > 0)
                        Text(
                          '-${widget.currencySymbol}${dailyExpense.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: 300.ms,
                    child: const Icon(
                      Icons.expand_more,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: 300.ms,
            curve: Curves.easeInOut,
            child: _isExpanded ? Column(
              children: [
                const Divider(height: 1),
                ...widget.transactions.map((t) {
                  final category = _getCategoryById(t.categoryId);
                  return Dismissible(
                    key: ValueKey(t.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) => widget.onDeleteTransaction(t),
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.only(
                          bottomLeft: widget.transactions.last == t ? const Radius.circular(12) : Radius.zero,
                          bottomRight: widget.transactions.last == t ? const Radius.circular(12) : Radius.zero,
                        ),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: TransactionTile(
                      transaction: t,
                      icon: category.icon,
                      color: category.color,
                      currencySymbol: widget.currencySymbol,
                      onEdit: () => widget.onEditTransaction(t),
                    ),
                  );
                }).toList(),
              ],
            ) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// --- REVAMPED: Category Manager Page ---
class CategoryManagerPage extends StatefulWidget {
  final List<Category> categories;
  final Function(String, Color, IconData, bool) onAddCategory;
  final Function(Category) onUpdateCategory;
  final Function(String) onDeleteCategory;

  const CategoryManagerPage({
    super.key,
    required this.categories,
    required this.onAddCategory,
    required this.onUpdateCategory,
    required this.onDeleteCategory,
  });

  @override
  _CategoryManagerPageState createState() => _CategoryManagerPageState();
}

class _CategoryManagerPageState extends State<CategoryManagerPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddEditSheet({Category? category, required bool isExpense}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AddEditCategorySheet(
          category: category,
          isExpense: isExpense,
          onSave: (name, color, icon) {
            if (category == null) {
              // Add new category
              widget.onAddCategory(name, color, icon, isExpense);
            } else {
              // Update existing category
              category.name = name;
              category.color = color;
              category.icon = icon;
              widget.onUpdateCategory(category);
            }
          },
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  void _confirmDelete(Category category) {
    // Protected categories that cannot be deleted
    final protectedNames = ['other', 'other income'];
    if (protectedNames.contains(category.name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot delete the "${category.name}" category.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you sure?'),
        content: Text(
            'Do you want to delete this category? All associated transactions will be moved to "Other ${category.isExpense ? '' : 'Income'}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              widget.onDeleteCategory(category.id);
              Navigator.of(ctx).pop();
              setState(() {});
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(bool isExpense) {
    final filteredCategories = widget.categories.where((c) => c.isExpense == isExpense).toList();
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredCategories.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final category = filteredCategories[index];
        final isProtected = category.name.toLowerCase().contains('other');

        return CustomCard(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: category.color,
              child: Icon(category.icon, color: Colors.white, size: 20),
            ),
            title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: isProtected
                ? null // Hide menu for 'Other' categories
                : PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showAddEditSheet(category: category, isExpense: isExpense);
                } else if (value == 'delete') {
                  _confirmDelete(category);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.5);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryList(true), // Expense categories
          _buildCategoryList(false), // Income categories
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Check which tab is active to determine if we're adding an expense or income category
          final isExpense = _tabController.index == 0;
          _showAddEditSheet(isExpense: isExpense);
        },
        label: const Text('New Category'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.lightBlue,
      ).animate().scale(),
    );
  }
}

// --- NEW: Add/Edit Category Bottom Sheet ---
class AddEditCategorySheet extends StatefulWidget {
  final Category? category;
  final bool isExpense;
  final Function(String name, Color color, IconData icon) onSave;

  const AddEditCategorySheet({super.key, this.category, required this.onSave, required this.isExpense});

  @override
  _AddEditCategorySheetState createState() => _AddEditCategorySheetState();
}

class _AddEditCategorySheetState extends State<AddEditCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late Color _selectedColor;
  late IconData _selectedIcon;

  // A predefined list of icons for users to choose from
  final List<IconData> _icons = [
    Icons.fastfood_rounded, Icons.shopping_bag_rounded, Icons.directions_car_rounded,
    Icons.receipt_long_rounded, Icons.movie_rounded, Icons.home_rounded,
    Icons.health_and_safety_rounded, Icons.school_rounded, Icons.pets_rounded,
    Icons.card_giftcard_rounded, Icons.phone_android_rounded, Icons.flight_takeoff_rounded,
    Icons.fitness_center_rounded, Icons.music_note_rounded, Icons.category_rounded,
    Icons.work_rounded, Icons.account_balance_rounded, Icons.watch_later_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedColor = widget.category?.color ?? Colors.blue;
    _selectedIcon = widget.category?.icon ?? Icons.category_rounded;
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() => _selectedColor = color);
            },
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Done'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(
        _nameController.text,
        _selectedColor,
        _selectedIcon,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Text(widget.category == null ? 'New Category' : 'Edit Category', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Category Name'),
              validator: (v) => v == null || v.isEmpty ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 20),
            _buildColorPicker(),
            const SizedBox(height: 20),
            _buildIconPicker(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return Row(
      children: [
        const Text('Color:', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: _pickColor,
          child: CircleAvatar(backgroundColor: _selectedColor),
        ),
        const Spacer(),
        TextButton(onPressed: _pickColor, child: const Text('Choose Color'))
      ],
    );
  }

  Widget _buildIconPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Icon:', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _icons.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final icon = _icons[index];
              final isSelected = icon == _selectedIcon;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = icon),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected ? _selectedColor.withAlpha(50) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected ? Border.all(color: _selectedColor, width: 2) : null,
                  ),
                  child: Icon(icon, color: isSelected ? _selectedColor : Colors.grey.shade600),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// --- NEW: Balance Calculation Settings Page ---
class BalanceCalculationSettingsPage extends StatefulWidget {
  final bool includeFixedDeposits;
  final bool includeSavings;
  final ValueChanged<bool> onIncludeFixedDepositsChanged;
  final ValueChanged<bool> onIncludeSavingsChanged;

  const BalanceCalculationSettingsPage({
    super.key,
    required this.includeFixedDeposits,
    required this.includeSavings,
    required this.onIncludeFixedDepositsChanged,
    required this.onIncludeSavingsChanged,
  });

  @override
  _BalanceCalculationSettingsPageState createState() =>
      _BalanceCalculationSettingsPageState();
}

class _BalanceCalculationSettingsPageState
    extends State<BalanceCalculationSettingsPage> {
  late bool _includeFixedDeposits;
  late bool _includeSavings;

  @override
  void initState() {
    super.initState();
    _includeFixedDeposits = widget.includeFixedDeposits;
    _includeSavings = widget.includeSavings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Balance Calculation'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: const Text("Include Fixed Deposits"),
            subtitle: const Text("Adds the total of your fixed deposits to the main balance."),
            value: _includeFixedDeposits,
            onChanged: (newValue) {
              setState(() {
                _includeFixedDeposits = newValue;
              });
              widget.onIncludeFixedDepositsChanged(newValue);
            },
            secondary: const Icon(Icons.account_balance),
          ),
          SwitchListTile(
            title: const Text("Include Savings Pot"),
            subtitle: const Text("Adds your savings pot amount to the main balance."),
            value: _includeSavings,
            onChanged: (newValue) {
              setState(() {
                _includeSavings = newValue;
              });
              widget.onIncludeSavingsChanged(newValue);
            },
            secondary: const Icon(Icons.savings_outlined),
          ),
        ],
      ),
    );
  }
}

// --- NEW: Recurring/Reset Settings Page ---
class RecurringSettingsPage extends StatelessWidget {
  final VoidCallback onResetTransactions;
  final VoidCallback onResetDays;
  final VoidCallback onFactoryReset;

  const RecurringSettingsPage({
    super.key,
    required this.onResetTransactions,
    required this.onResetDays,
    required this.onFactoryReset,
  });

  void _showConfirmationDialog(BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.of(ctx).pop();
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Data'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Reset All Transactions'),
            subtitle: const Text('This will delete all your income and expense records permanently.'),
            onTap: () => _showConfirmationDialog(
              context,
              title: 'Reset Transactions?',
              content: 'Are you sure? This action cannot be undone.',
              onConfirm: onResetTransactions,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Reset Usage Days'),
            subtitle: const Text('This will reset the "Total Days" counter on your profile to 1.'),
            onTap: () => _showConfirmationDialog(
              context,
              title: 'Reset Days?',
              content: 'Are you sure you want to reset your usage day counter?',
              onConfirm: onResetDays,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            title: const Text('Factory Reset', style: TextStyle(color: Colors.redAccent)),
            subtitle: const Text('This will erase all app data, including transactions, loans, categories, and settings.'),
            onTap: () => _showConfirmationDialog(
              context,
              title: 'Factory Reset?',
              content: 'WARNING: This will permanently delete all your data. Are you absolutely sure?',
              onConfirm: onFactoryReset,
            ),
          ),
        ],
      ),
    );
  }
}


// --- Extensions ---

/// Helper extension to capitalize the first letter of a string.
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return "";
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

// --- MODIFIED: Persistence Service with new methods ---

class PersistenceService {
  Future<Directory> get _localPath async {
    return await getApplicationDocumentsDirectory();
  }

  Future<File> _getLocalFile(String fileName) async {
    final path = await _localPath;
    return File('${path.path}/$fileName');
  }

  Future<void> _saveJsonToFile(String fileName, List<Map<String, dynamic>> data) async {
    final file = await _getLocalFile(fileName);
    await file.writeAsString(json.encode(data));
  }

  Future<List<Map<String, dynamic>>> _loadJsonFromFile(String fileName) async {
    try {
      final file = await _getLocalFile(fileName);
      final contents = await file.readAsString();
      final data = json.decode(contents) as List;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      // If the file doesn't exist or is corrupt, return an empty list
      return [];
    }
  }

  // --- Transactions ---
  Future<void> saveTransactions(List<Transaction> transactions) async {
    final data = transactions.map((t) => t.toJson()).toList();
    await _saveJsonToFile('transactions.json', data);
  }

  Future<List<Transaction>> loadTransactions() async {
    final data = await _loadJsonFromFile('transactions.json');
    return data.map((json) => Transaction.fromJson(json)).toList();
  }

  // NEW: Clear transactions
  Future<void> clearTransactions() async {
    await _saveJsonToFile('transactions.json', []);
  }

  // --- Categories ---
  Future<void> saveCategories(List<Category> categories) async {
    final data = categories.map((c) => c.toJson()).toList();
    await _saveJsonToFile('categories.json', data);
  }

  Future<List<Category>> loadCategories() async {
    final data = await _loadJsonFromFile('categories.json');
    return data.map((json) => Category.fromJson(json)).toList();
  }

  // --- Loans ---
  Future<void> saveLoans(List<Loan> loans) async {
    final data = loans.map((l) => l.toJson()).toList();
    await _saveJsonToFile('loans.json', data);
  }

  Future<List<Loan>> loadLoans() async {
    final data = await _loadJsonFromFile('loans.json');
    return data.map((json) => Loan.fromJson(json)).toList();
  }

  // --- Fixed Deposits ---
  Future<void> saveFixedDeposits(List<FixedDeposit> deposits) async {
    final data = deposits.map((d) => d.toJson()).toList();
    await _saveJsonToFile('fixed_deposits.json', data);
  }

  Future<List<FixedDeposit>> loadFixedDeposits() async {
    final data = await _loadJsonFromFile('fixed_deposits.json');
    return data.map((json) => FixedDeposit.fromJson(json)).toList();
  }

  // --- SharedPreferences for simple key-value data ---

  // --- Savings Pot ---
  Future<void> saveSavingsPot(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('savingsPot', amount);
  }

  Future<double> loadSavingsPot() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('savingsPot') ?? 0.0;
  }

  // --- Nickname ---
  Future<void> saveNickname(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname', nickname);
  }

  Future<String> loadNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nickname') ?? 'Nickname';
  }

  // --- Install Date ---
  Future<void> saveInstallDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('installDate', date.toIso8601String());
  }

  Future<DateTime?> loadInstallDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString('installDate');
    return dateString != null ? DateTime.parse(dateString) : null;
  }

  // --- Profile Image Path (NEW) ---
  Future<void> saveProfileImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImagePath', path);
  }

  Future<String?> loadProfileImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('profileImagePath');
  }


  // --- Settings ---
  Future<void> saveSettings({
    required Currency currency,
    required bool includeFixedDeposits,
    required bool includeSavings,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', currency.name);
    await prefs.setBool('includeFixedDeposits', includeFixedDeposits);
    await prefs.setBool('includeSavings', includeSavings);
  }

  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final currencyName = prefs.getString('currency');
    return {
      'currency': currencyName != null ? Currency.values.byName(currencyName) : null,
      'includeFixedDeposits': prefs.getBool('includeFixedDeposits'),
      'includeSavings': prefs.getBool('includeSavings'),
    };
  }

  // --- Factory Reset ---
  Future<void> clearAllData() async {
    // Clear all JSON files
    final fileNames = ['transactions.json', 'categories.json', 'loans.json', 'fixed_deposits.json'];
    for (var fileName in fileNames) {
      try {
        final file = await _getLocalFile(fileName);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Ignore errors if file doesn't exist
      }
    }

    // Clear SharedPreferences, but keep the install date
    final prefs = await SharedPreferences.getInstance();
    final installDate = prefs.getString('installDate'); // Save it before clearing
    await prefs.clear();
    if (installDate != null) {
      await prefs.setString('installDate', installDate); // Restore it
    }
  }
}
